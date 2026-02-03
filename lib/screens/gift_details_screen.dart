import 'package:flutter/material.dart';

class GiftDetailsScreen extends StatelessWidget {
  static const routeName = '/gift-details';

  const GiftDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Details'),
      ),
      body: const Center(
        child: Text(
          'Gift Details Screen (Next)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
