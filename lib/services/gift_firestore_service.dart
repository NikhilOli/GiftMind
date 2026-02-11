import 'package:cloud_firestore/cloud_firestore.dart';

class GiftFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getGiftsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // doc IDs are gift IDs (you uploaded docs using doc(id))
    final futures = ids.map((id) => _db.collection('gifts').doc(id).get()).toList();
    final docs = await Future.wait(futures);

    final items = <Map<String, dynamic>>[];
    for (final d in docs) {
      if (d.exists && d.data() != null) items.add(d.data()!);
    }
    return items; // preserves the ids order automatically
  }
}
