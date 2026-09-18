import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/broker_repository.dart';
import '../../shared/widgets/broker_card.dart';

class BrokersScreen extends StatelessWidget {
  const BrokersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brokers = context.read<BrokerRepository>().all();

    return Scaffold(
      appBar: AppBar(title: const Text('Courtiers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Des professionnels basés à Dakar, sur la Petite-Côte et dans les régions.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final broker in brokers) ...[
            BrokerCard(broker: broker),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
