import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/studio_theme.dart';

class StudioLoader extends StatefulWidget {
  final double size;
  final Duration duration;
  final bool loop;

  const StudioLoader({
    super.key,
    this.size = 300,
    this.duration = const Duration(seconds: 3),
    this.loop = true,
  });

  @override
  State<StudioLoader> createState() => _StudioLoaderState();
}

class _StudioLoaderState extends State<StudioLoader>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController.forward().then((_) {
      if (widget.loop) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_progressController, _pulseController]),
          builder: (context, child) {
            double scale = 1.0;
            if (_progressController.isCompleted) {
              scale = _pulseAnimation.value;
            }
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size(widget.size, widget.size * 0.27),
                painter: _WaveformPainter(
                  progress: _progressAnimation.value,
                  pulseGlow: _progressController.isCompleted ? _pulseController.value : 0.0,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final double pulseGlow;

  _WaveformPainter({
    required this.progress,
    required this.pulseGlow,
  });

  // Identical bar height mappings as the index.html SVG waveform
  final List<double> barHeights = [
    8, 12, 10, 16, 24, 20, 36, 48, 40, 56, 68, 60, 72, 76, 80, 76, 72, 60, 68, 56, 40, 48, 36, 20, 24, 16, 10, 12, 8
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 10.0;
    final double waveWidth = size.width - (padding * 2);
    final double centerY = size.height / 2;
    
    final int totalBars = barHeights.length;
    final double spacing = waveWidth / (totalBars - 1);

    // 1. Draw Background Waveform (Low Opacity Outline)
    final Paint bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < totalBars; i++) {
      final double x = padding + (i * spacing);
      final double h = (barHeights[i] / 80) * size.height;
      canvas.drawLine(
        Offset(x, centerY - (h / 2)),
        Offset(x, centerY + (h / 2)),
        bgPaint,
      );
    }

    // 2. Draw Filled Waveform (Linear Gradient up to progress threshold)
    final double activeWidth = progress * waveWidth;
    final Paint fgPaint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Set Shader Gradient matching Studduo Brand (Green to Yellow)
    final Rect shaderBounds = Rect.fromLTWH(padding, 0, waveWidth, size.height);
    fgPaint.shader = const LinearGradient(
      colors: [Color(0xFF00FFCC), Color(0xFFFFD700)],
    ).createShader(shaderBounds);

    if (pulseGlow > 0.0) {
      // Apply breathing glow shadow when fully loaded
      fgPaint.colorFilter = ColorFilter.mode(
        const Color(0xFF00FFCC).withOpacity(pulseGlow * 0.15),
        BlendMode.plus,
      );
    }

    for (int i = 0; i < totalBars; i++) {
      final double x = padding + (i * spacing);
      // Only draw if within the current fill boundary
      if (x - padding <= activeWidth) {
        final double h = (barHeights[i] / 80) * size.height;
        canvas.drawLine(
          Offset(x, centerY - (h / 2)),
          Offset(x, centerY + (h / 2)),
          fgPaint,
        );
      }
    }

    // 3. Draw Traveling Neural Particle on the active boundary edge
    if (progress > 0.0 && progress < 1.0) {
      final double particleX = padding + activeWidth;
      
      // Calculate smooth height interpolation at active boundary
      final int lowerIndex = (activeWidth / spacing).floor();
      final int upperIndex = (lowerIndex + 1).clamp(0, totalBars - 1);
      final double factor = (activeWidth / spacing) - lowerIndex;
      
      final double h1 = (barHeights[lowerIndex] / 80) * size.height;
      final double h2 = (barHeights[upperIndex] / 80) * size.height;
      final double interpolatedH = h1 + (h2 - h1) * factor;

      // Jitter/oscillate vertically along the top/bottom tips of the active bar
      final double time = DateTime.now().millisecondsSinceEpoch * 0.005;
      final double oscillation = math.sin(time + particleX * 0.05);
      final double particleY = centerY + (oscillation * (interpolatedH / 2));

      // Draw particle halo (Purple glow)
      final Paint haloPaint = Paint()
        ..color = const Color(0xFFD03BFF).withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(particleX, particleY), 6.5, haloPaint);

      // Draw particle core (Green center)
      final Paint corePaint = Paint()
        ..color = const Color(0xFF00FFCC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(particleX, particleY), 3.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulseGlow != pulseGlow;
  }
}
