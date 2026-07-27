import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppFab extends StatelessWidget {
  final bool mini;
  final EdgeInsets? padding;

  const WhatsAppFab({
    super.key,
    this.mini = false,
    this.padding,
  });

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse("https://wa.me/917471121210");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget fab = FloatingActionButton(
      onPressed: _launchWhatsApp,
      backgroundColor: const Color(0xFF25D366),
      elevation: 6,
      mini: mini,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mini ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(mini ? 8.0 : 10.0),
        child: Image.asset('assets/images/whatsapp.png'),
      ),
    );

    if (padding != null) {
      return Padding(padding: padding!, child: fab);
    }
    return fab;
  }
}
