import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:krishikranti/firebase_options.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/app_theme.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/core/notification_service.dart';
import 'package:krishikranti/core/notification_provider.dart';
import 'package:krishikranti/core/update_service.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';
import 'package:krishikranti/features/splash/presentation/pages/splash_page.dart';
import 'package:krishikranti/features/language/presentation/pages/choose_language_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/choose_user_type_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/farmer_redirect_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/otp_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/register_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/ekyc_page.dart';
import 'package:krishikranti/screens/main_screen.dart';
import 'package:krishikranti/screens/search_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/contact_us_screen.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/address_service.dart';
import 'package:krishikranti/screens/order_detail_screen.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';
import 'package:krishikranti/screens/coupons_screen.dart';
import 'package:krishikranti/screens/favorites_screen.dart';
import 'package:krishikranti/screens/my_orders_screen.dart';
import 'package:krishikranti/screens/notification_screen.dart';
import 'package:krishikranti/screens/profile_screen.dart';
import 'package:krishikranti/screens/edit_profile_screen.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';
import 'package:krishikranti/screens/about_us_screen.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

// Top-level callback required by flutter_downloader (runs in a background isolate).
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  try {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('=== ERROR in top-level downloadCallback: $e ===');
    }
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // ── Silence all debugPrint output in production builds ──────────────────
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Update Service (remote config)
  await UpdateService.init();

  // Initialize FlutterDownloader (WorkManager-backed background downloads)
  await FlutterDownloader.initialize(debug: kDebugMode);
  FlutterDownloader.registerCallback(downloadCallback);

  // Initialize Language Service (load saved locale synchronously before startup)
  await LanguageService.initialize();

  // Initialize Notification Service
  await NotificationService.initialize();

  // Initialize Meta/Facebook SDK in background to avoid blocking main thread
  MetaAnalyticsService.initialize();

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
        ChangeNotifierProvider(create: (_) => DynamicTranslationService()),
        ChangeNotifierProvider(create: (_) => FavoriteService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => AddressService()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
      themeMode: ThemeMode.light,
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
        '/choose-user-type': (context) => const ChooseUserTypePage(),
        '/farmer-redirect': (context) => const FarmerRedirectPage(),
        '/language': (context) => const ChooseLanguagePage(),
        '/phone-verify': (context) => const PhoneVerifyPage(),
        '/otp': (context) => const OtpPage(),
        '/register': (context) => const RegisterPage(),
        '/kyc': (context) => const EkycPage(),
        '/dashboard': (context) => const MainScreen(),
        '/search': (context) => const SearchScreen(),
        '/language-select': (context) =>
            const ChooseLanguagePage(isSettings: true),
        '/contact': (context) => const ContactUsScreen(),
      },
            onGenerateRoute: (settings) {
        if (settings.name == '/cart') {
          return MaterialPageRoute(builder: (context) => const CartScreen());
        }
        if (settings.name == '/products' || settings.name == '/catalogue') {
          return MaterialPageRoute(builder: (context) => const CatalogueScreen());
        }
        if (settings.name == '/orders' || settings.name == '/my_orders') {
          return MaterialPageRoute(builder: (context) => const MyOrdersScreen());
        }
        if (settings.name == '/coupons' || settings.name == '/offers') {
          return MaterialPageRoute(builder: (context) => const CouponsScreen());
        }
        if (settings.name == '/favorites' || settings.name == '/wishlist') {
          return MaterialPageRoute(builder: (context) => const FavoritesScreen());
        }
        if (settings.name == '/notifications' || settings.name == '/inbox') {
          return MaterialPageRoute(builder: (context) => const NotificationScreen());
        }
        if (settings.name == '/profile') {
          return MaterialPageRoute(builder: (context) => const ProfileScreen());
        }
        if (settings.name == '/edit-profile') {
          return MaterialPageRoute(builder: (context) => const EditProfileScreen());
        }
        if (settings.name == '/shipping-address' || settings.name == '/addresses') {
          return MaterialPageRoute(builder: (context) => const ShippingAddressScreen());
        }
        if (settings.name == '/about-us') {
          return MaterialPageRoute(builder: (context) => const AboutUsScreen());
        }
        if (settings.name != null &&
            settings.name!.startsWith('/order_details/')) {
          final orderId = settings.name!.replaceFirst('/order_details/', '');
          return MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
          );
        }
        return null;
      },
    );
  }
}
