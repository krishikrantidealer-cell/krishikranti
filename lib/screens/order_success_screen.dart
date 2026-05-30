import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/screens/my_orders_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  int secondsRemaining = 4;
  Timer? redirectTimer;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Trigger the text/card animation after the success checkmark has time to draw
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
    redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 1) {
        if (mounted) {
          setState(() {
            secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Sleek Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8F5E9), // Soft elegant mint green
                    Colors.white,
                  ],
                ),
              ),
            ),

            // 2. Central Content Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Advanced Custom Flutter Success Animation
                    const CustomSuccessAnimation(),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: _showContent ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: _showContent
                            ? Offset.zero
                            : const Offset(0, 0.2),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        child: TypewriterText(
                          text:
                              "Thank you for your purchase. We are preparing your order for shipment. Let's get growing!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          start: _showContent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 3. Wide Floating Action Button
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.24),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Cancel the timer to prevent double-navigation actions
                          redirectTimer?.cancel();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyOrdersScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(29),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Go to My Orders (${secondsRemaining}s)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(CupertinoIcons.arrow_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSuccessAnimation extends StatefulWidget {
  const CustomSuccessAnimation({super.key});

  @override
  State<CustomSuccessAnimation> createState() => _CustomSuccessAnimationState();
}

class _CustomSuccessAnimationState extends State<CustomSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _particlesController;
  late Animation<double> _particlesAnimation;

  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    // 1. Badge 3D Flip & Scale Entrance
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    );
    _rotateAnimation = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeOutExpo,
    );

    // 2. Checkmark Drawing
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOutCirc,
    );

    // 3. Continuous Multi-Ring Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: false);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutSine,
    );

    // 4. Advanced Particle Explosion (Stars & Circles)
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _particlesAnimation = CurvedAnimation(
      parent: _particlesController,
      curve: Curves.easeOutQuart,
    );

    // 5. Subtle Spinning Outer Orbit Accent Ring
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Start Choreography
    _badgeController.forward().then((_) {
      _checkController.forward();
    });
    _particlesController.forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _checkController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Expanding Gradient Glow Pulse Rings
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150 + (_pulseAnimation.value * 140),
                    height: 150 + (_pulseAnimation.value * 140),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(
                          0xFF2E7D32,
                        ).withOpacity((1.0 - _pulseAnimation.value) * 0.3),
                        width: 2.0,
                      ),
                      color: const Color(
                        0xFF81C784,
                      ).withOpacity((1.0 - _pulseAnimation.value) * 0.15),
                    ),
                  ),
                  Container(
                    width: 150 + (_pulseAnimation.value * 70),
                    height: 150 + (_pulseAnimation.value * 70),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xFF2E7D32,
                      ).withOpacity((1.0 - _pulseAnimation.value) * 0.25),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Rotating Orbit Accent Ring
          AnimatedBuilder(
            animation: _spinController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _OrbitRingPainter(),
                ),
              );
            },
          ),

          // 3. Multi-Layer Dynamic Particle Burst
          AnimatedBuilder(
            animation: _particlesAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(340, 340),
                painter: _AdvancedParticlesPainter(
                  progress: _particlesAnimation.value,
                ),
              );
            },
          ),

          // 4. Central 3D Badge with Animated Checkmark
          AnimatedBuilder(
            animation: _badgeController,
            builder: (context, child) {
              final scale = _scaleAnimation.value;
              final rotateY = (1.0 - _rotateAnimation.value) * math.pi;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(rotateY)
                  ..scale(scale, scale),
                alignment: Alignment.center,
                child: Container(
                  width: 146,
                  height: 146,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: _rotateAnimation.value > 0.5
                      ? AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _CheckmarkPainter(
                                progress: _checkAnimation.value,
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const dashWidth = 8.0;
    const dashSpace = 8.0;
    double circumference = 2 * math.pi * radius;
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    double sweepAngle = (dashWidth / circumference) * 2 * math.pi;
    double spaceAngle = (dashSpace / circumference) * 2 * math.pi;

    double currentAngle = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle + spaceAngle;
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + radius, center.dy), 4.0, dotPaint);
    canvas.drawCircle(Offset(center.dx - radius, center.dy), 3.0, dotPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - radius), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final p1 = Offset(size.width * 0.3, size.height * 0.52);
    final p2 = Offset(size.width * 0.45, size.height * 0.65);
    final p3 = Offset(size.width * 0.72, size.height * 0.38);

    if (progress < 0.5) {
      final t = progress / 0.5;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final t = (progress - 0.5) / 0.5;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AdvancedParticlesPainter extends CustomPainter {
  final double progress;

  _AdvancedParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.48;

    final paint = Paint()..style = PaintingStyle.fill;

    const particleCount = 24;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount + (i % 2 * 0.2);
      final isStar = i % 3 == 0;
      final speedMult = isStar ? 1.0 : (i % 2 == 0 ? 0.8 : 0.6);

      final currentRadius =
          50.0 +
          (maxRadius * speedMult * Curves.easeOutQuart.transform(progress));
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      paint.color =
          (i % 2 == 0
                  ? const Color(0xFF2E7D32)
                  : (isStar
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF81C784)))
              .withOpacity(opacity);

      if (isStar) {
        _drawStar(canvas, Offset(x, y), 8.0 * (1.0 - progress * 0.2), paint);
      } else {
        final pSize = (i % 2 == 0 ? 6.0 : 4.0) * (1.0 - progress * 0.2);
        canvas.drawCircle(Offset(x, y), pSize, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset position, double size, Paint paint) {
    final path = Path();
    path.moveTo(position.dx, position.dy - size);
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx + size,
      position.dy,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx,
      position.dy + size,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx - size,
      position.dy,
    );
    path.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx,
      position.dy - size,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AdvancedParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Duration duration;
  final bool start;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.duration = const Duration(milliseconds: 25),
    this.start = false,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.start) {
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.start && !oldWidget.start) {
      _startTyping();
    } else if (!widget.start && oldWidget.start) {
      _timer?.cancel();
      setState(() {
        _displayedText = "";
        _currentIndex = 0;
      });
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = "";
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _currentIndex++;
            _displayedText = widget.text.substring(0, _currentIndex);
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      textAlign: widget.textAlign,
      style: widget.style,
    );
  }
}
