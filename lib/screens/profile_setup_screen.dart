import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth_gate.dart';

class ProfileSetupScreen extends StatefulWidget {
  static const routeName = '/profile-setup';

  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _auth = AuthService();
  final _userService = UserService();

  final List<String> allInterests = [
    'tech',
    'fitness',
    'books',
    'fashion',
    'beauty',
    'home',
  ];

  final Set<String> selectedInterests = {};
  String selectedStyle = 'practical';
  String selectedPersonality = 'minimalist';

  bool loading = false;

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => loading = true);

    await _userService.saveProfileDefaults(
      uid: uid,
      profile: {
        'interests': selectedInterests.toList(),
        'stylePreference': selectedStyle,
        'personalityTag': selectedPersonality,
      },
    );

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AuthGate.routeName, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Select Your Interests",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: allInterests.map((i) {
                final selected = selectedInterests.contains(i);
                return FilterChip(
                  label: Text(i),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        selectedInterests.remove(i);
                      } else {
                        selectedInterests.add(i);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text("Preferred Style",
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedStyle,
              items: ['practical', 'luxury', 'creative']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStyle = v!),
            ),
            const SizedBox(height: 20),
            const Text("Personality",
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedPersonality,
              items: ['minimalist', 'trendy', 'sentimental']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPersonality = v!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : _saveProfile,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
