import 'package:flutter/material.dart';
import 'gift_details_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const routeName = '/';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 18),

              // Small top title (optional, like your wireframe)
              const Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'GiftMind',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              // Big center content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'GiftMind',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'A smart system for personalized\ngift recommendations',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, height: 1.35),
                    ),
                  ],
                ),
              ),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, GiftDetailsScreen.routeName);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(width: 2, color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Optional bottom note (you can remove if you want)
              const Text(
                'UNIVERSITY PROJECT WIREFRAME - LOW FIDELITY',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
