/// =====================================================
/// 文件：lib/widgets/chaos_particle.dart
/// 功能：混乱粒子特效背景
/// 描述：使用 CustomPainter 绘制向上飘浮的粒子动画
///        不同 Emoji 映射不同的粒子符号，营造"发疯"氛围
/// =====================================================

import 'dart:math';
import 'package:flutter/material.dart';

/// 单个粒子数据
class _Particle {
  Offset position; // 当前位置
  double size; // 粒子大小 (15~25)
  double opacity; // 透明度 (0.3~0.8)
  double angle; // 旋转角度
  double speed; // 上浮速度 (0.3~1.5)
  String symbol; // 绘制的符号

  _Particle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.angle,
    required this.speed,
    required this.symbol,
  });

  /// 更新粒子位置（向上漂浮）
  void update(double screenHeight, double screenWidth, Random random) {
    // 向上移动
    position = Offset(position.dx, position.dy - speed);

    // 超出屏幕顶部时，重置到底部随机位置
    if (position.dy < -30) {
      position = Offset(
        random.nextDouble() * screenWidth,
        screenHeight + random.nextDouble() * 50,
      );
      // 随机刷新大小和符号
      size = 15 + random.nextDouble() * 10;
      opacity = 0.3 + random.nextDouble() * 0.5;
      symbol = _randomSymbol(random);
    }

    // 轻微水平摆动（"混乱感"）
    position = Offset(
      position.dx + (random.nextDouble() - 0.5) * 0.5,
      position.dy,
    );
  }
}

/// 随机生成粒子符号
String _randomSymbol(Random random) {
  const symbols = ['✦', '•', '✧', '◇', '○', '△', '✿', '♢', '◆', '◈', '❖', '✶'];
  return symbols[random.nextInt(symbols.length)];
}

/// 根据 Emoji 映射粒子主符号
List<String> _emojiToSymbols(String emoji) {
  switch (emoji) {
    case '🤯':
      return ['💥', '✦', '✧'];
    case '🥳':
      return ['🎉', '✨', '✿'];
    case '😭':
      return ['🌧️', '💧', '•'];
    case '😤':
      return ['🔥', '◆', '♢'];
    case '🤪':
      return ['🌀', '◇', '✶'];
    case '🥵':
      return ['☀️', '❖', '◆'];
    case '🤬':
      return ['⚡', '△', '◈'];
    case '😎':
      return ['★', '✦', '✧'];
    case '🫠':
      return ['💫', '○', '•'];
    case '🤡':
      return ['🎪', '✿', '♢'];
    default:
      return ['✦', '•', '✧'];
  }
}

/// ============ ChaosParticleBackground Widget ============
class ChaosParticleBackground extends StatefulWidget {
  /// 基础颜色（用于背景底色）
  final Color baseColor;

  /// 当前 Emoji（决定粒子符号）
  final String emoji;

  const ChaosParticleBackground({
    super.key,
    required this.baseColor,
    required this.emoji,
  });

  @override
  State<ChaosParticleBackground> createState() =>
      _ChaosParticleBackgroundState();
}

class _ChaosParticleBackgroundState extends State<ChaosParticleBackground>
    with SingleTickerProviderStateMixin {
  // ============ 动画控制器 ============
  late AnimationController _controller;

  // ============ 粒子列表 ============
  final List<_Particle> _particles = [];
  final Random _random = Random();

  // ============ 粒子符号映射 ============
  late List<String> _symbols;

  @override
  void initState() {
    super.initState();

    // 8 秒循环动画
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _symbols = _emojiToSymbols(widget.emoji);
  }

  @override
  void didUpdateWidget(ChaosParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Emoji 变化时更新符号映射
    if (oldWidget.emoji != widget.emoji) {
      _symbols = _emojiToSymbols(widget.emoji);
      _refreshParticles();
    }
  }

  /// 刷新所有粒子的符号
  void _refreshParticles() {
    for (final particle in _particles) {
      particle.symbol = _symbols[_random.nextInt(_symbols.length)];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ChaosParticlePainter(
            particles: _particles,
            symbols: _symbols,
            random: _random,
            baseColor: widget.baseColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// ============ ChaosParticlePainter ============
class _ChaosParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final List<String> symbols;
  final Random random;
  final Color baseColor;

  _ChaosParticlePainter({
    required this.particles,
    required this.symbols,
    required this.random,
    required this.baseColor,
  }) {
    // 初始化30个粒子（仅在列表为空时）
    if (particles.isEmpty) {
      // 这里在首次 paint 时进行懒初始化
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 懒初始化粒子
    if (particles.isEmpty) {
      _initParticles(size);
    }

    // 绘制背景底色
    final bgPaint = Paint()..color = baseColor.withOpacity(0.15);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制每个粒子
    for (final particle in particles) {
      // 更新粒子位置
      particle.update(size.height, size.width, random);

      // 使用 TextPainter 绘制粒子符号
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size,
            color: Colors.white.withOpacity(particle.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          particle.position.dx - textPainter.width / 2,
          particle.position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// 初始化30个粒子，随机分布在屏幕底部
  void _initParticles(Size size) {
    for (int i = 0; i < 30; i++) {
      particles.add(_Particle(
        position: Offset(
          random.nextDouble() * size.width,
          size.height * 0.3 + random.nextDouble() * size.height * 0.7,
        ),
        size: 15 + random.nextDouble() * 10,
        opacity: 0.3 + random.nextDouble() * 0.5,
        angle: random.nextDouble() * 2 * pi,
        speed: 0.3 + random.nextDouble() * 1.2,
        symbol: symbols[random.nextInt(symbols.length)],
      ));
    }
  }

  @override
  bool shouldRepaint(covariant _ChaosParticlePainter oldDelegate) {
    return true; // 始终重绘以保持60fps动画
  }
}
