import 'dart:math';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool looksLikeUuid(String value) => _uuidPattern.hasMatch(value);

/// UUID v4 (PK texte ou uuid côté Supabase).
String newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final body = bytes.map(hex).join();
  return '${body.substring(0, 8)}-${body.substring(8, 12)}-'
      '${body.substring(12, 16)}-${body.substring(16, 20)}-'
      '${body.substring(20)}';
}
