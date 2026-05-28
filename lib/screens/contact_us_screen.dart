import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

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

  // Support is online Mon-Sat, 9:00 AM to 7:00 PM
  bool _isSupportOnline() {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) return false;
    final hour = now.hour;
    return hour >= 9 && hour < 19;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    HapticFeedback.lightImpact();
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorSnackBar("Could not initiate phone call. Dialer not available.");
      }
    } catch (e) {
      _showErrorSnackBar("Error launching phone app: $e");
    }
  }

  Future<void> _sendEmail({required String email, String? subject, String? body}) async {
    HapticFeedback.lightImpact();
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
        _showErrorSnackBar("Could not open email client. No email app configured.");
      }
    } catch (e) {
      _showErrorSnackBar("Error launching email client: $e");
    }
  }

  Future<void> _sendWhatsAppMessage({required String phoneNumber, required String message}) async {
    HapticFeedback.lightImpact();
    final url = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
    final Uri launchUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar("Could not launch WhatsApp. Please check if WhatsApp is installed.");
      }
    } catch (e) {
      _showErrorSnackBar("Error launching WhatsApp: $e");
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

    final formattedMessage = "Hello Krishi Kranti Support,\n\n"
        "I have a query regarding: *$selectedTopic*\n\n"
        "Details:\n$messageText";

    if (useWhatsApp) {
      _sendWhatsAppMessage(
        phoneNumber: '917471121210',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            _PulsingDot(color: isOnline ? Colors.green : Colors.amber),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isOnline ? l10n.onlineSupportActive : l10n.offlineResponseDelayed,
                                  style: TextStyle(
                                    color: isOnline ? Colors.green.shade800 : Colors.amber.shade800,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.flash_on, color: primaryColor, size: 12),
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
                            phoneNumber: '917471121210',
                            message: "Hello Krishi Kranti Support, I need help with...",
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
                          onTap: () => _makePhoneCall('+917471121210'),
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
                          onTap: () => _sendEmail(email: 'info@krishikrantiorganics.com'),
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
                      border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  topic,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),

                        // Message Text Field
                        Text(
                          l10n.messageDetails,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Describe your issue, order question, or dealer interest...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                      colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF25D366).withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 18),
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
                                  border: Border.all(color: Colors.grey.shade200),
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

                  /// TRUST BADGE GRID (MODERN & STUNNING)
                  Text(
                    l10n.whyTrustKrishiKranti,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: [
                      _buildTrustBadge(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: l10n.dataPrivate,
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: primaryColor,
                      ),
                      _buildTrustBadge(
                        icon: CupertinoIcons.checkmark_seal_fill,
                        label: l10n.cibrcRegd,
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: primaryColor,
                      ),
                      _buildTrustBadge(
                        icon: CupertinoIcons.doc_text_fill,
                        label: l10n.gstInvoice,
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: primaryColor,
                      ),
                      _buildTrustBadge(
                        icon: CupertinoIcons.bus,
                        label: l10n.panIndiaDelivery,
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
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
}

/// Helper scale animator for click feedback
class _SupportScaleBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SupportScaleBtn({required this.child, required this.onTap});

  @override
  State<_SupportScaleBtn> createState() => _SupportScaleBtnState();
}

class _SupportScaleBtnState extends State<_SupportScaleBtn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
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

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
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
