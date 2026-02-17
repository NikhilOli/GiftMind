import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../services/recommendation_api.dart';
import '../services/gift_firestore_service.dart';
import '../services/gift_image_api.dart';

class RecommendationsScreen extends StatefulWidget {
  static const routeName = '/recommendations';

  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _api = RecommendationApi();
  final _fs = GiftFirestoreService();
  final _imgApi = GiftImageApi();

  late UserInput input;

  bool loading = true;
  String? errorMsg;

  List<Map<String, dynamic>> apiRanks = []; // [{id,name,score}, ...]
  List<Map<String, dynamic>> gifts = []; // Firestore gift docs in same order

  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadedOnce) return;
    _loadedOnce = true;

    input = ModalRoute.of(context)!.settings.arguments as UserInput;
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        loading = true;
        errorMsg = null;
      });

      // 1) Call server-side recommendation API
      final ranks = await _api.recommend(
        occasion: input.occasion,
        relationship: input.relationship,
        budgetNpr: input.budgetNpr,
        interests: input.interests,
        giftStyle: input.giftStyle,
        limit: 10,
      );

      final ids = ranks.map((r) => (r['id'] ?? '').toString()).toList();

      // 2) Fetch gift docs from Firestore by docId (same as giftId)
      final fetched = await _fs.getGiftsByIds(ids);

      setState(() {
        apiRanks = ranks;
        gifts = fetched;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Error loading recommendations: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (errorMsg != null)
              ? Center(child: Text(errorMsg!))
              : _buildList(),
    );
  }

  Widget _buildList() {
    if (apiRanks.isEmpty) {
      return const Center(
        child: Text('No recommendations found. Try adjusting preferences.'),
      );
    }

    // Lookup score by gift id
    final scoreById = <String, dynamic>{};
    for (final r in apiRanks) {
      final id = (r['id'] ?? '').toString();
      scoreById[id] = r['score'];
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(input),
        const SizedBox(height: 12),
        const Text(
          'Top Recommendations (Server-Side)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...gifts.map((g) {
          final id = (g['id'] ?? '').toString();
          final score = scoreById[id];
          return _giftCardFromFirestore(g, score);
        }).toList(),
      ],
    );
  }

  Widget _summaryCard(UserInput input) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Inputs',
                style: TextStyle(fontWeight: FontWeight.w800)),
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

  Widget _giftCardFromFirestore(Map<String, dynamic> g, dynamic score) {
    final id = (g['id'] ?? '').toString();
    final name = (g['name'] ?? g['title'] ?? 'Unknown').toString();
    final desc = (g['description'] ?? '').toString();
    final minB = g['minBudget'];
    final maxB = g['maxBudget'];
    final style = (g['style'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ IMAGE (fetched from Unsplash via Cloud Function + cached in Firestore)
            FutureBuilder<String?>(
              future: _imgApi.getImageUrl(giftId: id, query: name),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                final url = snap.data;
                if (url == null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.card_giftcard, size: 52),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            if (desc.isNotEmpty) Text(desc),
            const SizedBox(height: 8),
            Text('Budget: NPR $minB–$maxB  •  Style: $style'),
            const SizedBox(height: 6),
            Text(
              'Score (API): ${score == null ? "-" : (score as num).toStringAsFixed(3)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
