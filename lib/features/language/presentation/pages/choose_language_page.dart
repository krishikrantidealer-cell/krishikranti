import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:krishikranti/core/language_service.dart';
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
      duration: const Duration(milliseconds: 600),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: Stack(
          children: [
            _buildAnimatedMeshBackground(theme),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildCompactHeader(context, l10n, theme),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
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
        return Stack(
          children: [
            Container(color: const Color(0xFFF8FAF8)),
            Positioned(
              top: -80 + (20 * _blobController.value),
              right: -40,
              child: _BlurredBlob(
                size: 280,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -60,
              child: _BlurredBlob(
                size: 320,
                color: theme.colorScheme.secondary.withValues(alpha: 0.05),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/app_logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          Lottie.asset(
            'assets/animations/language_globe.json',
            height: 70,
            repeat: true,
            errorBuilder: (_, __, ___) => Icon(
              CupertinoIcons.globe,
              size: 50,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.selectLanguage,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Select your farming language",
            style: TextStyle(
              fontSize: 13,
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
        (index * 0.06).clamp(0.0, 0.5),
        (index * 0.06 + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutQuart,
      ),
    );

    final isSelected = currentLocale == lang['code'];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
          ),
        );
      },
    );
  }

  Widget _buildCompactButton(AppLocalizations l10n, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pushReplacementNamed('/phone-verify');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          "GET STARTED",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _CompactLanguageCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? theme.primaryColor.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : const Color(0xFFF1F3F1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  lang['native']![0],
                  style: TextStyle(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? theme.primaryColor
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
