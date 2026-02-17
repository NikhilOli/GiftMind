import 'dart:convert';
import 'package:http/http.dart' as http;

class GiftImageApi {
  static const String url =
      'https://us-central1-giftmind-app-3b181.cloudfunctions.net/getGiftImage';

  Future<String?> getImageUrl({
    required String giftId,
    required String query,
  }) async {
    final resp = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'giftId': giftId, 'query': query}),
    );

    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    return imageUrl.isEmpty ? null : imageUrl;
  }
}
