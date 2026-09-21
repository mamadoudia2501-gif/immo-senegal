import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/formatters/money_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/auth_widgets.dart';

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
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;
    final listings = context.watch<ListingRepository>();
    final mine = user == null
        ? const <Listing>[]
        : listings.byPublisher(user.phone);

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  AppAvatar(
                    initials: user?.initials ?? 'IS',
                    seed: user?.phone ?? 'visitor',
                    radius: 42,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.displayName ?? 'Visiteur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user == null
                        ? 'Parcourez les annonces sans compte'
                        : user.isAdmin
                        ? 'Compte administrateur'
                        : user.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xE6FFFFFF)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _Pill(
                        label: user?.role.label ?? 'Visiteur',
                        icon: Icons.badge_outlined,
                      ),
                      const _Pill(
                        label: 'Français',
                        icon: Icons.language_rounded,
                      ),
                      const _Pill(
                        label: AppConstants.currency,
                        icon: Icons.payments_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (user == null) ...[
            PublishCta(
              onPressed: () => openPublishFlow(context, loggedIn: false),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('profile-login-cta'),
              onPressed: () => context.push('/connexion'),
              child: const Text('Se connecter / s’inscrire'),
            ),
          ] else ...[
            if (user.isAdmin)
              const _QuotaCard(
                title: 'Publication illimitée',
                body:
                    'Compte administrateur : les annonces sont gratuites, sans quota.',
              )
            else
              _QuotaCard(
                key: const Key('quota-label'),
                title: user.freeListingsRemaining > 0
                    ? '${user.freeListingsRemaining} annonces gratuites restantes'
                    : 'Quota gratuit épuisé',
                body: user.freeListingsRemaining > 0
                    ? '${AppConstants.freeListingQuota} offertes au départ, puis ${formatFcfa(AppConstants.extraListingPriceFcfa)} / annonce.'
                    : 'Prochaine publication : ${formatFcfa(AppConstants.extraListingPriceFcfa)} (paiement mock).',
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('profile-publish-cta'),
              onPressed: () => context.push('/annonce/nouvelle'),
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('Publier une annonce'),
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('admin-moderation-cta'),
                onPressed: () => context.push('/admin/annonces'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Modérer les annonces'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('logout-cta'),
              onPressed: () => auth.logout(),
              child: const Text('Se déconnecter'),
            ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text('Mes annonces', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${mine.length} publication${mine.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
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

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.primaryDark)),
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
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
