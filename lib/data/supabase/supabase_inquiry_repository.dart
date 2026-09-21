import 'package:supabase_flutter/supabase_flutter.dart';

import '../mappers/supabase_mappers.dart';
import '../models/inquiry.dart';
import '../repositories/inquiry_repository.dart';

class SupabaseInquiryRepository extends InquiryRepository {
  SupabaseInquiryRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final List<Inquiry> _cache = [];

  @override
  List<Inquiry> get inquiries => List.unmodifiable(_cache);

  @override
  Future<void> load() async {
    final rows = await _client
        .from('inquiries')
        .select()
        .order('created_at', ascending: false);
    _cache
      ..clear()
      ..addAll([
        for (final row in rows as List)
          if (row is Map) inquiryFromRow(Map<String, dynamic>.from(row)),
      ]);
    notifyListeners();
  }

  @override
  Future<Inquiry> add({
    required String name,
    required String phone,
    required String message,
    String? listingId,
  }) async {
    final inserted = await _client
        .from('inquiries')
        .insert({
          'listing_id': listingId,
          'requester_id': _client.auth.currentUser?.id,
          'name': name.trim(),
          'phone': phone.trim(),
          'message': message.trim(),
        })
        .select()
        .single();
    final inquiry = inquiryFromRow(Map<String, dynamic>.from(inserted));
    latestId = inquiry.id;
    _cache.insert(0, inquiry);
    notifyListeners();
    return inquiry;
  }
}
