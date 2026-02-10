import '../models/gift_item.dart';
import '../models/user_input.dart';

class ScoredGift {
  final GiftItem gift;
  final int score;
  final List<String> reasons;

  const ScoredGift({required this.gift, required this.score, required this.reasons});
}

class RecommenderService {
  List<ScoredGift> recommend({
    required UserInput input,
    required List<GiftItem> gifts,
    int topN = 5,
  }) {
    final results = <ScoredGift>[];

    for (final g in gifts) {
      // RULE FILTERS (context)
      if (input.budgetNpr < g.minBudget || input.budgetNpr > g.maxBudget) continue;
      if (!g.occasions.contains(input.occasion)) continue;
      if (!g.relationships.contains(input.relationship)) continue;

      int score = 0;
      final reasons = <String>[];

      // CONTENT-BASED: interest matches
      final interestMatches = g.tags.toSet().intersection(input.interests.toSet()).length;
      if (interestMatches > 0) {
        score += 3 * interestMatches;
        reasons.add('Matches interests (${interestMatches} tag(s))');
      }

      // Occasion match (already filtered, but still score)
      score += 3;
      reasons.add('Suitable for ${input.occasion}');

      // Relationship match (already filtered, but still score)
      score += 2;
      reasons.add('Fits relationship: ${input.relationship}');

      // Style match
      if (g.style == input.giftStyle) {
        score += 2;
        reasons.add('Matches style: ${input.giftStyle}');
      }

      // Budget closeness: closer to middle => higher
      final mid = (g.minBudget + g.maxBudget) / 2.0;
      final diff = (input.budgetNpr - mid).abs();
      // simple bucket scoring
      if (diff <= 500) {
        score += 2;
        reasons.add('Good budget fit');
      } else if (diff <= 1500) {
        score += 1;
      }

      results.add(ScoredGift(gift: g, score: score, reasons: reasons));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topN).toList();
  }
}
