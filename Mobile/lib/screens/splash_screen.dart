import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _orbScale;
  late Animation<double> _orbFade;
  late Animation<double> _textFade;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _orbScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    _orbFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();

    // Navigate to home after splash
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: AnimatedBuilder(
          animation: Listenable.merge([_mainController, _pulseController]),
          builder: (context, _) {
            return Stack(
              children: [
                // Floating particles
                ..._buildParticles(),

                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Orb
                      Transform.scale(
                        scale: _orbScale.value,
                        child: Opacity(
                          opacity: _orbFade.value,
                          child: _buildOrb(),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Title
                      Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _textFade.value)),
                          child: Text(
                            'Farmer Copilot',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - _subtitleFade.value)),
                          child: Text(
                            'Your AI Farming Assistant',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrb() {
    final pulseScale = 1.0 + _pulseController.value * 0.05;

    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _SplashOrbPainter(
          pulseValue: _pulseController.value,
          scale: pulseScale,
        ),
        child: Center(
          child: Icon(
            Icons.eco_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 42,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final random = Random(42);
    final particles = <Widget>[];

    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final size = 3.0 + random.nextDouble() * 4;
      final delay = random.nextDouble();

      final progress = (_mainController.value - delay * 0.3).clamp(0.0, 1.0);
      final alpha = (sin(progress * pi) * 0.5).clamp(0.0, 1.0);

      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y -
              progress * 50,
          child: Opacity(
            opacity: alpha,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}

class _SplashOrbPainter extends CustomPainter {
  final double pulseValue;
  final double scale;

  _SplashOrbPainter({required this.pulseValue, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32 * scale;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGreen.withValues(alpha: 0.15 + pulseValue * 0.05),
          AppTheme.accentGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.5));
    canvas.drawCircle(center, radius * 2.5, glowPaint);

    // Ring
    final ringPaint = Paint()
      ..color = AppTheme.accentGreen.withValues(alpha: 0.12 + pulseValue * 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 1.6, ringPaint);

    // Core
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGreen,
          AppTheme.emerald,
          AppTheme.deepGreen,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orbPaint);

    // Highlight
    final highlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.6, highlight);
  }

  @override
  bool shouldRepaint(covariant _SplashOrbPainter oldDelegate) => true;
}
