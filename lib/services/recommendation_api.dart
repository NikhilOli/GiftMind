import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationApi {
  static const String url =
      'https://us-central1-giftmind-app-3b181.cloudfunctions.net/recommend';

  Future<List<Map<String, dynamic>>> recommend({
    required String occasion,
    required String relationship,
    required int budgetNpr,
    required List<String> interests,
    required String giftStyle,
    int limit = 10,
  }) async {
    final resp = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'occasion': occasion,
        'relationship': relationship,
        'budgetNpr': budgetNpr,
        'interests': interests,
        'giftStyle': giftStyle,
        'limit': limit,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception("API ${resp.statusCode}: ${resp.body}");
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (data['results'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return results;
  }
}
