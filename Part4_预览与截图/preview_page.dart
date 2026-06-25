/// =====================================================
/// 文件：lib/screens/preview_page.dart
/// 功能：发疯卡片预览页
/// 描述：毛玻璃视觉效果卡片 + 保存到数据库 + 截图保存相册
/// =====================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/madness_card_model.dart';
import '../services/madness_database.dart';
import '../utils/screenshot_helper.dart';

/// 十六进制颜色字符串转 Color
Color _hexToColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 通过路由参数接收数据
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String emoji = args['emoji'] as String;
    final String startColorHex = args['startColor'] as String;
    final String endColorHex = args['endColor'] as String;
    final String userText = args['userText'] as String;

    final Color startColor = _hexToColor(startColorHex);
    final Color endColor = _hexToColor(endColorHex);

    // 用于截图的 GlobalKey
    final GlobalKey cardKey = GlobalKey();

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // ---- 全屏渐变背景 ----
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ---- 主内容 ----
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 返回按钮
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---- 核心卡片区域（毛玻璃） ----
                  RepaintBoundary(
                    key: cardKey,
                    child: _buildGlassmorphismCard(
                      emoji: emoji,
                      userText: userText,
                      startColor: startColor,
                      endColor: endColor,
                      cardWidth: screenWidth * 0.82,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---- 底部按钮区 ----
                  _buildBottomButtons(
                    context,
                    cardKey,
                    emoji,
                    startColorHex,
                    endColorHex,
                    userText,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ======== 毛玻璃卡片 ========
  Widget _buildGlassmorphismCard({
    required String emoji,
    required String userText,
    required Color startColor,
    required Color endColor,
    required double cardWidth,
  }) {
    final cardHeight = cardWidth * 1.2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // 卡片内容
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 表情
                    Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 70,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 发疯语录
                    Text(
                      userText.isNotEmpty ? userText : '今日不想说话',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'serif',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    // 底部日期
                    Text(
                      DateTime.now().toString().substring(0, 16),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // 右下角水印
              Positioned(
                right: 16,
                bottom: 12,
                child: Text(
                  '#今日份发疯',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ======== 底部按钮区 ========
  Widget _buildBottomButtons(
    BuildContext context,
    GlobalKey cardKey,
    String emoji,
    String startColorHex,
    String endColorHex,
    String userText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ---- 发疯存档按钮 ----
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveToDatabase(
                context,
                emoji,
                startColorHex,
                endColorHex,
                userText,
              ),
              icon: const Icon(Icons.save),
              label: const Text('发疯存档'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ---- 保存相册按钮 ----
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _saveToGallery(context, cardKey),
              icon: const Icon(Icons.photo_library),
              label: const Text('存到相册发朋友圈'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ======== 保存到数据库 ========
  Future<void> _saveToDatabase(
    BuildContext context,
    String emoji,
    String startColorHex,
    String endColorHex,
    String userText,
  ) async {
    try {
      final card = MadnessCard(
        emoji: emoji,
        startColor: startColorHex,
        endColor: endColorHex,
        userText: userText,
        createDate: DateTime.now(),
      );

      await DatabaseService().insertCard(card);

      // 检查 mounted 再弹出 SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🧠 发疯证据已保存！')),
        );
        // 返回首页
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ 保存到数据库失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 保存失败: $e')),
        );
      }
    }
  }

  /// ======== 截图保存到相册 ========
  Future<void> _saveToGallery(
      BuildContext context, GlobalKey cardKey) async {
    try {
      if (!context.mounted) return;

      // 显示保存中提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🖼️ 正在保存...'),
          duration: Duration(seconds: 1),
        ),
      );

      final success = await ScreenshotHelper.captureAndSave(cardKey);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🖼️ 已保存到相册，快去发疯吧！')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ 保存失败，请检查权限设置')),
          );
        }
      }
    } catch (e) {
      print('❌ 截图保存失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 保存失败: $e')),
        );
      }
    }
  }
}
