/// =====================================================
/// 文件：lib/screens/home_page.dart
/// 功能：首页 - "今天发什么疯？"
/// 描述：Emoji选择、渐变色滑轨、发疯语录输入、AI生成按钮
/// =====================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/madness_provider.dart';
import '../widgets/chaos_particle.dart';
import '../services/ai_madness_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// ============ 数据 ============

  /// 发疯专用 Emoji 列表
  static const List<String> _emojiList = [
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

  /// 预设渐变色组（每对 [startHex, endHex]）
  static const List<List<String>> _gradientPresets = [
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

  /// 将十六进制字符串解析为 Color
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  // ============ 文本控制器（保持输入状态） ============
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<MadnessProvider>(
      builder: (context, provider, _) {
        // 同步 provider 文本到 controller
        if (_textController.text != provider.userText) {
          _textController.text = provider.userText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: provider.userText.length),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // ---- 混乱粒子特效背景 ----
              ChaosParticleBackground(
                baseColor: provider.gradientStart,
                emoji: provider.emoji,
              ),

              // ---- 主内容 ----
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ======== 顶部预览区 (40% 屏幕高度) ========
                      _buildPreviewArea(provider, screenHeight),

                      const SizedBox(height: 16),

                      // ======== 中部功能区 ========
                      _buildEmojiSelector(provider),
                      const SizedBox(height: 12),
                      _buildGradientSelector(provider),
                      const SizedBox(height: 12),

                      // ======== 底部输入区 ========
                      _buildTextInput(provider),

                      const SizedBox(height: 16),

                      // ======== 生成卡片按钮 ========
                      _buildGenerateButton(screenWidth, provider),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ======== 顶部预览区 ========
  Widget _buildPreviewArea(MadnessProvider provider, double screenHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: screenHeight * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [provider.gradientStart, provider.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 巨大的 Emoji（带阴影）
          Text(
            provider.emoji,
            style: TextStyle(
              fontSize: 80,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 副标题
          const Text(
            '今日份发疯',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ======== Emoji 选择面板 ========
  Widget _buildEmojiSelector(MadnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选个表情',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _emojiList.map((emoji) {
              final isSelected = provider.emoji == emoji;
              return GestureDetector(
                onTap: () => provider.setEmoji(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white30,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ======== 渐变颜色滑轨 ========
  Widget _buildGradientSelector(MadnessProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '选个配色',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _gradientPresets.length,
            itemBuilder: (context, index) {
              final preset = _gradientPresets[index];
              final startColor = _hexToColor(preset[0]);
              final endColor = _hexToColor(preset[1]);

              final isSelected = provider.startColorHex == preset[0] &&
                  provider.endColorHex == preset[1];

              return GestureDetector(
                onTap: () {
                  provider.setGradientFromHex(preset[0], preset[1]);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [startColor, endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ======== 底部输入区 ========
  Widget _buildTextInput(MadnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        maxLines: 2,
        controller: _textController,
        onChanged: (value) => provider.setUserText(value),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: '输入今日发疯语录...（也可点AI魔法棒生成）',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            tooltip: 'AI 发疯文学生成',
            onPressed: () {
              _showAiPhrasesDialog(context, provider);
            },
          ),
        ),
      ),
    );
  }

  /// ======== 底部生成按钮 ========
  Widget _buildGenerateButton(
      double screenWidth, MadnessProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (provider.userText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入发疯语录再生成！')),
              );
              return;
            }

            Navigator.pushNamed(
              context,
              '/preview',
              arguments: {
                'emoji': provider.emoji,
                'startColor': provider.startColorHex,
                'endColor': provider.endColorHex,
                'userText': provider.userText,
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            elevation: 4,
          ),
          child: const Text(
            '✨ 生成我的发疯卡片',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// ======== AI 发疯文学弹窗 ========
  void _showAiPhrasesDialog(BuildContext context, MadnessProvider provider) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'AI 发疯文学生成中...',
            style: TextStyle(color: Colors.white),
          ),
          content: FutureBuilder<List<String>>(
            future: AIMadnessService.getMadnessPhrases(provider.emoji),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      '生成失败，请重试',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final phrases = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < phrases.length; i++) ...[
                    if (i > 0) const Divider(color: Colors.white24),
                    InkWell(
                      onTap: () {
                        provider.setUserText(phrases[i]);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}.',
                              style: const TextStyle(
                                  color: Colors.purpleAccent, fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                phrases[i],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}
