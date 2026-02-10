import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/gift_item.dart';

class GiftRepository {
  Future<List<GiftItem>> loadGifts() async {
    final jsonStr = await rootBundle.loadString('assets/gifts.json');
    final data = jsonDecode(jsonStr) as List<dynamic>;
    return data.map((e) => GiftItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
