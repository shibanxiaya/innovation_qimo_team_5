/// =====================================================
/// 文件：lib/services/madness_database.dart
/// 功能：发疯卡片数据库服务（单例）
/// 描述：移动端/桌面端使用 sqflite，Web 端使用内存存储
/// =====================================================

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/madness_card_model.dart';

/// 数据库服务单例
class DatabaseService {
  // ============ 单例模式 ============
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  // ============ 数据库实例 ============
  Database? _database;

  /// Web 端内存存储（SQLite 在 Web 不可用）
  final List<MadnessCard> _webCards = [];
  int _webIdCounter = 0;
  bool _webLoaded = false;

  static const String _webStorageKey = 'madness_cards_json';
  static const String _webIdCounterKey = 'madness_id_counter';

  static const String _dbName = 'madness.db';
  static const String _tableName = 'madness_cards';

  /// 是否为 Web 平台
  bool get _isWeb => kIsWeb;

  /// 获取数据库实例，若未初始化则先初始化
  Future<Database> get database async {
    if (_isWeb) {
      throw UnsupportedError('Web 平台不支持 SQLite，请使用内存存储方法');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      String dbPath;

      // 桌面端 (Windows/Linux/macOS) 使用 ffi 工厂
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        final appDir = await getApplicationDocumentsDirectory();
        dbPath = p.join(appDir.path, _dbName);
      } else {
        // 移动端 (Android/iOS) 使用默认路径
        final dbDir = await getDatabasesPath();
        dbPath = p.join(dbDir, _dbName);
      }

      print('📂 数据库路径: $dbPath');

      final db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              emoji TEXT NOT NULL,
              startColor TEXT NOT NULL,
              endColor TEXT NOT NULL,
              userText TEXT NOT NULL,
              createDate INTEGER NOT NULL
            )
          ''');
          print('📂 数据表 $_tableName 已创建');
        },
      );

      return db;
    } catch (e) {
      print('❌ 数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 插入一条发疯记录
  /// 返回插入后的自增 ID
  Future<int> insertCard(MadnessCard card) async {
    try {
      // Web 平台使用内存存储 + SharedPreferences 持久化
      if (_isWeb) {
        await _loadWebCards();
        _webIdCounter++;
        final newCard = MadnessCard(
          id: _webIdCounter,
          emoji: card.emoji,
          startColor: card.startColor,
          endColor: card.endColor,
          userText: card.userText,
          createDate: card.createDate,
        );
        _webCards.add(newCard);
        await _persistWebCards();
        print('🟢 [Web] 发疯记录已入库，ID=$_webIdCounter');
        return _webIdCounter;
      }

      final db = await database;
      final id = await db.insert(_tableName, card.toMap());
      print('🟢 发疯记录已入库，ID=$id');
      return id;
    } catch (e) {
      print('❌ 插入发疯记录失败: $e');
      rethrow;
    }
  }

  /// 获取所有发疯记录，按创建时间倒序（最新在前）
  Future<List<MadnessCard>> getAllCards() async {
    try {
      // Web 平台使用内存存储
      if (_isWeb) {
        await _loadWebCards();
        _webCards.sort((a, b) => b.createDate.compareTo(a.createDate));
        print('🟡 [Web] 查询到 ${_webCards.length} 条发疯记录');
        return List.unmodifiable(_webCards);
      }

      final db = await database;
      final maps = await db.query(
        _tableName,
        orderBy: 'createDate DESC',
      );
      final cards = maps.map((map) => MadnessCard.fromMap(map)).toList();
      print('🟡 查询到 ${cards.length} 条发疯记录');
      return cards;
    } catch (e) {
      print('❌ 查询所有发疯记录失败: $e');
      return [];
    }
  }

  /// 按日期查询某一天的发疯记录
  /// 使用毫秒区间 BETWEEN 查询，精度高且跨平台兼容
  Future<List<MadnessCard>> getCardsByDate(DateTime date) async {
    try {
      // Web 平台使用内存存储
      if (_isWeb) {
        await _loadWebCards();
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final startMillis = startOfDay.millisecondsSinceEpoch;
        final endMillis = endOfDay.millisecondsSinceEpoch;

        final result = _webCards.where((c) {
          final ts = c.createDate.millisecondsSinceEpoch;
          return ts >= startMillis && ts < endMillis;
        }).toList()
          ..sort((a, b) => b.createDate.compareTo(a.createDate));

        print(
            '🟡 [Web] 查询 ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 的发疯记录: ${result.length} 条');
        return result;
      }

      final db = await database;

      // 计算当天 00:00:00 的时间戳（毫秒）
      final startOfDay = DateTime(date.year, date.month, date.day);
      final startMillis = startOfDay.millisecondsSinceEpoch;

      // 计算当天 23:59:59.999 的时间戳（毫秒）
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final endMillis = endOfDay.millisecondsSinceEpoch;

      final maps = await db.query(
        _tableName,
        where: 'createDate >= ? AND createDate < ?',
        whereArgs: [startMillis, endMillis],
        orderBy: 'createDate DESC',
      );

      final cards = maps.map((map) => MadnessCard.fromMap(map)).toList();
      print(
          '🟡 查询 ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 的发疯记录: ${cards.length} 条');
      return cards;
    } catch (e) {
      print('❌ 按日期查询发疯记录失败: $e');
      return [];
    }
  }

  /// 按 ID 删除一条发疯记录
  /// 返回被删除的行数
  Future<int> deleteCard(int id) async {
    try {
      // Web 平台使用内存存储
      if (_isWeb) {
        await _loadWebCards();
        final before = _webCards.length;
        _webCards.removeWhere((c) => c.id == id);
        final deleted = before - _webCards.length;
        if (deleted > 0) {
          await _persistWebCards();
        }
        print('🟢 [Web] 已删除 ID=$id 的发疯记录，影响行数: $deleted');
        return deleted;
      }

      final db = await database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🟢 已删除 ID=$id 的发疯记录，影响行数: $count');
      return count;
    } catch (e) {
      print('❌ 删除发疯记录失败: $e');
      rethrow;
    }
  }

  // ============ Web 端 localStorage 持久化 ============

  /// 从 SharedPreferences 加载 Web 端卡片数据
  Future<void> _loadWebCards() async {
    if (_webLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_webStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _webCards.clear();
        for (final map in list) {
          _webCards.add(MadnessCard.fromMap(Map<String, dynamic>.from(map)));
        }
        print('📂 [Web] 已从本地加载 ${_webCards.length} 条记录');
      }
      _webIdCounter = prefs.getInt(_webIdCounterKey) ?? 0;
      _webLoaded = true;
    } catch (e) {
      print('❌ [Web] 加载缓存失败: $e');
    }
  }

  /// 将 Web 端卡片数据保存到 SharedPreferences
  Future<void> _persistWebCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webCards.map((c) => c.toMap()).toList();
      await prefs.setString(_webStorageKey, jsonEncode(list));
      await prefs.setInt(_webIdCounterKey, _webIdCounter);
      print('💾 [Web] 已持久化 ${_webCards.length} 条记录');
    } catch (e) {
      print('❌ [Web] 持久化失败: $e');
    }
  }
}
