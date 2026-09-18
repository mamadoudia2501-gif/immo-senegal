import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/broker_repository.dart';
import '../../shared/widgets/broker_card.dart';

class BrokersScreen extends StatelessWidget {
  const BrokersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brokers = context.read<BrokerRepository>().all();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Courtiers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Des professionnels basés à Dakar, sur la Petite-Côte et dans les régions.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          for (final broker in brokers) ...[
            BrokerCard(broker: broker),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
