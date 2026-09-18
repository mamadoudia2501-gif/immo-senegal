import 'package:url_launcher/url_launcher.dart';

import 'phone.dart';

Future<void> launchPhone(String phone) {
  return launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}'));
}

Future<void> launchMail(String email) {
  return launchUrl(Uri.parse('mailto:$email'));
}

/// Ouvre WhatsApp (schéma natif) ou le lien wa.me en repli — simulation locale.
Future<void> launchWhatsApp(String phone) async {
  final digits = senegalWhatsAppDigits(phone);
  final native = Uri.parse('whatsapp://send?phone=$digits');
  try {
    if (await canLaunchUrl(native)) {
      await launchUrl(native, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  await launchUrl(
    Uri.parse('https://wa.me/$digits'),
    mode: LaunchMode.externalApplication,
  );
}
