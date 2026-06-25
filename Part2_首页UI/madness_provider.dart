/// =====================================================
/// 文件：lib/providers/madness_provider.dart
/// 功能：发疯卡片状态管理
/// 描述：使用 ChangeNotifier 管理 emoji、渐变色、用户文本，
///        并通过 shared_preferences 实现持久化
/// =====================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 十六进制颜色字符串转 Color 的工具方法
Color hexToColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

/// Color 转十六进制字符串的工具方法
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

/// 发疯卡片状态管理 - ChangeNotifier
class MadnessProvider extends ChangeNotifier {
  // ============ 预设渐变色组 ============
  static const List<List<String>> presetGradients = [
    ['#FF9A9E', '#FECFEF'],
    ['#A18CD1', '#FBC2EB'],
    ['#FBC2EB', '#A6C1EE'],
    ['#F84F4F', '#F9D423'],
    ['#00C9FF', '#92FE9D'],
    ['#FC5C7D', '#6A82FB'],
    ['#F6D365', '#FDA085'],
    ['#42E695', '#3BB2B8'],
    ['#29323C', '#485563'],
    ['#232526', '#414345'],
  ];

  /// 发疯专用 Emoji 列表
  static const List<String> madnessEmojis = [
    '🤯',
    '😤',
    '🥵',
    '🤪',
    '😭',
    '🥳',
    '🤬',
    '😎',
    '🫠',
    '🤡',
  ];

  // ============ 状态变量 ============

  /// 当前选中的 Emoji，默认 🤯
  String _emoji = '🤯';

  /// 渐变起始颜色，默认 #FBC2EB
  Color _gradientStart = hexToColor('#FBC2EB');

  /// 渐变结束颜色，默认 #A6C1EE
  Color _gradientEnd = hexToColor('#A6C1EE');

  /// 用户输入的"发疯语录"
  String _userText = '';

  // ============ Getters ============

  String get emoji => _emoji;
  Color get gradientStart => _gradientStart;
  Color get gradientEnd => _gradientEnd;
  String get userText => _userText;

  /// 获取渐变色对应的十六进制字符串
  String get startColorHex => colorToHex(_gradientStart);
  String get endColorHex => colorToHex(_gradientEnd);

  // ============ 构造函数 ============

  MadnessProvider() {
    _loadFromPrefs();
  }

  // ============ 更新方法 ============

  /// 设置当前 Emoji
  void setEmoji(String newEmoji) {
    _emoji = newEmoji;
    notifyListeners();
  }

  /// 设置渐变色（通过十六进制字符串）
  void setGradientFromHex(String startHex, String endHex) {
    _gradientStart = hexToColor(startHex);
    _gradientEnd = hexToColor(endHex);
    notifyListeners();
  }

  /// 设置渐变色（通过 Color 对象）
  void setGradient(Color start, Color end) {
    _gradientStart = start;
    _gradientEnd = end;
    notifyListeners();
  }

  /// 设置用户文本
  void setUserText(String text) {
    _userText = text;
    notifyListeners();
  }

  /// 通过十六进制字符串设置起始颜色
  void setStartColorFromHex(String hex) {
    _gradientStart = hexToColor(hex);
    notifyListeners();
  }

  /// 通过十六进制字符串设置结束颜色
  void setEndColorFromHex(String hex) {
    _gradientEnd = hexToColor(hex);
    notifyListeners();
  }

  // ============ 持久化 ============

  /// 从 SharedPreferences 加载上次保存的状态
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _emoji = prefs.getString('madness_emoji') ?? '🤯';
      final savedStart = prefs.getString('madness_gradientStart');
      final savedEnd = prefs.getString('madness_gradientEnd');

      if (savedStart != null) {
        _gradientStart = hexToColor(savedStart);
      }
      if (savedEnd != null) {
        _gradientEnd = hexToColor(savedEnd);
      }

      // 加载后通知 UI 刷新
      notifyListeners();
      print('📂 已从本地加载偏好: emoji=$_emoji, start=$savedStart, end=$savedEnd');
    } catch (e) {
      print('❌ 加载偏好失败，使用默认值: $e');
    }
  }

  /// 保存当前状态到 SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('madness_emoji', _emoji);
      await prefs.setString('madness_gradientStart', colorToHex(_gradientStart));
      await prefs.setString('madness_gradientEnd', colorToHex(_gradientEnd));
      print('💾 偏好已保存: emoji=$_emoji');
    } catch (e) {
      print('❌ 保存偏好失败: $e');
    }
  }

  @override
  void dispose() {
    _saveToPrefs();
    super.dispose();
  }
}
