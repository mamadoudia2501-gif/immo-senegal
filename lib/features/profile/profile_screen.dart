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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    child: Icon(Icons.person_rounded, size: 44),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Visiteur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Compte local · aucune connexion requise',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xE6FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: appCardShadow,
            ),
            child: const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.language_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text('Langue'),
                    subtitle: Text('Français'),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text('Devise'),
                    subtitle: Text(AppConstants.currency),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.flag_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text('Marché'),
                    subtitle: Text(AppConstants.country),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: appCardShadow,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochaines étapes',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connexion (auth), cartes, backend réel, notifications et espace courtier arriveront dans une prochaine version. Ce MVP fonctionne entièrement hors ligne avec des données d’exemple.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${AppConstants.name} · MVP 1.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
