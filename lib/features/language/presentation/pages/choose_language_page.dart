import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChooseLanguagePage extends StatefulWidget {
  const ChooseLanguagePage({super.key});

  @override
  State<ChooseLanguagePage> createState() => _ChooseLanguagePageState();
}

class _ChooseLanguagePageState extends State<ChooseLanguagePage> {
  // Common Indian agricultural languages
  final List<String> _languages = [
    'English',
    'Hindi (हिन्दी)',
    'Marathi (मराठी)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Gujarati (ગુજરાતી)',
    'Telugu (తెలుగు)',
    'Tamil (தமிழ்)',
    'Kannada (ಕನ್ನಡ)',
    'Malayalam (മലയാളം)',
    'Bengali (বাংলা)',
    'Odia (ଓଡ଼ିଆ)',
    'Urdu (اردو)',
    'Assamese (অসমীয়া)',
    'Kashmiri (کٲشُر)',
    'Nepali (नेपाली)',
    'Konkani (कोंকणी)',
    'Sindhi (سنڌي)',
    'Bodo (बड़ो)',
    'Maithili (मैथिली)',
    'Santhali (ᱥᱟᱱᱛᱟᱲᱤ)',
    'Dogri (डोगरी)',
  ];

  String? _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Layer 1: The Main Content (Scrollable Grid)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Choose Your Language',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your preferred language.',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: 120,
                        ), // More padding to ensure items don't hide behind button
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                        itemCount: _languages.length,
                        itemBuilder: (context, index) {
                          final language = _languages[index].split(' (')[0];
                          final fullLanguage = _languages[index];
                          final isSelected = _selectedLanguage == fullLanguage;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(
                                  () => _selectedLanguage = fullLanguage,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Center(
                                child: Text(
                                  language,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 2: Modern Squircle Forward Button (Bottom Right)
            Positioned(
              bottom: 30,
              right: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/phone-verify');
                    },
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.transparent,
                    child: Center(
                      child: Image.asset(
                        'assets/images/double_icon.png',
                        width: 30,
                        height: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
