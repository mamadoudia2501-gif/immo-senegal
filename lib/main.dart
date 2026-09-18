import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/inquiry_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final inquiries = InquiryRepository(
    preferences: await SharedPreferences.getInstance(),
  );
  await inquiries.load();
  runApp(ImmoApp(inquiryRepository: inquiries));
}
