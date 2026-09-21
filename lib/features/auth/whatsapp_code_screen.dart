import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/conversation_repository.dart';

class WhatsAppCodeScreen extends StatefulWidget {
  const WhatsAppCodeScreen({super.key, this.nextPath});

  final String? nextPath;

  @override
  State<WhatsAppCodeScreen> createState() => _WhatsAppCodeScreenState();
}

class _WhatsAppCodeScreenState extends State<WhatsAppCodeScreen> {
  final _codeController = TextEditingController();
  var _error = false;
  var _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = false;
    });
    final ok = await context.read<AuthRepository>().verifyDemoCode(
      _codeController.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _verifying = false;
        _error = true;
      });
      return;
    }
    await context.read<ConversationRepository>().syncRemote();
    if (!mounted) return;
    final next = widget.nextPath;
    if (next != null && next.startsWith('/')) {
      context.go(next);
    } else {
      context.go('/profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final phone = auth.pendingPhone;
    final hideDemoCode = !auth.showDemoOtp;
    final remote = auth.isRemote;
    final emailFallback = auth.pendingUsesEmailFallback;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Code WhatsApp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            remote ? 'Confirmation' : 'Confirmation mock',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            phone == null
                ? 'Saisissez le code reçu pour valider le numéro.'
                : remote
                ? (emailFallback
                      ? 'Le SMS n’est pas disponible. Saisissez le code e-mail de secours pour $phone.'
                      : 'Saisissez le code reçu par SMS pour $phone.')
                : hideDemoCode
                ? 'Un message WhatsApp a été simulé. Saisissez le code reçu. Aucun envoi réel.'
                : 'Un message WhatsApp a été simulé vers $phone. Aucun envoi réel.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          if (!hideDemoCode)
            Container(
              key: const Key('whatsapp-demo-code'),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFFB7D9C8)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Code WhatsApp de démo',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.whatsappDemoCode,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Utilisez ce code pour tester (annonceur).',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                ],
              ),
            )
          else
            Container(
              key: const Key('whatsapp-admin-code-hidden'),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFFE4D9C8)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saisissez le code reçu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remote
                        ? 'Le code de démo n’est pas affiché en mode Supabase.'
                        : 'Pour ce compte, le code n’est pas affiché dans l’application.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('auth-code'),
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'Code WhatsApp',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              errorText: _error
                  ? (hideDemoCode
                        ? 'Code incorrect.'
                        : 'Code incorrect. Essayez ${AppConstants.whatsappDemoCode}.')
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('auth-verify'),
            onPressed: _verifying ? null : _verify,
            child: Text(_verifying ? 'Vérification…' : 'Valider le numéro'),
          ),
        ],
      ),
    );
  }
}
