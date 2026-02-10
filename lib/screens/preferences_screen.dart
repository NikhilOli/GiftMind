import 'package:flutter/material.dart';
import '../models/user_input.dart';
import 'recommendations_screen.dart';

class PreferencesScreen extends StatefulWidget {
  static const routeName = '/preferences';

  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final List<String> _interestOptions = const [
    'Books',
    'Fashion',
    'Technology',
    'Home & Decor',
    'Fitness',
    'Gaming',
    'Music',
    'Beauty',
    'Food',
    'Travel',
    'Art',
    'Stationery',
  ];

  final Set<String> _selectedInterests = {};
  String _giftStyle = 'Practical'; // default

  @override
  Widget build(BuildContext context) {
    final input = ModalRoute.of(context)!.settings.arguments as UserInput;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Additional Preferences',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Select interests to personalize recommendations.'),
            const SizedBox(height: 16),

            const Text('Interests', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _interestOptions.map((interest) {
                final selected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 22),
            const Text('Gift Style', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            RadioListTile<String>(
              value: 'Practical',
              groupValue: _giftStyle,
              title: const Text('Practical'),
              onChanged: (v) => setState(() => _giftStyle = v!),
            ),
            RadioListTile<String>(
              value: 'Surprise',
              groupValue: _giftStyle,
              title: const Text('Surprise'),
              onChanged: (v) => setState(() => _giftStyle = v!),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // optional: require at least 1 interest
                  if (_selectedInterests.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select at least one interest.')),
                    );
                    return;
                  }

                  final updated = input.copyWith(
                    interests: _selectedInterests.toList(),
                    giftStyle: _giftStyle,
                  );

                  Navigator.pushNamed(
                    context,
                    RecommendationsScreen.routeName,
                    arguments: updated,
                  );
                },
                child: const Text('View Recommendations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
