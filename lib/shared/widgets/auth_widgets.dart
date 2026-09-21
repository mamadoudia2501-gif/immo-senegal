import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class DemoAccountsCard extends StatelessWidget {
  const DemoAccountsCard({super.key, this.onFillAdmin});

  final VoidCallback? onFillAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sand.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFE4D9C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comptes de démo',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Visiteur : parcourir sans compte.\n'
            'Annonceur : n’importe quel n° 7x + code WhatsApp ${AppConstants.whatsappDemoCode} · 4 annonces gratuites, puis 100 FCFA.\n'
            'Admin : 77 000 00 00 + code ${AppConstants.whatsappDemoCode} · publication gratuite illimitée.',
            style: TextStyle(height: 1.45),
          ),
          if (onFillAdmin != null) ...[
            const SizedBox(height: 10),
            TextButton(
              key: const Key('fill-admin-phone'),
              onPressed: onFillAdmin,
              child: const Text('Remplir le numéro admin'),
            ),
          ],
        ],
      ),
    );
  }
}

class PublishCta extends StatelessWidget {
  const PublishCta({super.key, required this.onPressed, this.light = false});

  final VoidCallback onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (light) {
      return OutlinedButton.icon(
        key: const Key('publish-cta'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0x66FFFFFF), width: 1.4),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Publier une annonce'),
      );
    }
    return FilledButton.icon(
      key: const Key('publish-cta'),
      onPressed: onPressed,
      icon: const Icon(Icons.add_home_work_outlined),
      label: const Text('Publier une annonce'),
    );
  }
}

void openPublishFlow(BuildContext context, {required bool loggedIn}) {
  if (loggedIn) {
    context.push('/annonce/nouvelle');
  } else {
    context.push('/connexion?next=/annonce/nouvelle');
  }
}
