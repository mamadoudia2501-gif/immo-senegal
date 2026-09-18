import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/broker_repository.dart';
import '../../shared/widgets/broker_card.dart';
import '../../shared/widgets/shimmer.dart';
import '../shell/catalog_ready.dart';

class BrokersScreen extends StatelessWidget {
  const BrokersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<CatalogReady>().ready;
    final brokers = context.read<BrokerRepository>().all();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Courtiers')),
      body: !ready
          ? ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: const [
                ListingSkeleton(),
                SizedBox(height: 16),
                ListingSkeleton(),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Des professionnels basés à Dakar, sur la Petite-Côte et dans les régions.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${brokers.length} courtiers · mise en relation locale',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                for (final broker in brokers) ...[
                  BrokerCard(broker: broker),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}
