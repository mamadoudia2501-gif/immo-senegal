import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/broker.dart';
import 'app_avatar.dart';

class BrokerCard extends StatelessWidget {
  const BrokerCard({super.key, required this.broker});

  final Broker broker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: appCardShadow,
      ),
      child: Card(
        child: InkWell(
          key: Key('broker-card-${broker.id}'),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => context.push('/courtier/${broker.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppAvatar(
                  initials: broker.initials,
                  seed: broker.id,
                  radius: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(broker.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${broker.agency} · ${broker.city}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          broker.specialty,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
