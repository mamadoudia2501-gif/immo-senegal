import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Code WhatsApp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Confirmation mock', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            phone == null
                ? 'Saisissez le code de démo pour valider le numéro.'
                : 'Un message WhatsApp a été simulé vers $phone. Aucun envoi réel.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
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
                  'Utilisez ce code pour tester (123456).',
                  style: TextStyle(color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('auth-code'),
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Code à 6 chiffres',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              errorText: _error ? 'Code incorrect. Essayez 123456.' : null,
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
