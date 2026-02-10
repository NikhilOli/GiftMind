import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../services/gift_repository.dart';
import '../services/recommender_service.dart';

class RecommendationsScreen extends StatefulWidget {
  static const routeName = '/recommendations';

  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _repo = GiftRepository();
  final _recommender = RecommenderService();

  @override
  Widget build(BuildContext context) {
    final input = ModalRoute.of(context)!.settings.arguments as UserInput;

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: FutureBuilder(
        future: _repo.loadGifts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading gifts: ${snapshot.error}'));
          }

          final gifts = snapshot.data ?? [];
          final scored = _recommender.recommend(input: input, gifts: gifts, topN: 10);

          if (scored.isEmpty) {
            return const Center(
              child: Text('No recommendations found. Try adjusting preferences.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(input),
              const SizedBox(height: 12),
              const Text(
                'Top Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...scored.map((s) => _giftCard(s)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(UserInput input) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Inputs', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Relationship: ${input.relationship}'),
            Text('Occasion: ${input.occasion}'),
            Text('Budget: NPR ${input.budgetNpr}'),
            Text('Interests: ${input.interests.join(', ')}'),
            Text('Style: ${input.giftStyle}'),
          ],
        ),
      ),
    );
  }

  Widget _giftCard(ScoredGift scoredGift) {
    final g = scoredGift.gift;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(g.description),
            const SizedBox(height: 8),
            Text('Budget: NPR ${g.minBudget}–${g.maxBudget}  •  Style: ${g.style}'),
            const SizedBox(height: 6),
            Text('Score: ${scoredGift.score}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Why: ${scoredGift.reasons.join(' • ')}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
