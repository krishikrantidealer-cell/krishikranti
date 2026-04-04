import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:krishikranti/core/app_theme.dart';
import 'package:krishikranti/features/splash/presentation/pages/splash_page.dart';
import 'package:krishikranti/features/language/presentation/pages/choose_language_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/otp_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/register_page.dart';
import 'package:krishikranti/features/auth/presentation/pages/ekyc_page.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krishi Dealer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/language': (context) => const ChooseLanguagePage(),
        '/phone-verify': (context) => const PhoneVerifyPage(),
        '/otp': (context) => const OtpPage(),
        '/register': (context) => const RegisterPage(),
        '/ekyc': (context) => const EkycPage(),
        '/home': (context) => const MyHomePage(title: 'Krishi Dealer Home'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
