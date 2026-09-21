import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
