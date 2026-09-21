import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/backend/app_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final preferences = await SharedPreferences.getInstance();
  final opened = await openAppRepositories(preferences: preferences);
  assert(() {
    debugPrint('Immo Sénégal backend : ${AppConfig.backendLabel}');
    return true;
  }());
  await Future.wait([
    opened.inquiries.load(),
    opened.auth.load(),
    opened.listings.load(),
    opened.stories.load(),
    opened.conversations.load(),
  ]);
  runApp(
    ImmoApp(
      inquiryRepository: opened.inquiries,
      authRepository: opened.auth,
      listingRepository: opened.listings,
      storyRepository: opened.stories,
      conversationRepository: opened.conversations,
    ),
  );
}
