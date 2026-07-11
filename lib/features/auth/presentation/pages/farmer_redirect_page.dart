import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FarmerRedirectPage extends StatefulWidget {
  const FarmerRedirectPage({super.key});

  @override
  State<FarmerRedirectPage> createState() => _FarmerRedirectPageState();
}

class _FarmerRedirectPageState extends State<FarmerRedirectPage>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _blobController;

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'title': 'Krishi Bhandar',
      'notice': 'Notice for Farmers',
      'desc':
          'This app is specifically designed for Retailers, Wholesalers, and Distributors to place bulk orders.\n\nFor personal cultivation, purchasing premium organic inputs, and direct delivery, please download our official Krishi Bhandar app.',
      'download': 'DOWNLOAD FARMER APP',
      'whatsapp': 'TALK ON WHATSAPP',
      'changeType': 'Change User Type',
    },
    'hi': {
      'title': 'किसान सेवा केंद्र',
      'notice': 'किसानों के लिए आवश्यक सूचना',
      'desc':
          'यह ऐप विशेष रूप से रिटेलर्स, थोक विक्रेताओं और डिस्ट्रीब्यूटर्स के लिए थोक ऑर्डर करने के लिए डिज़ाइन किया गया है।\n\nव्यक्तिगत खेती, प्रीमियम जैविक इनपुट खरीदने और सीधे होम डिलीवरी के लिए, कृपया हमारा आधिकारिक किसान सेवा केंद्र ऐप डाउनलोड करें।',
      'download': 'किसान ऐप डाउनलोड करें',
      'whatsapp': 'व्हाट्सएप पर बात करें',
      'changeType': 'यूज़र प्रकार बदलें',
    },
    'ta': {
      'title': 'கிசான் சேவா கேந்திரா',
      'notice': 'விவசாயிகளுக்கான முக்கிய அறிவிப்பு',
      'desc':
          'இந்தச் செயலி சில்லறை விற்பனையாளர்கள், மொத்த விற்பனையாளர்கள் மற்றும் விநியோகஸ்தர்கள் மொத்தமாக ஆர்டர் செய்வதற்காக வடிவமைக்கப்பட்டுள்ளது.\n\nதனிப்பட்ட விவசாயம், பிரீமியம் இயற்கை உள்ளீடுகளை வாங்குதல் மற்றும் நேரடி விநியோகத்திற்கு, தயவுசெய்து எங்களது கிசான் சேவா கேந்திரா செயலியைப் பதிவிறக்கவும்.',
      'download': 'விவசாயி செயலியைப் பதிவிறக்கவும்',
      'whatsapp': 'வாட்ஸ்அப்பில் பேசவும்',
      'changeType': 'பயனர் வகையை மாற்றவும்',
    },
    'te': {
      'title': 'కిసాన్ సేవా కేంద్ర',
      'notice': 'రైతు సోదరులకు ముఖ్య గమనిక',
      'desc':
          'ఈ యాప్ రిటైలర్లు, హోల్‌సేలర్లు మరియు డిస్ట్రిబ్యూటర్లు బల్క్ ఆర్డర్లు చేయడానికి ప్రత్యేకంగా రూపొందించబడింది.\n\nవ్యక్తిగత సాగు కోసం, ప్రీమియం సేంద్రీయ ఇన్‌పుట్‌లను కొనుగోలు చేయడానికి మరియు ప్రత్యక్ష డెలివరీ కోసం, దయచేసి మా అధికారిక కిసాన్ సేవా కేంద్ర యాప్‌ను డౌన్‌లోడ్ చేయండి.',
      'download': 'రైతు యాప్‌ను డౌన్‌లోడ్ చేయండి',
      'whatsapp': 'వాట్సాప్‌లో మాట్లాడండి',
      'changeType': 'యూజర్ రకాన్ని మార్చండి',
    },
    'mr': {
      'title': 'किसान सेवा केंद्र',
      'notice': 'शेतकऱ्यांसाठी महत्त्वाची सूचना',
      'desc':
          'हे ॲप विशेषतः रिटेलर्स, घाऊक व्यापारी आणि वितरकांसाठी मोठ्या प्रमाणात आदेश देण्यासाठी डिझाइन केले आहे.\n\nवैयक्तिक शेतीसाठी, प्रीमियम सेंद्रिय उत्पादने खरेदी करण्यासाठी आणि थेट डिलिव्हरी मिळवण्यासाठी, कृपया आमचे अधिकृत किसान सेवा केंद्र ॲप डाउनलोड करा।',
      'download': 'शेतकरी ॲप डाउनलोड करा',
      'whatsapp': 'व्हाट्सॲपवर संपर्क साधा',
      'changeType': 'वापरकर्ता प्रकार बदला',
    },
    'kn': {
      'title': 'ಕಿಸಾನ್ ಸೇವಾ ಕೇಂದ್ರ',
      'notice': 'ರೈತರಿಗಾಗಿ ಪ್ರಮುಖ ಪ್ರಕಟಣೆ',
      'desc':
          'ಈ ಅಪ್ಲಿಕೇಶನ್ ವಿಶೇಷವಾಗಿ ಚಿಲ್ಲರೆ ವ್ಯಾಪಾರಿಗಳು, ಸಗಟು ವ್ಯಾಪಾರಿಗಳು ಮತ್ತು ವಿತರಕರು ಬೃಹತ್ ಆರ್ಡರ್‌ಗಳನ್ನು ಮಾಡಲು ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ.\n\nವೈಯಕ್ತಿಕ ಕೃಷಿ, ಪ್ರೀಮಿಯಂ ಸಾವಯವ ಪರಿಕರಗಳ ಖರೀದಿ ಮತ್ತು ನೇರ ವಿತರಣೆಗಾಗಿ, ದಯವಿಟ್ಟು ನಮ್ಮ ಅಧಿಕೃತ ಕಿಸಾನ್ ಸೇವಾ ಕೇಂದ್ರ ಅಪ್ಲಿಕೇಶನ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ.',
      'download': 'ರೈತ ಅಪ್ಲಿಕೇಶನ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ',
      'whatsapp': 'ವಾಟ್ಸಾಪ್‌ನಲ್ಲಿ ಮಾತನಾಡಿ',
      'changeType': 'ಬಳಕೆದಾರರ ಪ್ರಕಾರವನ್ನು ಬದಲಾಯಿಸಿ',
    },
  };

  String _getString(String key, String localeCode) {
    final Map<String, String> langMap =
        _localizedStrings[localeCode] ?? _localizedStrings['en']!;
    return langMap[key] ?? _localizedStrings['en']![key] ?? '';
  }

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

  Future<void> launchPlayStore() async {
    HapticUtil.medium();
    MetaAnalyticsService.logContactSupport(
      contactMethod: 'Farmer Play Store Redirect',
    );
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.snss.ebs.kisan_sewa_kendra&hl=en_IN',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchWhatsApp() async {
    HapticUtil.medium();
    MetaAnalyticsService.logContactSupport(
      contactMethod: 'Farmer WhatsApp Redirect',
    );
    final url = Uri.parse('https://wa.me/919399022060');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLocale = languageService.locale.languageCode;
    final theme = Theme.of(context);

    final animation1 = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    final animation2 = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9F6),
        body: Stack(
          children: [
            _buildAnimatedMeshBackground(theme),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnimatedBuilder(
                          animation: _staggerController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: animation1.value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 50 * (1 - animation1.value)),
                                child: _buildRedirectCard(currentLocale, theme),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return Opacity(
                    opacity: animation2.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - animation2.value)),
                      child: _buildBackButton(currentLocale, theme),
                    ),
                  );
                },
              ),
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

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _TopIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () async {
              HapticUtil.light();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('selected_user_type');
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/choose-user-type');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRedirectCard(String currentLocale, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Agriculture Logo / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  _getString('notice', currentLocale),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  _getString('desc', currentLocale),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // Play Store Button (Commented out for App Store approval)
                // PlayStoreButton(onTap: launchPlayStore),
                // const SizedBox(height: 12),
                // WhatsApp Button
                _WhatsAppButton(
                  text: _getString('whatsapp', currentLocale),
                  onTap: _launchWhatsApp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(String currentLocale, ThemeData theme) {
    return TextButton(
      onPressed: () async {
        HapticUtil.light();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_user_type');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/choose-user-type');
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.arrow_left, size: 16),
          const SizedBox(width: 8),
          Text(
            _getString('changeType', currentLocale),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
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

class PlayStoreButton extends StatefulWidget {
  final VoidCallback onTap;

  const PlayStoreButton({required this.onTap});

  @override
  State<PlayStoreButton> createState() => _PlayStoreButtonState();
}

class _PlayStoreButtonState extends State<PlayStoreButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String playStoreSvg = '''
<svg width="540" height="156" viewBox="0 0 540 156" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M520 156H20C9.005 156 0 147.22 0 136.5V19.5C0 8.77987 9.005 0 20 0H520C530.995 0 540 8.77987 540 19.5V136.5C540 147.22 530.995 156 520 156Z" fill="black"/>
<path d="M520 3.12487C529.26 3.12487 536.795 10.4715 536.795 19.5V136.5C536.795 145.528 529.26 152.875 520 152.875H20C10.74 152.875 3.205 145.528 3.205 136.5V19.5C3.205 10.4715 10.74 3.12487 20 3.12487H520ZM520 0H20C9.005 0 0 8.77987 0 19.5V136.5C0 147.22 9.005 156 20 156H520C530.995 156 540 147.22 540 136.5V19.5C540 8.77987 530.995 0 520 0Z" fill="#A6A6A6"/>
<path d="M41.74 29.4011C40.565 30.6003 39.885 32.4674 39.885 34.8854V121.134C39.885 123.552 40.565 125.419 41.74 126.618L42.03 126.882L91.6 78.5703V77.4296L42.03 29.1183L41.74 29.4011Z" fill="url(#paint0_linear_1902_252)"/>
<path d="M108.105 94.6822L91.5999 78.5703V77.4295L108.125 61.3177L108.495 61.5273L128.065 72.3839C133.65 75.4649 133.65 80.5349 128.065 83.6354L108.495 94.4725L108.105 94.6822V94.6822Z" fill="url(#paint1_linear_1902_252)"/>
<path d="M108.495 94.4726L91.6 78L41.74 126.618C43.595 128.52 46.62 128.749 50.06 126.847L108.495 94.4726" fill="url(#paint2_linear_1902_252)"/>
<path d="M108.495 61.5274L50.06 29.1525C46.62 27.2707 43.595 27.4999 41.74 29.4011L91.6 78L108.495 61.5274Z" fill="url(#paint3_linear_1902_252)"/>
<path d="M189.67 39.9506C189.67 43.2071 188.67 45.8153 186.7 47.7604C184.435 50.0663 181.485 51.2265 177.87 51.2265C174.415 51.2265 171.465 50.0468 169.045 47.7214C166.62 45.3619 165.41 42.4661 165.41 39C165.41 35.5339 166.62 32.6381 169.045 30.2981C171.465 27.9533 174.415 26.7735 177.87 26.7735C179.59 26.7735 181.23 27.1196 182.795 27.7631C184.355 28.4115 185.625 29.289 186.545 30.3713L184.455 32.4285C182.85 30.5809 180.665 29.6693 177.87 29.6693C175.35 29.6693 173.165 30.5273 171.31 32.2579C169.475 33.9934 168.555 36.2408 168.555 39C168.555 41.7593 169.475 44.0261 171.31 45.7616C173.165 47.4728 175.35 48.3503 177.87 48.3503C180.545 48.3503 182.795 47.4728 184.57 45.7421C185.74 44.5965 186.405 43.017 186.58 40.9988H177.87V38.181H189.49C189.63 38.7904 189.67 39.3803 189.67 39.9506V39.9506Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M208.105 30.1811H197.19V37.5911H207.03V40.4089H197.19V47.8189H208.105V50.6902H194.1V27.3097H208.105V30.1811Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M221.115 50.6902H218.025V30.1811H211.33V27.3097H227.815V30.1811H221.115V50.6902V50.6902Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M239.745 50.6902V27.3097H242.83V50.6902H239.745Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M256.505 50.6902H253.44V30.1811H246.72V27.3097H263.225V30.1811H256.505V50.6902Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M294.435 47.6824C292.07 50.0468 289.14 51.2265 285.645 51.2265C282.13 51.2265 279.2 50.0468 276.835 47.6824C274.475 45.3229 273.3 42.4271 273.3 39C273.3 35.5729 274.475 32.6771 276.835 30.3176C279.2 27.9533 282.13 26.7735 285.645 26.7735C289.12 26.7735 292.05 27.9533 294.415 30.3371C296.795 32.7161 297.97 35.5924 297.97 39C297.97 42.4271 296.795 45.3229 294.435 47.6824ZM279.12 45.7226C280.9 47.4728 283.065 48.3503 285.645 48.3503C288.205 48.3503 290.39 47.4728 292.15 45.7226C293.925 43.9725 294.825 41.7251 294.825 39C294.825 36.2749 293.925 34.0275 292.15 32.2774C290.39 30.5273 288.205 29.6498 285.645 29.6498C283.065 29.6498 280.9 30.5273 279.12 32.2774C277.345 34.0275 276.445 36.2749 276.445 39C276.445 41.7251 277.345 43.9725 279.12 45.7226V45.7226Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M302.305 50.6902V27.3097H306.055L317.715 45.4935H317.85L317.715 40.9987V27.3097H320.8V50.6902H317.58L305.37 31.6095H305.235L305.37 36.1237V50.6902H302.305V50.6902Z" fill="white" stroke="white" stroke-width="0.16" stroke-miterlimit="10"/>
<path d="M272.54 84.8348C263.145 84.8348 255.47 91.8061 255.47 101.424C255.47 110.965 263.145 118.009 272.54 118.009C281.955 118.009 289.63 110.965 289.63 101.424C289.63 91.8061 281.955 84.8348 272.54 84.8348ZM272.54 111.477C267.385 111.477 262.95 107.328 262.95 101.424C262.95 95.4428 267.385 91.3673 272.54 91.3673C277.695 91.3673 282.15 95.4428 282.15 101.424C282.15 107.328 277.695 111.477 272.54 111.477V111.477ZM235.295 84.8348C225.88 84.8348 218.225 91.8061 218.225 101.424C218.225 110.965 225.88 118.009 235.295 118.009C244.705 118.009 252.365 110.965 252.365 101.424C252.365 91.8061 244.705 84.8348 235.295 84.8348ZM235.295 111.477C230.135 111.477 225.685 107.328 225.685 101.424C225.685 95.4428 230.135 91.3673 235.295 91.3673C240.45 91.3673 244.885 95.4428 244.885 101.424C244.885 107.328 240.45 111.477 235.295 111.477ZM190.975 89.9194V96.9687H208.24C207.735 100.908 206.385 103.803 204.315 105.822C201.795 108.259 197.87 110.965 190.975 110.965C180.35 110.965 172.03 102.604 172.03 92.2448C172.03 81.8854 180.35 73.5248 190.975 73.5248C196.72 73.5248 200.9 75.7137 203.985 78.5509L209.08 73.5833C204.765 69.5663 199.025 66.4804 190.975 66.4804C176.405 66.4804 164.16 78.0391 164.16 92.2448C164.16 106.451 176.405 118.009 190.975 118.009C198.85 118.009 204.765 115.494 209.415 110.775C214.18 106.129 215.665 99.5963 215.665 94.3216C215.665 92.6836 215.525 91.1772 215.275 89.9194H190.975ZM372.205 95.3843C370.8 91.6744 366.465 84.8348 357.635 84.8348C348.885 84.8348 341.6 91.5574 341.6 101.424C341.6 110.716 348.81 118.009 358.475 118.009C366.29 118.009 370.8 113.363 372.655 110.658L366.855 106.889C364.92 109.649 362.285 111.477 358.475 111.477C354.69 111.477 351.975 109.785 350.235 106.451L372.99 97.2709L372.205 95.3843V95.3843ZM349.005 100.908C348.81 94.5117 354.1 91.2357 357.89 91.2357C360.86 91.2357 363.38 92.6836 364.22 94.7554L349.005 100.908V100.908ZM330.51 117H337.99V68.2501H330.51V117ZM318.26 88.5301H318.01C316.33 86.5898 313.125 84.8348 309.065 84.8348C300.545 84.8348 292.755 92.1278 292.755 101.478C292.755 110.775 300.545 118.009 309.065 118.009C313.125 118.009 316.33 116.24 318.01 114.241H318.26V116.62C318.26 122.962 314.785 126.37 309.18 126.37C304.61 126.37 301.775 123.152 300.605 120.447L294.1 123.094C295.975 127.491 300.94 132.902 309.18 132.902C317.95 132.902 325.35 127.871 325.35 115.63V85.8439H318.26V88.5301V88.5301ZM309.705 111.477C304.55 111.477 300.235 107.27 300.235 101.478C300.235 95.6329 304.55 91.3673 309.705 91.3673C314.785 91.3673 318.79 95.6329 318.79 101.478C318.79 107.27 314.785 111.477 309.705 111.477V111.477ZM407.225 68.2501H389.335V117H396.795V98.5287H407.225C415.51 98.5287 423.635 92.6836 423.635 83.3869C423.635 74.0952 415.49 68.2501 407.225 68.2501V68.2501ZM407.42 91.7476H396.795V75.0312H407.42C412.99 75.0312 416.17 79.5406 416.17 83.3869C416.17 87.1602 412.99 91.7476 407.42 91.7476ZM453.535 84.7422C448.145 84.7422 442.54 87.0627 440.235 92.2058L446.855 94.9114C448.28 92.2058 450.9 91.3283 453.67 91.3283C457.54 91.3283 461.465 93.5952 461.525 97.5976V98.1094C460.175 97.3489 457.285 96.2228 453.73 96.2228C446.6 96.2228 439.335 100.05 439.335 107.192C439.335 113.724 445.175 117.931 451.74 117.931C456.76 117.931 459.53 115.723 461.27 113.154H461.525V116.922H468.73V98.2216C468.73 89.5782 462.11 84.7422 453.535 84.7422ZM452.635 111.457C450.195 111.457 446.795 110.277 446.795 107.328C446.795 103.555 451.035 102.107 454.705 102.107C457.99 102.107 459.53 102.814 461.525 103.745C460.94 108.259 456.955 111.457 452.635 111.457V111.457ZM494.98 85.8098L486.405 106.943H486.15L477.285 85.8098H469.24L482.56 115.343L474.96 131.776H482.755L503.28 85.8098H494.98V85.8098ZM427.735 117H435.215V68.2501H427.735V117Z" fill="white"/>
<defs>
<linearGradient id="paint0_linear_1902_252" x1="87.1988" y1="122.032" x2="21.7684" y2="54.9241" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#00A0FF"/>
<stop offset="0.0066" stop-color="#00A1FF"/>
<stop offset="0.2601" stop-color="#00BEFF"/>
<stop offset="0.5122" stop-color="#00D2FF"/>
<stop offset="0.7604" stop-color="#00DFFF"/>
<stop offset="1" stop-color="#00E3FF"/>
</linearGradient>
<linearGradient id="paint1_linear_1902_252" x1="135.337" y1="77.9945" x2="38.5499" y2="77.9945" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FFE000"/>
<stop offset="0.4087" stop-color="#FFBD00"/>
<stop offset="0.7754" stop-color="#FFA500"/>
<stop offset="1" stop-color="#FF9C00"/>
</linearGradient>
<linearGradient id="paint2_linear_1902_252" x1="99.308" y1="69.0452" x2="10.5791" y2="-21.9588" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FF3A44"/>
<stop offset="1" stop-color="#C31162"/>
</linearGradient>
<linearGradient id="paint3_linear_1902_252" x1="29.1892" y1="155.313" x2="68.8106" y2="114.676" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#32A071"/>
<stop offset="0.0685" stop-color="#2DA771"/>
<stop offset="0.4762" stop-color="#15CF74"/>
<stop offset="0.8009" stop-color="#06E775"/>
<stop offset="1" stop-color="#00F076"/>
</linearGradient>
</defs>
</svg>
''';

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _animation,
        child: SvgPicture.string(
          playStoreSvg,
          width: double.infinity,
          height: 48, // Reduced even more to match visual height
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const _WhatsAppButton({required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height:
            54, // Keep it slightly taller than the SVG height to look "same"
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/whatsapp.png', width: 28, height: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmeringActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final ThemeData theme;
  final IconData icon;
  final List<Color> colors;

  const _ShimmeringActionButton({
    required this.onPressed,
    required this.text,
    required this.theme,
    required this.icon,
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
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
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
