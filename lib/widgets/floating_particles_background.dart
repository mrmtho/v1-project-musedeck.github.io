import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double speedY;
  double speedX;
  double radius;
  double opacity;
  double theta;
  double thetaSpeed;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.radius,
    required this.opacity,
    required this.theta,
    required this.thetaSpeed,
    required this.color,
  });
}

class FloatingParticlesBackground extends StatefulWidget {
  const FloatingParticlesBackground({super.key});

  @override
  State<FloatingParticlesBackground> createState() => _FloatingParticlesBackgroundState();
}

class _FloatingParticlesBackgroundState extends State<FloatingParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  final int _particleCount = 120;

  // Curated color palette matching Studduo's premium branding
  final List<Color> _brandColors = [
    const Color(0xFFD03BFF), // Purple accent
    const Color(0xFF00FFCC), // Cyan accent
    const Color(0xFF6C3BF5), // Blueish-purple base
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _initializeParticles(Size size) {
    if (_particles.isNotEmpty) return;

    for (int i = 0; i < _particleCount; i++) {
      final colorIndex = _random.nextInt(_brandColors.length);
      _particles.add(
        Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          speedY: 0.15 + _random.nextDouble() * 0.35, // slow upward drift
          speedX: -0.05 + _random.nextDouble() * 0.1, // very slight horizontal drift
          radius: 0.6 + _random.nextDouble() * 1.8, // varying sizes for depth
          opacity: 0.1 + _random.nextDouble() * 0.45, // subtle glow
          theta: _random.nextDouble() * pi * 2,
          thetaSpeed: 0.005 + _random.nextDouble() * 0.015,
          color: _brandColors[colorIndex],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initializeParticles(size);

        return CustomPaint(
          size: size,
          painter: ParticlePainter(
            particles: _particles,
            animation: _controller,
            size: size,
            random: _random,
          ),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final Size size;
  final Random random;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.size,
    required this.random,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // 1. Update Position
      particle.y -= particle.speedY;
      particle.x += particle.speedX + sin(particle.theta) * 0.15;
      particle.theta += particle.thetaSpeed;

      // 2. Wrap boundaries
      if (particle.y < -10) {
        // Reset to bottom
        particle.y = size.height + 10;
        particle.x = random.nextDouble() * size.width;
      }
      if (particle.x < -10) {
        particle.x = size.width + 10;
      } else if (particle.x > size.width + 10) {
        particle.x = -10;
      }

      // 3. Draw Particle
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      // For a premium touch, add a subtle soft glow around larger particles
      if (particle.radius > 1.5) {
        final glowPaint = Paint()
          ..color = particle.color.withOpacity(particle.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(particle.x, particle.y), particle.radius * 2.5, glowPaint);
      }

      canvas.drawCircle(Offset(particle.x, particle.y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
