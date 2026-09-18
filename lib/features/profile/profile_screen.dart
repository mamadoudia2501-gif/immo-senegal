import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _notify = true;
  var _preferredType = 'Location';
  final _cities = <String>{'Dakar', 'Saly'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: appCardShadow,
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  AppAvatar(initials: 'IS', seed: 'visitor', radius: 42),
                  SizedBox(height: 14),
                  Text(
                    'Visiteur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Compte local · aucune connexion requise',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xE6FFFFFF)),
                  ),
                  SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _Pill(label: 'Français', icon: Icons.language_rounded),
                      _Pill(
                        label: AppConstants.currency,
                        icon: Icons.payments_outlined,
                      ),
                      _Pill(
                        label: AppConstants.country,
                        icon: Icons.flag_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Préférences', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Réglages fictifs, stockés seulement le temps de la session.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: appCardShadow,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      value: _notify,
                      onChanged: (value) => setState(() => _notify = value),
                      activeThumbColor: AppColors.primary,
                      title: const Text('Alertes de nouveaux biens'),
                      subtitle: const Text('Simulation locale, sans push'),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Type de bien recherché',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final type in const [
                            'Location',
                            'Vente',
                            'Terrain',
                          ])
                            ChoiceChip(
                              label: Text(type),
                              selected: _preferredType == type,
                              onSelected: (_) =>
                                  setState(() => _preferredType = type),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Villes favorites',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final city in const [
                            'Dakar',
                            'Saly',
                            'Thiès',
                            'Saint-Louis',
                            'Ziguinchor',
                          ])
                            FilterChip(
                              label: Text(city),
                              selected: _cities.contains(city),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _cities.add(city);
                                  } else {
                                    _cities.remove(city);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Application', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
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
                    subtitle: Text('Français (Sénégal)'),
                    trailing: _LangBadge(),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'FR',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
