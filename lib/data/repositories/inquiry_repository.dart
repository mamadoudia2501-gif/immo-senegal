import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inquiry.dart';

class InquiryRepository extends ChangeNotifier {
  InquiryRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  InquiryRepository.remote() : _preferences = null;

  static const _storageKey = 'immo_senegal_inquiries';

  SharedPreferences? _preferences;
  final List<Inquiry> _inquiries = [];
  bool _loaded = false;
  String? latestId;

  List<Inquiry> get inquiries => List.unmodifiable(_inquiries);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_storageKey);
    _inquiries
      ..clear()
      ..addAll(_decode(raw));
    _loaded = true;
    notifyListeners();
  }

  Future<Inquiry> add({
    required String name,
    required String phone,
    required String message,
    String? listingId,
  }) async {
    final inquiry = Inquiry(
      id: 'd${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone.trim(),
      message: message.trim(),
      listingId: listingId,
      createdAt: DateTime.now(),
    );
    _inquiries.insert(0, inquiry);
    latestId = inquiry.id;
    await _persist();
    notifyListeners();
    return inquiry;
  }

  List<Inquiry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) Inquiry.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _inquiries.map((inquiry) => inquiry.toJson()).toList(),
    );
    await _preferences!.setString(_storageKey, payload);
  }
}
