import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseUserTypePage extends StatefulWidget {
  const ChooseUserTypePage({super.key});

  @override
  State<ChooseUserTypePage> createState() => _ChooseUserTypePageState();
}

class _ChooseUserTypePageState extends State<ChooseUserTypePage>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _blobController;

  String? _selectedUserType; // User must explicitly select

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'selectUserType': 'Select User Type',
      'subtitle': 'Choose how you want to use KrishiDealer',
      'retailerTitle': 'Retailer / Wholesaler',
      'retailerDesc':
          'Order fertilizers, seeds & agrochemicals in bulk for retail or wholesale business.',
      'farmerTitle': 'Farmer',
      'farmerDesc':
          'Purchase premium organic inputs directly for personal cultivation.',
      'continue': 'CONTINUE',
      'selectUserTypeError': 'Please select a user type to continue',
    },
    'hi': {
      'selectUserType': 'यूज़र का प्रकार चुनें',
      'subtitle': 'चुनें कि आप कृषिडीलर का उपयोग कैसे करना चाहते हैं',
      'retailerTitle': 'रिटेलर / थोक विक्रेता',
      'retailerDesc':
          'अपनी दुकान या व्यवसाय के लिए थोक में उर्वरक, बीज और कृषि रसायन ऑर्डर करें।',
      'farmerTitle': 'किसान',
      'farmerDesc': 'व्यक्तिगत खेती के लिए सीधे प्रीमियम जैविक इनपुट खरीदें।',
      'continue': 'जारी रखें',
      'selectUserTypeError': 'कृपया आगे बढ़ने के लिए यूज़र का प्रकार चुनें',
    },
    'ta': {
      'selectUserType': 'பயனர் வகையைத் தேர்ந்தெடுக்கவும்',
      'subtitle':
          'கிருஷி டீலரை எவ்வாறு பயன்படுத்த விரும்புகிறீர்கள் என்பதைத் தேர்வுசெய்க',
      'retailerTitle': 'சில்லறை / மொத்த விற்பனையாளர்',
      'retailerDesc':
          'உங்கள் சில்லறை அல்லது மொத்த விற்பனை வணிகத்திற்காக உரங்கள், விதைகள் மற்றும் வேளாண் இரசாயனங்கள் மொத்தமாக ஆர்டர் செய்யுங்கள்.',
      'farmerTitle': 'விவசாயி',
      'farmerDesc':
          'தனிப்பட்ட சாகுபடிக்கு நேரடியாக பிரீமியம் கரிம உள்ளீடுகளை வாங்கவும்.',
      'continue': 'தொடரவும்',
      'selectUserTypeError': 'தொடர பயனர் வகையைத் தேர்ந்தெடுக்கவும்',
    },
    'te': {
      'selectUserType': 'యూజర్ రకాన్ని ఎంచుకోండి',
      'subtitle': 'కృషిడీలర్‌ను మీరు ఎలా ఉపయోగించాలనుకుంటున్నారో ఎంచుకోండి',
      'retailerTitle': 'రిటైలర్ / హోల్‌సేలర్',
      'retailerDesc':
          'మీ రిటైల్ లేదా హోల్‌సేల్ వ్యాపారం కోసం ఎరువులు, విత్తనాలు & ఆగ్రోకెమికల్స్ బల్క్‌గా ఆర్డర్ చేయండి.',
      'farmerTitle': 'రైతు',
      'farmerDesc':
          'వ్యక్తిగత సాగు కోసం ప్రీమియం సేంద్రీయ ఇన్‌పుట్‌లను నేరుగా కొనుగోలు చేయండి.',
      'continue': 'కొనసాగించండి',
      'selectUserTypeError': 'కొనసాగడానికి దయచేసి యూజర్ రకాన్ని ఎంచుకోండి',
    },
    'mr': {
      'selectUserType': 'वापरकर्ता प्रकार निवडा',
      'subtitle': 'तुम्ही कृषीडीलरचा कसा वापर करू इच्छिता ते निवडा',
      'retailerTitle': 'रिटेलर / घाऊक व्यापारी',
      'retailerDesc':
          'तुमच्या किरकोळ किंवा घाऊक व्यवसायासाठी खते, बियाणे आणि कृषी रसायने घाऊक प्रमाणात ऑर्डर करा.',
      'farmerTitle': 'शेतकरी',
      'farmerDesc':
          'वैयक्तिक शेतीसाठी थेट प्रीमियम सेंद्रिय उत्पादने खरेदी करा.',
      'continue': 'पुढे जा',
      'selectUserTypeError': 'कृपया पुढे जाण्यासाठी वापरकर्ता प्रकार निवडा',
    },
    'kn': {
      'selectUserType': 'ಬಳಕೆದಾರರ ಪ್ರಕಾರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'subtitle': 'ಕೃಷಿಡೀಲರ್ ಅನ್ನು ನೀವು ಹೇಗೆ ಬಳಸಲು ಬಯಸುತ್ತೀರಿ ಎಂಬುದನ್ನು ಆರಿಸಿ',
      'retailerTitle': 'ಚಿಲ್ಲರೆ / ಸಗಟು ವ್ಯಾಪಾರಿ',
      'retailerDesc':
          'ನಿಮ್ಮ ಚಿಲ್ಲರೆ ಅಥವಾ ಸಗಟು ವ್ಯಾಪಾರಕ್ಕಾಗಿ ರಸಗೊಬ್ಬರಗಳು, ಬೀಜಗಳು ಮತ್ತು ಕೃಷಿ ರಾಸಾಯನಿಕಗಳನ್ನು ದೊಡ್ಡ ಪ್ರಮಾಣದಲ್ಲಿ ಆರ್ಡರ್ ಮಾಡಿ.',
      'farmerTitle': 'ರೈತ',
      'farmerDesc':
          'ವೈಯಕ್ತಿಕ ಕೃಷಿಗಾಗಿ ಪ್ರೀಮಿಯಂ ಸಾವಯವ ಪರಿಕರಗಳನ್ನು ನೇರವಾಗಿ ಖರೀದಿಸಿ.',
      'continue': 'ಮುಂದುವರಿಯಿರಿ',
      'selectUserTypeError':
          'ಮುಂದವರಿಯಲು ದಯವಿಟ್ಟು ಬಳಕೆದಾರರ ಪ್ರಕಾರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    },
  };

  String _getString(String key, String localeCode) {
    final Map<String, String> langMap =
        _localizedStrings[localeCode] ?? _localizedStrings['en']!;
    return langMap[key] ?? _localizedStrings['en']![key] ?? '';
  }

  void _clearUserTypeSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_user_type');
  }

  @override
  void initState() {
    super.initState();
    _clearUserTypeSelection();
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

  List<Color> _getSelectedGradient() {
    switch (_selectedUserType) {
      case 'farmer':
        return const [Color(0xFFE65100), Color(0xFFFF9800)];
      case 'retailer':
      default:
        return const [Color(0xFF2E7D32), Color(0xFF4CAF50)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLocale = languageService.locale.languageCode;
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> userTypes = [
      {
        'id': 'farmer',
        'title': _getString('farmerTitle', currentLocale),
        'desc': _getString('farmerDesc', currentLocale),
        'icon': Icons.agriculture_rounded,
        'gradient': const [Color(0xFFE65100), Color(0xFFFF9800)],
      },
      {
        'id': 'retailer',
        'title': _getString('retailerTitle', currentLocale),
        'desc': _getString('retailerDesc', currentLocale),
        'icon': Icons.storefront_rounded,
        'gradient': const [Color(0xFF2E7D32), Color(0xFF4CAF50)],
      },
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F9F6),
          body: Stack(
            children: [
              _buildAnimatedMeshBackground(theme),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(currentLocale, theme),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: List.generate(userTypes.length, (index) {
                          final type = userTypes[index];
                          final isSelected = _selectedUserType == type['id'];

                          final animation = CurvedAnimation(
                            parent: _staggerController,
                            curve: Interval(
                              (index * 0.08).clamp(0.0, 0.4),
                              (index * 0.08 + 0.6).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - animation.value)),
                                  child: Opacity(
                                    opacity: animation.value.clamp(0.0, 1.0),
                                    child: _UserTypeCard(
                                      type: type,
                                      isSelected: isSelected,
                                      theme: theme,
                                      onTap: () {
                                        HapticUtil.light();
                                        setState(() {
                                          _selectedUserType = type['id'];
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                child: _buildContinueButton(currentLocale, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMeshBackground(ThemeData theme) {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        final t = _blobController.value * 2 * math.pi;

        final blob1X = 35 * math.cos(t);
        final blob1Y = 25 * math.sin(t);

        final blob2X = 40 * math.sin(2 * t);
        final blob2Y = 30 * math.cos(t);

        final blob3X = 45 * math.sin(t);
        final blob3Y = 20 * math.sin(t + math.pi / 4);

        return Stack(
          children: [
            Container(color: const Color(0xFFF6F9F6)),
            Positioned(
              top: -80 + blob1Y,
              right: -60 + blob1X,
              child: _BlurredBlob(
                size: 340,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -40 + blob2Y,
              left: -80 + blob2X,
              child: _BlurredBlob(
                size: 380,
                color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35 + blob3Y,
              right: -100 + blob3X,
              child: _BlurredBlob(
                size: 300,
                color: const Color(0xFF00BFA5).withValues(alpha: 0.07),
              ),
            ),
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

  Widget _buildHeader(String currentLocale, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getString('selectUserType', currentLocale),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getString('subtitle', currentLocale),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(String currentLocale, ThemeData theme) {
    final bool isSelected = _selectedUserType != null;
    final buttonColors = _getSelectedGradient();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isSelected ? 1.0 : 0.65,
      child: _ShimmeringActionButton(
        text: _getString('continue', currentLocale).toUpperCase(),
        theme: theme,
        colors: buttonColors,
        onPressed: () async {
          if (_selectedUserType == null) {
            HapticUtil.medium();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getString('selectUserTypeError', currentLocale),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.all(20),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }

          HapticUtil.medium();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selected_user_type', _selectedUserType!);

          if (!mounted) return;
          if (_selectedUserType == 'farmer') {
            Navigator.of(context).pushReplacementNamed('/farmer-redirect');
          } else {
            Navigator.of(context).pushReplacementNamed('/phone-verify');
          }
        },
      ),
    );
  }
}

class _UserTypeCard extends StatefulWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _UserTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_UserTypeCard> createState() => _UserTypeCardState();
}

class _UserTypeCardState extends State<_UserTypeCard>
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
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    final Color cardBg = widget.isSelected
        ? Colors.white.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: widget.isSelected ? null : cardBg,
              borderRadius: BorderRadius.circular(20),
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: type['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: widget.isSelected
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: (type['gradient'][0] as Color).withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            padding: widget.isSelected
                ? const EdgeInsets.all(1.8)
                : EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: type['gradient'],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (type['gradient'][0] as Color)
                                    .withValues(alpha: 0.3),
                                blurRadius: widget.isSelected ? 10 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              type['icon'],
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                type['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: widget.isSelected
                                      ? (type['gradient'][0] as Color)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                type['desc'],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          widget.isSelected
                              ? Icons.check_circle_rounded
                              : CupertinoIcons.chevron_right,
                          size: 22,
                          color: widget.isSelected
                              ? type['gradient'][0]
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
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
  final List<Color> colors;

  const _ShimmeringActionButton({
    required this.onPressed,
    required this.text,
    required this.theme,
    required this.colors,
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
                    widget.colors[0],
                    widget.colors[1],
                    widget.colors[0],
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors[0].withValues(alpha: 0.35),
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
