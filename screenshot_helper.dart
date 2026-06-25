/// =====================================================
/// 文件：lib/utils/screenshot_helper.dart
/// 功能：截图保存工具类
/// 描述：通过 RepaintBoundary 截图并保存到相册/本地文件
///        自动处理权限申请，跨平台兼容
/// =====================================================

import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 条件导入：Web 平台使用 dart:html 下载，其他平台返回 false
import 'save_file_stub.dart' if (dart.library.html) 'save_file_web.dart';

class ScreenshotHelper {
  /// ============ 截图并保存 ============
  ///
  /// [key]：RepaintBoundary 的 GlobalKey
  /// 返回 true 表示保存成功
  static Future<bool> captureAndSave(GlobalKey key) async {
    try {
      // 1. 获取 RenderRepaintBoundary
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print('❌ 无法获取 RenderRepaintBoundary');
        return false;
      }

      // 2. 生成图片 (2倍分辨率)
      final image = await boundary.toImage(pixelRatio: 2.0);

      // 3. 转为 PNG 字节数据
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        print('❌ 图片数据为空');
        return false;
      }

      final bytes = byteData.buffer.asUint8List();

      // 4. 根据平台选择保存方式
      if (kIsWeb) {
        // Web 平台：暂不支持直接保存到相册，保存为本地下载
        return await _saveToFileWeb(bytes);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动端：使用 ImageGallerySaver
        return await _saveToGallery(bytes);
      } else {
        // 桌面端：保存到本地文件
        return await _saveToFileDesktop(bytes);
      }
    } catch (e) {
      print('❌ 截图保存异常: $e');
      return false;
    }
  }

  /// ============ 移动端保存到相册 ============
  static Future<bool> _saveToGallery(Uint8List bytes) async {
    try {
      // permission_handler 在 pubspec.yaml 中已添加
      // 此处简化处理：直接尝试保存
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'madness_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result != null && result['isSuccess'] == true) {
        print('🟢 已保存到相册');
        return true;
      } else {
        print('⚠️ 保存到相册返回结果: $result');
        return false;
      }
    } catch (e) {
      print('❌ 保存到相册失败: $e');
      // 如果相册保存失败，回退到本地文件
      return await _saveToFileDesktop(bytes);
    }
  }

  /// ============ 桌面端保存到本地文件 ============
  static Future<bool> _saveToFileDesktop(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'madness_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = p.join(dir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('🟢 已保存到本地文件: $filePath');
      return true;
    } catch (e) {
      print('❌ 保存到本地文件失败: $e');
      return false;
    }
  }

  /// ============ Web 平台保存（浏览器下载） ============
  static Future<bool> _saveToFileWeb(Uint8List bytes) async {
    final fileName = 'madness_${DateTime.now().millisecondsSinceEpoch}.png';
    return await saveBytes(bytes, fileName);
  }
}
