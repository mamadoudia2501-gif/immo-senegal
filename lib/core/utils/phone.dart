/// Numéros mobiles sénégalais (préfixe 7x).
bool isValidSenegalPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('221') ? digits.substring(3) : digits;
  return RegExp(r'^7\d{8}$').hasMatch(local);
}

String formatSenegalPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('221') ? digits.substring(3) : digits;
  if (local.length != 9) return input.trim();
  return '+221 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5, 7)} ${local.substring(7)}';
}

String senegalWhatsAppDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('221') ? digits : '221$digits';
}
