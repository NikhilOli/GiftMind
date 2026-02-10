import 'package:flutter/material.dart';
import 'preferences_screen.dart';
import '../models/user_input.dart';


class GiftDetailsScreen extends StatefulWidget {
  static const routeName = '/gift-details';

  const GiftDetailsScreen({super.key});

  @override
  State<GiftDetailsScreen> createState() => _GiftDetailsScreenState();
}

class _GiftDetailsScreenState extends State<GiftDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  String? _gender;
  String? _relationship;
  String? _occasion;

  double _budget = 3000; // NPR (default)

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _relationshipOptions = [
    'Friend',
    'Best Friend',
    'Partner',
    'Sibling',
    'Parent',
    'Colleague',
    'Other'
  ];
  final List<String> _occasionOptions = [
    'Birthday',
    'Anniversary',
    'Festival',
    'Graduation',
    'Valentine’s Day',
    'Wedding',
    'Other'
  ];

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _continue() {
  if (!_formKey.currentState!.validate()) return;

  if (_gender == null || _relationship == null || _occasion == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select gender, relationship, and occasion.')),
    );
    return;
  }

  final age = int.parse(_ageController.text.trim());

  final input = UserInput(
    age: age,
    gender: _gender!,
    relationship: _relationship!,
    occasion: _occasion!,
    budgetNpr: _budget.toInt(),
    interests: const [],
    giftStyle: 'Practical',
  );

  Navigator.pushNamed(
    context,
    PreferencesScreen.routeName,
    arguments: input,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Details'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              const Text(
                'Tell us about the person you’re buying a gift for.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Recipient Age
              const Text('Recipient Age', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g., 21',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Age is required';
                  final age = int.tryParse(v);
                  if (age == null) return 'Enter a valid number';
                  if (age < 1 || age > 120) return 'Enter an age between 1 and 120';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              const Text('Recipient Gender', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select gender',
                ),
              ),
              const SizedBox(height: 16),

              // Relationship dropdown
              const Text('Relationship', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _relationship,
                items: _relationshipOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _relationship = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select relationship',
                ),
              ),
              const SizedBox(height: 16),

              // Occasion dropdown
              const Text('Occasion', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _occasion,
                items: _occasionOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _occasion = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select occasion',
                ),
              ),
              const SizedBox(height: 16),

              // Budget slider
              const Text('Budget Range (NPR)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Selected: NPR ${_budget.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14),
              ),
              Slider(
                value: _budget,
                min: 500,
                max: 20000,
                divisions: 39, // step size ~500
                label: 'NPR ${_budget.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _budget = v),
              ),

              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
