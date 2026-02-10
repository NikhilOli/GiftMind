import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/gift_details_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/recommendations_screen.dart';

Future<void> main() async {
  runApp(const GiftMindApp());
}

class GiftMindApp extends StatelessWidget {
  const GiftMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiftMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      initialRoute: WelcomeScreen.routeName,
      routes: {
        WelcomeScreen.routeName: (_) => const WelcomeScreen(),
        GiftDetailsScreen.routeName: (_) => const GiftDetailsScreen(),
        PreferencesScreen.routeName: (_) => const PreferencesScreen(),
        RecommendationsScreen.routeName: (_) => const RecommendationsScreen(),
      },
    );
  }
}
