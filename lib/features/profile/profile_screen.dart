import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.sand,
            foregroundColor: AppColors.primaryDark,
            child: Icon(Icons.person_rounded, size: 44),
          ),
          const SizedBox(height: 12),
          Text(
            'Visiteur',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Compte local · aucune connexion requise',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('Langue'),
                  subtitle: Text('Français'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.payments_outlined),
                  title: Text('Devise'),
                  subtitle: Text(AppConstants.currency),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Marché'),
                  subtitle: Text(AppConstants.country),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochaines étapes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connexion (auth), cartes, backend réel, notifications et espace courtier arriveront dans une prochaine version. Ce MVP fonctionne entièrement hors ligne avec des données d’exemple.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${AppConstants.name} · MVP 1.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
