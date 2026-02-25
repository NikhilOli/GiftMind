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
  // Keep list concise but useful
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
    'Pets',
    'Sports',
  ];

  final List<String> _ageGroups = const [
    'Teen',
    'Young Adult',
    'Adult',
    'Senior',
  ];

  final List<String> _personalityOptions = const [
    'Minimalist',
    'Trendy',
    'Sentimental',
  ];

  final Set<String> _selectedInterests = {};
  final Set<String> _dislikedCategories = {};

  String _giftStyle = 'Practical';
  String _recipientPersonality = 'Minimalist';
  String _recipientAgeGroup = 'Adult';

  @override
  Widget build(BuildContext context) {
    final input = ModalRoute.of(context)!.settings.arguments as UserInput;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipient Preferences')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Recipient Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell us about the person you are gifting. This helps the AI personalize results.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),

            // Age group
            const Text('Age Group', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _recipientAgeGroup,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _ageGroups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _recipientAgeGroup = v ?? 'Adult'),
            ),

            const SizedBox(height: 18),

            // Personality
            const Text('Personality', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _personalityOptions.map((p) {
                final selected = _recipientPersonality == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() => _recipientPersonality = p),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Interests
            const Text('Interests', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Pick 2–5 interests for better recommendations.',
              style: TextStyle(color: Colors.black54),
            ),
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
                        // Soft cap to keep UX clean
                        if (_selectedInterests.length >= 5) return;
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            if (_selectedInterests.length >= 5) ...[
              const SizedBox(height: 8),
              const Text(
                'Max 5 interests selected.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],

            const SizedBox(height: 18),

            // Disliked categories (optional but powerful)
            const Text('Avoid Categories (optional)',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Choose up to 3 categories the recipient does NOT like.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _interestOptions.map((cat) {
                final selected = _dislikedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        if (_dislikedCategories.length >= 3) return;
                        _dislikedCategories.add(cat);
                      } else {
                        _dislikedCategories.remove(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Gift style (session preference)
            const Text('Gift Style', style: TextStyle(fontWeight: FontWeight.w800)),
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

            const SizedBox(height: 18),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  if (_selectedInterests.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select at least 2 interests.')),
                    );
                    return;
                  }

                  final updated = input.copyWith(
                    interests: _selectedInterests.toList(),
                    giftStyle: _giftStyle,
                    recipientAgeGroup: _recipientAgeGroup,
                    recipientPersonality: _recipientPersonality,
                    dislikedCategories: _dislikedCategories.toList(),
                  );

                  Navigator.pushNamed(
                    context,
                    RecommendationsScreen.routeName,
                    arguments: updated,
                  );
                },
                child: const Text(
                  'View Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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