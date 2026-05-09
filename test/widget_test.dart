import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/main.dart';
import 'package:krishikranti/core/language_service.dart';
import 'package:krishikranti/core/favorite_service.dart';
import 'package:krishikranti/screens/home_screen.dart';
import 'package:krishikranti/screens/catalogue_screen.dart';
import 'package:krishikranti/features/products/data/models/category_model.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => FavoriteService()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that MyApp is present
    expect(find.byType(MyApp), findsOneWidget);
    
    // Allow any pending timers (like splash screen navigation) to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('CategoryCard Widget Test - Tap Trigger and Render', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            en: 'Insecticides',
            hi: 'कीटनाशक',
            icon: Icons.bug_report,
            image: 'https://storage.googleapis.com/krishi-product-images/categorycardbanners/Insecticides.webp',
            fallbackImage: 'https://images.unsplash.com/photo-1599420186946-7b6fb4e297f0?auto=format&fit=crop&q=80&w=400',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Verify elements are present
    expect(find.byType(CategoryCard), findsOneWidget);

    // Tap the card and verify action is executed
    await tester.tap(find.byType(CategoryCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('RectangularCategoryCard Widget Test - Tap Trigger and Render', (WidgetTester tester) async {
    bool tapped = false;
    final testCategory = Category(
      id: 'cat_insecticides',
      name: 'Insecticides',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RectangularCategoryCard(
            category: testCategory,
            imageUrl: 'https://storage.googleapis.com/krishi-product-images/categorycardbanners/Insecticides.webp',
            fallbackImage: 'https://images.unsplash.com/photo-1599420186946-7b6fb4e297f0?auto=format&fit=crop&q=80&w=400',
            icon: Icons.bug_report,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Verify elements are present
    expect(find.byType(RectangularCategoryCard), findsOneWidget);

    // Tap the card and verify action is executed
    await tester.tap(find.byType(RectangularCategoryCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
