import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/broker_repository.dart';
import 'data/repositories/inquiry_repository.dart';
import 'data/repositories/listing_repository.dart';
import 'features/search/listing_filter_controller.dart';

class ImmoApp extends StatefulWidget {
  const ImmoApp({
    super.key,
    required this.inquiryRepository,
    this.listingRepository = const ListingRepository(),
    this.brokerRepository = const BrokerRepository(),
  });

  final InquiryRepository inquiryRepository;
  final ListingRepository listingRepository;
  final BrokerRepository brokerRepository;

  @override
  State<ImmoApp> createState() => _ImmoAppState();
}

class _ImmoAppState extends State<ImmoApp> {
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.listingRepository),
        Provider.value(value: widget.brokerRepository),
        ChangeNotifierProvider.value(value: widget.inquiryRepository),
        ChangeNotifierProvider(create: (_) => ListingFilterController()),
      ],
      child: MaterialApp.router(
        title: AppConstants.name,
        theme: AppTheme.light(),
        routerConfig: _router,
        locale: const Locale('fr', 'SN'),
        supportedLocales: const [Locale('fr', 'SN'), Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (MediaQuery.sizeOf(context).width <= 700) return content;
          return ColoredBox(
            color: const Color(0xFFE8E2D6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}
