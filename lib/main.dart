import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/app_theme.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/features/splash/presentation/pages/splash_page.dart';
import 'package:krishikranti/features/language/presentation/pages/choose_language_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/otp_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/register_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/ekyc_page.dart';
import 'package:krishikranti/screens/main_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/language_screen.dart';
import 'package:krishikranti/screens/contact_us_screen.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Set global system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => FavoriteService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
      title: 'Krishi Dealer',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: languageService.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/language': (context) => const ChooseLanguagePage(),
        '/phone-verify': (context) => const PhoneVerifyPage(),
        '/otp': (context) => const OtpPage(),
        '/register': (context) => const RegisterPage(),
        '/kyc': (context) => const EkycPage(),
        '/dashboard': (context) => const MainScreen(),
        '/language-select': (context) => const LanguageScreen(),
        '/contact': (context) => const ContactUsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/cart') {
          return MaterialPageRoute(builder: (context) => const CartScreen());
        }
        return null;
      },
    );
  }
}
