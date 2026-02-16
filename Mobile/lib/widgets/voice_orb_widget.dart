import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

enum OrbState { idle, listening, processing }

class VoiceOrbWidget extends StatefulWidget {
  final OrbState orbState;
  final double amplitude;
  final double size;
  final VoidCallback? onTap;

  const VoiceOrbWidget({
    super.key,
    required this.orbState,
    this.amplitude = 0.0,
    this.size = 120,
    this.onTap,
  });

  @override
  State<VoiceOrbWidget> createState() => _VoiceOrbWidgetState();
}

class _VoiceOrbWidgetState extends State<VoiceOrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _pulseController;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size * 1.8,
        height: widget.size * 1.8,
        child: AnimatedBuilder(
          animation: Listenable.merge(
            [_breatheController, _pulseController, _spinController],
          ),
          builder: (context, _) {
            return CustomPaint(
              painter: _OrbPainter(
                orbState: widget.orbState,
                amplitude: widget.amplitude,
                breatheValue: _breatheController.value,
                pulseValue: _pulseController.value,
                spinValue: _spinController.value,
              ),
              child: Center(
                child: _buildIcon(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    double iconSize = widget.size * 0.3;

    switch (widget.orbState) {
      case OrbState.idle:
        icon = Icons.mic_rounded;
        color = Colors.white;
        break;
      case OrbState.listening:
        icon = Icons.stop_rounded;
        color = Colors.white;
        break;
      case OrbState.processing:
        icon = Icons.hourglass_top_rounded;
        color = AppTheme.orbProcessing;
        break;
    }

    return Icon(icon, color: color, size: iconSize);
  }
}

class _OrbPainter extends CustomPainter {
  final OrbState orbState;
  final double amplitude;
  final double breatheValue;
  final double pulseValue;
  final double spinValue;

  _OrbPainter({
    required this.orbState,
    required this.amplitude,
    required this.breatheValue,
    required this.pulseValue,
    required this.spinValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.22;

    switch (orbState) {
      case OrbState.idle:
        _paintIdle(canvas, center, baseRadius);
        break;
      case OrbState.listening:
        _paintListening(canvas, center, baseRadius);
        break;
      case OrbState.processing:
        _paintProcessing(canvas, center, baseRadius);
        break;
    }
  }

  void _paintIdle(Canvas canvas, Offset center, double radius) {
    final scale = 1.0 + breatheValue * 0.06;
    final r = radius * scale;

    // Soft outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGreen.withValues(alpha: 0.12 + breatheValue * 0.05),
          AppTheme.accentGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.2));
    canvas.drawCircle(center, r * 2.2, glowPaint);

    // Ring
    final ringPaint = Paint()
      ..color = AppTheme.accentGreen.withValues(alpha: 0.15 + breatheValue * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r * 1.4, ringPaint);

    // Core orb
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGreen,
          AppTheme.emerald,
          AppTheme.deepGreen,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, orbPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.7, highlightPaint);
  }

  void _paintListening(Canvas canvas, Offset center, double radius) {
    final ampScale = 0.15 + amplitude * 0.5;
    final pulseR = radius * (1.0 + pulseValue * 0.08 + ampScale * 0.12);

    // Ripples
    for (int i = 3; i >= 1; i--) {
      final rippleR = pulseR * (1.0 + i * 0.25 + ampScale * i * 0.08);
      final alpha = (0.08 - i * 0.02).clamp(0.01, 0.12);
      final ripplePaint = Paint()
        ..color = AppTheme.orbRecording.withValues(alpha: alpha + pulseValue * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, rippleR, ripplePaint);
    }

    // Waveform ring
    final wavePath = Path();
    for (int i = 0; i <= 360; i += 2) {
      final angle = i * pi / 180;
      final noise = sin(angle * 6 + spinValue * 2 * pi) * ampScale * radius * 0.3 +
          cos(angle * 4 + spinValue * 3 * pi) * ampScale * radius * 0.15;
      final waveR = pulseR * 1.2 + noise;
      final x = center.dx + cos(angle) * waveR;
      final y = center.dy + sin(angle) * waveR;
      if (i == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    wavePath.close();

    final wavePaint = Paint()
      ..color = AppTheme.orbRecording.withValues(alpha: 0.2 + pulseValue * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(wavePath, wavePaint);

    // Core - red tint
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.orbRecording,
          const Color(0xFFE11D48),
          const Color(0xFF9F1239),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: pulseR));
    canvas.drawCircle(center, pulseR, orbPaint);

    // Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: pulseR));
    canvas.drawCircle(center, pulseR * 0.6, highlightPaint);
  }

  void _paintProcessing(Canvas canvas, Offset center, double radius) {
    // Spinning arc
    final arcPaint = Paint()
      ..color = AppTheme.orbProcessing.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.4),
      spinValue * 2 * pi,
      pi * 1.2,
      false,
      arcPaint,
    );

    // Second arc
    final arc2Paint = Paint()
      ..color = AppTheme.accentGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.15),
      -spinValue * 2 * pi + pi,
      pi * 0.8,
      false,
      arc2Paint,
    );

    // Core orb
    final scale = 0.95 + breatheValue * 0.05;
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.orbProcessing,
          AppTheme.warmOrange,
          const Color(0xFFB45309),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * scale));
    canvas.drawCircle(center, radius * scale, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
