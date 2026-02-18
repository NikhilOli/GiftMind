import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  static const routeName = '/'; // root route

  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnap.data?.data() as Map<String, dynamic>?;
            final profile = data?['profile'] as Map<String, dynamic>?;

            final interests = (profile?['interests'] as List?) ?? [];
            final style = (profile?['stylePreference'] ?? '').toString();
            final personality = (profile?['personalityTag'] ?? '').toString();

            final profileComplete =
                interests.isNotEmpty && style.isNotEmpty && personality.isNotEmpty;

            if (!profileComplete) return const ProfileSetupScreen();

            return const WelcomeScreen();
          },
        );
      },
    );
  }
}
