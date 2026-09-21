import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key, this.nextPath});

  final String? nextPath;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    await context.read<AuthRepository>().requestCode(
      phone: _phoneController.text,
      name: _nameController.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    final next = widget.nextPath;
    final suffix = next == null || next.isEmpty
        ? ''
        : '?next=${Uri.encodeQueryComponent(next)}';
    context.push('/connexion/code$suffix');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remote = context.watch<AuthRepository>().isRemote;
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Inscription par téléphone',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              remote
                  ? 'Un code vous sera envoyé par SMS. Si le téléphone n’est pas activé sur le projet, un code e-mail de secours est utilisé. Le numéro reste enregistré sur le profil.'
                  : 'Un code WhatsApp de démo peut s’afficher pour tester un compte annonceur. Aucun SMS réel n’est envoyé.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('auth-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom (optionnel)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('auth-phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (Sénégal)',
                hintText: '77 123 45 67',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (!isValidSenegalPhone(value ?? '')) {
                  return 'Numéro sénégalais attendu (ex. 77 123 45 67)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('auth-continue'),
              onPressed: _sending ? null : _continue,
              child: Text(
                _sending
                    ? 'Envoi…'
                    : (remote
                          ? 'Recevoir le code'
                          : 'Recevoir le code WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
