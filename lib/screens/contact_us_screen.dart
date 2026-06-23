import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _messageController = TextEditingController();
  int _selectedTopicIndex = 0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Helper method for local translations of FAQs and office card elements
  String _translate({
    required String en,
    String? hi,
    String? mr,
    String? ta,
    String? te,
    String? kn,
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'hi':
        return hi ?? en;
      case 'mr':
        return mr ?? en;
      case 'ta':
        return ta ?? en;
      case 'te':
        return te ?? en;
      case 'kn':
        return kn ?? en;
      default:
        return en;
    }
  }

  // Copy text to clipboard with custom message and haptic feedback
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    final snackBarLabel = _translate(
      en: "$label copied to clipboard",
      hi: "$label क्लिपबोर्ड पर कॉपी किया गया",
      mr: "$label क्लिपबोर्डवर कॉपी केले",
      ta: "$label கிளிப்போர்டில் நகலெடுக்கப்பட்டது",
      te: "$label క్లిప్‌బోర్డ్‌కు కాపీ చేయబడింది",
      kn: "$label ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲಾಗಿದೆ",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                snackBarLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Support is online Mon-Sat, 9:00 AM to 7:00 PM
  bool _isSupportOnline() {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) return false;
    final hour = now.hour;
    return hour >= 9 && hour < 19;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    HapticFeedback.lightImpact();
    MetaAnalyticsService.logContactSupport(contactMethod: 'Phone Call');
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(launchUri, mode: LaunchMode.platformDefault)) {
          await _copyToClipboard(
            phoneNumber,
            _translate(
              en: "Phone number",
              hi: "फ़ोन नंबर",
              mr: "फोन नंबर",
              ta: "தொலைபேசி எண்",
              te: "ఫోన్ నంబర్",
              kn: "ಫೋನ್ ಸಂಖ್ಯೆ",
            ),
          );
        }
      }
    } catch (e) {
      await _copyToClipboard(
        phoneNumber,
        _translate(
          en: "Phone number",
          hi: "फ़ोन नंबर",
          mr: "फोन नंबर",
          ta: "தொலைபேசி எண்",
          te: "ఫోన్ నంబర్",
          kn: "ಫೋನ್ ಸಂಖ್ಯೆ",
        ),
      );
    }
  }

  Future<void> _sendEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    HapticFeedback.lightImpact();
    MetaAnalyticsService.logContactSupport(contactMethod: 'Email');
    final Map<String, String> queryParams = {};
    if (subject != null) queryParams['subject'] = subject;
    if (body != null) queryParams['body'] = body;

    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await _copyToClipboard(
          email,
          _translate(
            en: "Email address",
            hi: "ईमेल पता",
            mr: "ईमेल पत्ता",
            ta: "மின்னஞ்சல் முகவரி",
            te: "ఈమెయిల్ చిరునామా",
            kn: "ಇಮೇಲ್ ವಿಳಾಸ",
          ),
        );
      }
    } catch (e) {
      await _copyToClipboard(
        email,
        _translate(
          en: "Email address",
          hi: "ईमेल पता",
          mr: "ईमेल पत्ता",
          ta: "மின்னஞ்சல் முகவரி",
          te: "ఈమెయిల్ చిరునామా",
          kn: "ಇಮೇಲ್ ವಿಳಾಸ",
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    HapticFeedback.lightImpact();
    MetaAnalyticsService.logContactSupport(contactMethod: 'WhatsApp');
    final url =
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
    final Uri launchUri = Uri.parse(url);
    try {
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(launchUri, mode: LaunchMode.platformDefault)) {
          await _copyToClipboard(
            phoneNumber,
            _translate(
              en: "WhatsApp number",
              hi: "व्हाट्सएप नंबर",
              mr: "व्हॉट्सॲप नंबर",
              ta: "வாட்ஸ்அப் எண்",
              te: "వాట్సాప్ నంబర్",
              kn: "ವಾಟ್ಸಾಪ್ ಸಂಖ್ಯೆ",
            ),
          );
        }
      }
    } catch (e) {
      await _copyToClipboard(
        phoneNumber,
        _translate(
          en: "WhatsApp number",
          hi: "व्हाट्सएप नंबर",
          mr: "व्हॉट्सॲप नंबर",
          ta: "வாட்ஸ்அப் எண்",
          te: "వాట్సాప్ నంబర్",
          kn: "ವಾಟ್ಸಾಪ್ ಸಂಖ್ಯೆ",
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleSubmit(bool useWhatsApp) {
    final l10n = AppLocalizations.of(context)!;
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      _showErrorSnackBar(l10n.fieldRequired);
      return;
    }

    final topics = [
      l10n.topicOrderIssue,
      l10n.topicRefundPayment,
      l10n.topicBecomeDealer,
      l10n.topicProductQuery,
      l10n.topicKycHelp,
    ];
    final selectedTopic = topics[_selectedTopicIndex];

    final formattedMessage =
        "Hello Krishi Kranti Support,\n\n"
        "I have a query regarding: *$selectedTopic*\n\n"
        "Details:\n$messageText";

    if (useWhatsApp) {
      _sendWhatsAppMessage(
        phoneNumber: '919399022060',
        message: formattedMessage,
      );
    } else {
      _sendEmail(
        email: 'info@krishikrantiorganics.com',
        subject: 'Krishi Kranti Support - $selectedTopic',
        body: formattedMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isOnline = _isSupportOnline();
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    final topics = [
      l10n.topicOrderIssue,
      l10n.topicRefundPayment,
      l10n.topicBecomeDealer,
      l10n.topicProductQuery,
      l10n.topicKycHelp,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// PREMIUM DYNAMIC GRADIENT HEADER
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: size.height * 0.24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.85),
                        const Color(0xFF114216),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SupportScaleBtn(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Text(
                                l10n.contactUs,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 36), // Balanced spacing
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.letsConnect,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.supportSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating glassmorphism circle shapes for premium styling
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 40,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                /// DYNAMIC SUPPORT HOURS CARD (OVERLAYING THE HEADER)
                Positioned(
                  bottom: -24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _PulsingDot(
                              color: isOnline ? Colors.green : Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isOnline
                                      ? l10n.onlineSupportActive
                                      : l10n.offlineResponseDelayed,
                                  style: TextStyle(
                                    color: isOnline
                                        ? Colors.green.shade800
                                        : Colors.amber.shade800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  l10n.supportHours,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: primaryColor,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                l10n.fastResponse,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 44),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// GRID OF BRAND COMMUNICATION CARDS (COMPACT & MODERN)
                  Row(
                    children: [
                      // WhatsApp Card
                      Expanded(
                        child: _SupportScaleBtn(
                          onTap: () => _sendWhatsAppMessage(
                            phoneNumber: '919399022060',
                            message:
                                "Hello Krishi Kranti Support, I need help with...",
                          ),
                          onLongPress: () => _copyToClipboard(
                            '+919399022060',
                            _translate(
                              en: "WhatsApp number",
                              hi: "व्हाट्सएप नंबर",
                              mr: "व्हॉट्सॲप नंबर",
                              ta: "வாட்ஸ்அப் எண்",
                              te: "వాట్సాప్ నంబర్",
                              kn: "ವಾಟ್ಸಾಪ್ ಸಂಖ್ಯೆ",
                            ),
                          ),
                          child: _buildCommCard(
                            title: l10n.whatsapp,
                            subtitle: l10n.quickChat,
                            icon: CupertinoIcons.chat_bubble_2_fill,
                            iconColor: const Color(0xFF25D366),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Call Card
                      Expanded(
                        child: _SupportScaleBtn(
                          onTap: () => _makePhoneCall('+919399022060'),
                          onLongPress: () => _copyToClipboard(
                            '+919399022060',
                            _translate(
                              en: "Phone number",
                              hi: "फ़ोन नंबर",
                              mr: "फोन नंबर",
                              ta: "தொலைபேசி எண்",
                              te: "ఫోన్ నంబర్",
                              kn: "ಫೋನ್ ಸಂಖ್ಯೆ",
                            ),
                          ),
                          child: _buildCommCard(
                            title: l10n.callUs,
                            subtitle: l10n.directLine,
                            icon: CupertinoIcons.phone_fill,
                            iconColor: const Color(0xFF1976D2),
                            bgColor: const Color(0xFFE3F2FD),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Email Card
                      Expanded(
                        child: _SupportScaleBtn(
                          onTap: () => _sendEmail(
                            email: 'info@krishikrantiorganics.com',
                          ),
                          onLongPress: () => _copyToClipboard(
                            'info@krishikrantiorganics.com',
                            _translate(
                              en: "Email address",
                              hi: "ईमेल पता",
                              mr: "ईमेल पत्ता",
                              ta: "மின்னஞ்சல் முகவரி",
                              te: "ఈమెయిల్ చిరునామా",
                              kn: "ಇಮೇಲ್ ವಿಳಾಸ",
                            ),
                          ),
                          child: _buildCommCard(
                            title: l10n.emailLabel,
                            subtitle: l10n.officialMail,
                            icon: CupertinoIcons.mail_solid,
                            iconColor: const Color(0xFFFFA000),
                            bgColor: const Color(0xFFFFF8E1),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// INTERACTIVE MESSAGE COMPOSER FORM (ROBUST & CREATIVE)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.03),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sendQuickInquiry,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D2D),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Select Query Tag Chips
                        Text(
                          l10n.selectTopic,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // WRAPPING TOPICS TO NEVER CUT OFF
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(topics.length, (index) {
                            final topic = topics[index];
                            final isSelected = _selectedTopicIndex == index;
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedTopicIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  topic,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),

                        // Message Text Field header row with custom counter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.messageDetails,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              "${_messageController.text.length} / 500",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _messageController.text.length >= 500
                                    ? Colors.red
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          maxLength: 500,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            counterText: "", // Hide default counter
                            hintText: _translate(
                              en: "Describe your issue, order question, or dealer interest...",
                              hi: "अपनी समस्या, ऑर्डर प्रश्न या डीलर रुचि का वर्णन करें...",
                              mr: "तुमच्या समस्येचे, ऑर्डरच्या प्रश्नाचे किंवा डीलरच्या आवडीचे वर्णन करा...",
                              ta: "உங்கள் சிக்கல், ஆர்டர் கேள்வி அல்லது டீலர் ஆர்வத்தை விவரிக்கவும்...",
                              te: "మీ సమస్య, ఆర్డర్ ప్రశ్న లేదా డీలర్ ఆసక్తిని వివరించండి...",
                              kn: "ನಿಮ್ಮ ಸಮಸ್ಯೆ, ಆರ್ಡರ್ ಪ್ರಶ್ನೆ ಅಥವಾ ಡೀಲರ್ ಆಸಕ್ತಿಯನ್ನು ವಿವರಿಸಿ...",
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Send Button Row (WhatsApp as primary, Email as secondary)
                        Row(
                          children: [
                            // Primary WhatsApp Button
                            Expanded(
                              flex: 2,
                              child: _SupportScaleBtn(
                                onTap: () => _handleSubmit(true),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF25D366),
                                        Color(0xFF1EBE5D),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF25D366,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.chat_bubble_2_fill,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.sendWhatsApp,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Secondary Email Button
                            _SupportScaleBtn(
                              onTap: () => _handleSubmit(false),
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.mail_solid,
                                  color: Colors.grey.shade700,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Collapsible FAQ Accordion Section
                  // _buildFaqSection(),

                  // const SizedBox(height: 28),

                  /// Registered Office Location Address Card
                  // _buildOfficeCard(theme),

                  // const SizedBox(height: 32),

                  /// TRUST BADGE GRID (MODERN & STUNNING)
                  // Text(
                  //   l10n.whyTrustKrishiKranti,
                  //   style: const TextStyle(
                  //     fontSize: 15,
                  //     fontWeight: FontWeight.bold,
                  //     color: Color(0xFF2D2D2D),
                  //   ),
                  // ),
                  // const SizedBox(height: 14),
                  // GridView.count(
                  //   crossAxisCount: 2,
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   mainAxisSpacing: 10,
                  //   crossAxisSpacing: 10,
                  //   childAspectRatio: 2.8,
                  //   children: [
                  //     _buildTrustBadge(
                  //       icon: CupertinoIcons.lock_shield_fill,
                  //       label: l10n.dataPrivate,
                  //       bgColor: const Color(0xFFE8F5E9),
                  //       iconColor: primaryColor,
                  //     ),
                  //     _buildTrustBadge(
                  //       icon: CupertinoIcons.checkmark_seal_fill,
                  //       label: l10n.cibrcRegd,
                  //       bgColor: const Color(0xFFE8F5E9),
                  //       iconColor: primaryColor,
                  //     ),
                  //     _buildTrustBadge(
                  //       icon: CupertinoIcons.doc_text_fill,
                  //       label: l10n.gstInvoice,
                  //       bgColor: const Color(0xFFE8F5E9),
                  //       iconColor: primaryColor,
                  //     ),
                  //     _buildTrustBadge(
                  //       icon: CupertinoIcons.bus,
                  //       label: l10n.panIndiaDelivery,
                  //       bgColor: const Color(0xFFE8F5E9),
                  //       iconColor: primaryColor,
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    final title = _translate(
      en: "Frequently Asked Questions",
      hi: "अक्सर पूछे जाने वाले प्रश्न",
      mr: "वारंवार विचारले जाणारे प्रश्न",
      ta: "அடிக்கடி கேட்கப்படும் கேள்விகள்",
      te: "తరచుగా అడిగే ప్రశ్నలు",
      kn: "ಪದೇ ಪದೇ ಕೇಳಲಾಗುವ ಪ್ರಶ್ನೆಗಳು",
    );

    final faqs = [
      {
        'q': _translate(
          en: "How do I register as a Verified Dealer?",
          hi: "मैं एक सत्यापित डीलर के रूप में कैसे पंजीकरण करूँ?",
          mr: "मी सत्यापित डीलर म्हणून नोंदणी कशी करू?",
          ta: "நான் எப்படி ஒரு சரிபார்க்கப்பட்ட டீலராக பதிவு செய்வது?",
          te: "నేను ధృవీకరించబడిన డీలర్‌గా ఎలా నమోదు చేసుకోవాలి?",
          kn: "ನಾನು ಪರಿಶೀಲಿಸಿದ ಡೀಲರ್ ಆಗಿ ನೋಂದಾಯಿಸುವುದು ಹೇಗೆ?",
        ),
        'a': _translate(
          en: "Go to the Profile section and upload your KYC documents (GSTIN, PAN, and Pesticide/Fertilizer License). Our team will verify it within 24 hours.",
          hi: "प्रोफ़ाइल अनुभाग में जाएं और अपने केवाईसी दस्तावेज (GSTIN, पैन और कीटनाशक/उर्वरक लाइसेंस) अपलोड करें। हमारी टीम 24 घंटे के भीतर इसका सत्यापन करेगी।",
          mr: "प्रोफाइल विभागात जा आणि तुमचे केवायसी दस्तऐवज (GSTIN, पॅन आणि कीटकनाशक/खत परवाना) अपलोड करा. आमची टीम २४ तासांच्या आत त्याची पडताळणी करेल.",
          ta: "சுயவிவரப் பகுதிக்குச் சென்று உங்கள் KYC ஆவணங்களைப் பதிவேற்றவும் (GSTIN, PAN மற்றும் பூச்சிக்கொல்லி/உர உரிமம்). எங்கள் குழு 24 மணி நேரத்திற்குள் அதைச் சரிபார்க்கும்.",
          te: "ప్రొఫైల్ విభాగానికి వెళ్లి మీ KYC పత్రాలను (GSTIN, PAN మరియు పురుగుల మందు/ఎరువుల లైసెన్స్) అప్‌లోడ్ చేయండి. మా బృందం 24 గంటల్లో ధృవీకరిస్తుంది.",
          kn: "ಪ್ರೊಫೈಲ್ ವಿಭಾಗಕ್ಕೆ ಹೋಗಿ ಮತ್ತು ನಿಮ್ಮ ಕೆವೈಸಿ ದಾಖಲೆಗಳನ್ನು (ಜಿಎಸ್‌ಟಿಐಎನ್, ಪ್ಯಾನ್ ಮತ್ತು ಕೀಟನಾಶಕ/ರಸಗೊಬ್ಬರ ಪರವಾನಗಿ) ಅಪ್‌ಲೋಡ್ ಮಾಡಿ. ನಮ್ಮ ತಂಡವು 24 ಗಂಟೆಗಳ ಒಳಗೆ ಅದನ್ನು ಪರಿಶೀಲಿಸುತ್ತದೆ.",
        ),
      },
      {
        'q': _translate(
          en: "What is the minimum order value (MOV) for bulk pricing?",
          hi: "थोक डीलर मूल्य निर्धारण के लिए न्यूनतम ऑर्डर मूल्य (MOV) क्या है?",
          mr: "घाऊक डीलर किंमतीसाठी किमान ऑर्डर मूल्य (MOV) काय आहे?",
          ta: "மொத்த டீலர் விலையிடலுக்கான குறைந்தபட்ச ஆர்டர் மதிப்பு (MOV) என்ன?",
          te: "బల్క్ డీలర్ ధరల కోసం కనీస ఆర్డర్ విలువ (MOV) ఎంత?",
          kn: "ಬಲ್ಕ್ ಡೀಲರ್ ಬೆಲೆಗೆ ಕನಿಷ್ಠ ಆರ್ಡರ್ ಮೌಲ್ಯ (MOV) ಎಷ್ಟು?",
        ),
        'a': _translate(
          en: "To unlock bulk dealer margins, a minimum order value of ₹10,000 is required per order.",
          hi: "थोक डीलर मार्जिन का लाभ उठाने के लिए, प्रति ऑर्डर न्यूनतम ₹10,000 का ऑर्डर मूल्य होना आवश्यक है।",
          mr: "घाऊक डीलर मार्जिन मिळवण्यासाठी, प्रति ऑर्डर किमान ₹१०,००० ऑर्डर मूल्य आवश्यक आहे.",
          ta: "மொத்த டீலர் மார்ஜின்களைப் பெற, ஒரு ஆர்டருக்கு குறைந்தபட்சம் ₹10,000 மதிப்பு தேவை.",
          te: "బల్క్ డీలర్ మార్జిన్‌లను పొందడానికి, ప్రతి ఆర్డర్‌కు కనీసం ₹10,000 ఆర్డర్ విలువ అవసరం.",
          kn: "ಬಲ್ಕ್ ಡೀಲರ್ ಮಾರ್ಜಿನ್‌ಗಳನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಲು, ಪ್ರತಿ ಆರ್ಡರ್ ಕನಿಷ್ಠ ₹10,000 ಆರ್ಡರ್ ಮೌಲ್ಯದ ಅಗತ್ಯವಿದೆ.",
        ),
      },
      {
        'q': _translate(
          en: "How are pesticide & fertilizer shipments delivered?",
          hi: "कीटनाशक और उर्वरक शिपमेंट कैसे वितरित किए जाते हैं?",
          mr: "कीटकनाशक आणि खतांची डिलिव्हरी कशी केली जाते?",
          ta: "பூச்சிக்கொல்லி மற்றும் உர ஏற்றுமதி எவ்வாறு விநியோகிக்கப்படுகிறது?",
          te: "పురుగుల మందు మరియు ఎరువుల రవాణా ఎలా డెలివరీ చేయబడుతుంది?",
          kn: "ಕೀಟನಾಶಕ ಮತ್ತು ರಸಗೊಬ್ಬರ ಸಾಗಣೆಗಳನ್ನು ಹೇಗೆ ತಲುಪಿಸಲಾಗುತ್ತದೆ?",
        ),
        'a': _translate(
          en: "We partner with leading B2B logistics providers (Shiprocket, V-Trans, etc.) to ensure safe, CIB&RC-compliant delivery directly to your shop.",
          hi: "हम सीधे आपकी दुकान पर सुरक्षित, CIB&RC-compliant डिलीवरी सुनिश्चित करने के लिए प्रमुख B2B लॉजिस्टिक्स प्रदाताओं (जैसे Shiprocket, V-Trans) के साथ साझेदारी करते हैं।",
          mr: "आम्ही तुमच्या दुकानात थेट सुरक्षित, CIB&RC-compliant डिलिव्हरी सुनिश्चित करण्यासाठी प्रमुख B2B लॉजिस्टिक कंपन्यांशी भागीदारी करतो.",
          ta: "உங்கள் கடைக்கே பாதுகாப்பான, CIB&RC இணக்கமான விநியோகத்தை உறுதிப்படுத்த முன்னனி B2B லாஜிஸ்டிக்ஸ் நிறுவனங்களுடன் நாங்கள் இணைந்துள்ளோம்.",
          te: "మీ దుకాణానికి నేరుగా సురక్షితమైన, CIB&RC-నిబంధనలకు అనుగుణంగా డెలివరీని నిర్ధారించడానికి మేము ప్రముఖ B2B లాజిస్టిక్స్ భాగస్వాములతో పని చేస్తాము.",
          kn: "ನಿಮ್ಮ ಅಂಗಡಿಗೆ ನೇರವಾಗಿ ಸುರಕ್ಷಿತ, CIB&RC-ಅನುಸರಣೆಯ ವಿತರಣೆಯನ್ನು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಲು ನಾವು ಪ್ರಮುಖ B2B ಲಾಜಿಸ್ಟಿಕ್ಸ್ ಕಂಪನಿಗಳೊಂದಿಗೆ ಪಾಲುದಾರಿಕೆ ಹೊಂದಿದ್ದೇವೆ.",
        ),
      },
      {
        'q': _translate(
          en: "Can I get a GST credit note/invoice for my orders?",
          hi: "क्या मुझे अपने ऑर्डर के लिए जीएसटी इनवॉइस मिल सकता है?",
          mr: "मला माझ्या ऑर्डरसाठी जीएसटी इनव्हॉइस मिळू शकते का?",
          ta: "எனது ஆர்டர்களுக்கு ஜிஎஸ்டி இன்வாய்ஸ் பெற முடியுமா?",
          te: "నా ఆర్డర్‌ల కోసం నేను జీఎస్టీ ఇన్వాయిస్ పొందవచ్చా?",
          kn: "ನನ್ನ ಆರ್ಡರ್‌ಗಳಿಗೆ ನಾನು ಜಿಎಸ್‌ಟಿ ಇನ್‌ವಾಯ್ಸ್ ಪಡೆಯಬಹುದೇ?",
        ),
        'a': _translate(
          en: "Yes! A valid GST invoice is automatically generated and emailed to you for every purchase to claim input tax credit (ITC).",
          hi: "हाँ! इनपुट टैक्स क्रेडिट (ITC) का दावा करने के लिए प्रत्येक खरीद के लिए एक वैध जीएसटी इनवॉइस स्वचालित रूप से जनरेट होकर आपको ईमेल की जाती है।",
          mr: "होय! इनपुट टॅक्स क्रेडिट (ITC) क्लेम करण्यासाठी प्रत्येक खरेदीसाठी वैध जीएसटी इनव्हॉइस स्वयंचलितपणे तयार केले जाते आणि तुम्हाला ईमेल केले जाते.",
          ta: "ஆம்! உள்ளீட்டு வரி கிரெடிட்டை (ITC) பெற ஒவ்வொரு கொள்முதலுக்கும் செல்லுபடியாகும் ஜிஎஸ்டி இன்வாய்ஸ் தானாகவே உருவாக்கப்பட்டு உங்களுக்கு மின்னஞ்சல் ಮಾಡப்படும்.",
          te: "అవును! ఇన్‌పుట్ టాక్స్ క్రెడిట్ (ITC) క్లెయిమ్ చేయడానికి ప్రతి కొనుగోలుకు చెల్లుబాటు అయ్యే జీఎస్టీ ఇన్వాయిస్ ఆటోమేటిక్‌గా జనరేట్ చేయబడి మీకు ఈమెయిల్ చేయబడుతుంది.",
          kn: "ಹೌದು! ಇನ್‌ಪುಟ್ ಟ್ಯಾಕ್ಸ್ ಕ್ರೆಡಿಟ್ (ITC) ಪಡೆಯಲು ಪ್ರತಿ ಖರೀದಿಗೆ ಮಾನ್ಯವಾದ ಜಿಎಸ್‌ಟಿ ಇನ್‌ವಾಯ್ಸ್ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ರಚನೆಯಾಗಿ ನಿಮಗೆ ಇಮೇಲ್ ಮಾಡಲಾಗುತ್ತದೆ.",
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
              letterSpacing: -0.4,
            ),
          ),
        ),
        ...faqs.map((faq) => _FaqTile(question: faq['q']!, answer: faq['a']!)),
      ],
    );
  }

  Widget _buildOfficeCard(ThemeData theme) {
    final title = _translate(
      en: "Registered Office Address",
      hi: "पंजीकृत कार्यालय का पता",
      mr: "नोंदणीकृत कार्यालयाचा पत्ता",
      ta: "பதிவு செய்யப்பட்ட அலுவலக முகவரி",
      te: "రిజిస్టర్డ్ ఆఫీస్ చిరునామా",
      kn: "ನೋಂದಾಯಿತ ಕಚೇರಿ ವಿಳಾಸ",
    );
    final address =
        "Krishikranti Organics Pvt. Ltd.\n"
        "Sector-C, Sanwer Road Industrial Area,\n"
        "Indore, Madhya Pradesh - 452015";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.location_solid,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            address,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SupportScaleBtn(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final Uri mapsUri = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=Krishikranti+Organics+Indore",
                    );
                    try {
                      if (!await launchUrl(
                        mapsUri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        await launchUrl(
                          mapsUri,
                          mode: LaunchMode.platformDefault,
                        );
                      }
                    } catch (e) {
                      _showErrorSnackBar("Could not open maps application: $e");
                    }
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.compass_fill,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translate(
                              en: "Get Directions",
                              hi: "दिशा-निर्देश प्राप्त करें",
                              mr: "मार्ग मिळवा",
                              ta: "வழிமுறைகளைப் பெறுக",
                              te: "దిశలను పొందండి",
                              kn: "ನಿರ್ದೇಶನಗಳನ್ನು ಪಡೆಯಿರಿ",
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SupportScaleBtn(
                  onTap: () => _copyToClipboard(
                    address,
                    _translate(
                      en: "Address",
                      hi: "पता",
                      mr: "पत्ता",
                      ta: "முகவரி",
                      te: "చిరునామా",
                      kn: "ವಿಳಾಸ",
                    ),
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_on_doc_fill,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translate(
                              en: "Copy Address",
                              hi: "पता कॉपी करें",
                              mr: "पत्ता कॉपी करा",
                              ta: "முகவரி நகலெடு",
                              te: "చిరునామా కాపీ చేయి",
                              kn: "ವಿಳಾಸ ನಕಲಿಸಿ",
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper scale animator for click feedback
class _SupportScaleBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _SupportScaleBtn({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_SupportScaleBtn> createState() => _SupportScaleBtnState();
}

class _SupportScaleBtnState extends State<_SupportScaleBtn>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Live pulsing status indicator dot
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return Container(
          width: 12 + (3 * _controller.value),
          height: 12 + (3 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3),
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Collapsible FAQ Accordion widget
class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? theme.primaryColor.withOpacity(0.15)
              : Colors.grey.shade200,
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? theme.primaryColor.withOpacity(0.04)
                : Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isExpanded
                            ? theme.primaryColor
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: _isExpanded
                          ? theme.primaryColor
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
