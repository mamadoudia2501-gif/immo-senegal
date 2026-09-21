import '../constants/app_constants.dart';

/// Numéros mobiles sénégalais (préfixe 7x).
String senegalLocalDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('221') ? digits.substring(3) : digits;
}

bool isValidSenegalPhone(String input) {
  return RegExp(r'^7\d{8}$').hasMatch(senegalLocalDigits(input));
}

String formatSenegalPhone(String input) {
  final local = senegalLocalDigits(input);
  if (local.length != 9) return input.trim();
  return '+221 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5, 7)} ${local.substring(7)}';
}

String senegalWhatsAppDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('221') ? digits : '221$digits';
}

bool isReservedAdminPhone(String phone) =>
    senegalLocalDigits(phone) == AppConstants.adminPhoneLocal;

/// Affichage partiel pour les listes admin (jamais le numéro admin).
String maskSenegalPhone(String phone) {
  if (isReservedAdminPhone(phone)) return '•••••••••';
  final local = senegalLocalDigits(phone);
  if (local.length != 9) return '•• ••• •• ••';
  return '${local.substring(0, 2)} ••• ${local.substring(5, 7)} ${local.substring(7)}';
}
