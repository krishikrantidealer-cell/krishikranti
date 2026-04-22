import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = languageService.locale.languageCode;

    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
      {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectLanguage,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: languages.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 24,
          endIndent: 24,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = currentLocale == lang['code'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            onTap: () {
              languageService.setLocale(lang['code']!);
            },
            title: Text(
              lang['native']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : Colors.black87,
              ),
            ),
            subtitle: Text(
              lang['name']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: theme.colorScheme.primary,
                    size: 26,
                  )
                : null,
          );
        },
      ),
    );
  }
}
