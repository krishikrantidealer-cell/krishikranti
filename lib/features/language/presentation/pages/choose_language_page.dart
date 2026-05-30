import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class ChooseLanguagePage extends StatefulWidget {
  final bool isSettings;
  const ChooseLanguagePage({super.key, this.isSettings = false});

  @override
  State<ChooseLanguagePage> createState() => _ChooseLanguagePageState();
}

class _ChooseLanguagePageState extends State<ChooseLanguagePage>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _blobController;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLocale = languageService.locale.languageCode;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dts = Provider.of<DynamicTranslationService>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9F6),
        body: Stack(
          children: [
            _buildAnimatedMeshBackground(theme),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildCompactHeader(context, l10n, theme),
                  if (currentLocale != 'en' && dts.downloadErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dts.downloadErrorMessage!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedLanguageCard(
                          index,
                          _languages[index],
                          currentLocale,
                          languageService,
                          theme,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isSettings)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                child: _buildCompactButton(l10n, theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMeshBackground(ThemeData theme) {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        final t = _blobController.value * 2 * math.pi;

        // Blob 1: Green/Emerald - Top Right moving in a gentle ellipse
        final blob1X = 35 * math.cos(t);
        final blob1Y = 25 * math.sin(t);

        // Blob 2: Amber/Gold - Bottom Left moving in a figure-eight (Lissajous)
        final blob2X = 40 * math.sin(2 * t);
        final blob2Y = 30 * math.cos(t);

        // Blob 3: Accent Teal - Middle Right moving in a diagonal orbit
        final blob3X = 45 * math.sin(t);
        final blob3Y = 20 * math.sin(t + math.pi / 4);

        return Stack(
          children: [
            Container(color: const Color(0xFFF6F9F6)),
            // Blob 1 (Primary Green)
            Positioned(
              top: -80 + blob1Y,
              right: -60 + blob1X,
              child: _BlurredBlob(
                size: 340,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            // Blob 2 (Secondary Orange/Gold)
            Positioned(
              bottom: -40 + blob2Y,
              left: -80 + blob2X,
              child: _BlurredBlob(
                size: 380,
                color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              ),
            ),
            // Blob 3 (Teal Accent)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35 + blob3Y,
              right: -100 + blob3X,
              child: _BlurredBlob(
                size: 300,
                color: const Color(0xFF00BFA5).withValues(alpha: 0.07),
              ),
            ),
            // High-blur frosted glass overlay to blend the blobs organically
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isSettings)
                _TopIconButton(
                  icon: CupertinoIcons.chevron_left,
                  onTap: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 40),
              // Compact center globe with orbit
              Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _blobController,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CustomPaint(
                        painter: _DashedCirclePainter(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                          dashCount: 20,
                          dashWidth: 3,
                          spaceWidth: 3,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    ),
                  ),
                  Lottie.asset(
                    'assets/animations/language_globe.json',
                    height: 46,
                    repeat: true,
                    errorBuilder: (_, __, ___) => Icon(
                      CupertinoIcons.globe,
                      size: 26,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectLanguage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E293B),
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Select your farming language",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLanguageCard(
    int index,
    Map<String, String> lang,
    String currentLocale,
    LanguageService service,
    ThemeData theme,
  ) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        (index * 0.05).clamp(0.0, 0.4),
        (index * 0.05 + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );

    final isSelected = currentLocale == lang['code'];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 35 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: _CompactLanguageCard(
              lang: lang,
              isSelected: isSelected,
              theme: theme,
              onTap: () {
                HapticFeedback.lightImpact();
                service.setLocale(lang['code']!);
                if (widget.isSettings) {
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted) Navigator.pop(context);
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton(AppLocalizations l10n, ThemeData theme) {
    return _ShimmeringActionButton(
      text: "GET STARTED",
      theme: theme,
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacementNamed('/phone-verify');
      },
    );
  }
}

class _CompactLanguageCard extends StatefulWidget {
  final Map<String, String> lang;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _CompactLanguageCard({
    required this.lang,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_CompactLanguageCard> createState() => _CompactLanguageCardState();
}

class _CompactLanguageCardState extends State<_CompactLanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final Color cardBg = widget.isSelected
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.45);

    final Color borderColor = widget.isSelected
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.6);

    final double borderWidth = widget.isSelected ? 2.2 : 1.5;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: widget.isSelected
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.75,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade100,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isSelected
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (widget.isSelected)
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: TextStyle(
                                  color: widget.isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                                child: Text(widget.lang['native']![0]),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: widget.isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: widget.isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lang['native']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: widget.isSelected
                                  ? theme.colorScheme.primary
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.lang['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurredBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 80,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  State<_TopIconButton> createState() => _TopIconButtonState();
}

class _TopIconButtonState extends State<_TopIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(widget.icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}

class _ShimmeringActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final ThemeData theme;

  const _ShimmeringActionButton({
    required this.onPressed,
    required this.text,
    required this.theme,
  });

  @override
  State<_ShimmeringActionButton> createState() =>
      _ShimmeringActionButtonState();
}

class _ShimmeringActionButtonState extends State<_ShimmeringActionButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.arrow_right,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double dashWidth;
  final double spaceWidth;

  const _DashedCirclePainter({
    required this.color,
    this.dashCount = 24,
    this.dashWidth = 5.0,
    this.spaceWidth = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final double circumference = 2 * math.pi * radius;
    final double totalLength = dashWidth + spaceWidth;
    final int actualDashCount = (circumference / totalLength).floor();

    for (int i = 0; i < actualDashCount; i++) {
      final double angle = (i * 2 * math.pi) / actualDashCount;
      final double sweepAngle = (dashWidth / radius);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        angle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
