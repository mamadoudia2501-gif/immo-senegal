import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _whatsapp;
  late final TextEditingController _other;
  late final TextEditingController _address;
  var _city = AppConstants.cities.first;
  var _ready = false;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final user = context.read<AuthRepository>().currentUser;
    _name = TextEditingController(text: user?.displayName ?? '');
    _whatsapp = TextEditingController(
      text: user?.whatsapp ?? user?.phone ?? '',
    );
    _other = TextEditingController(text: user?.otherContact ?? '');
    _address = TextEditingController(text: user?.address ?? '');
    _city = user?.city ?? AppConstants.cities.first;
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) {
      _name.dispose();
      _whatsapp.dispose();
      _other.dispose();
      _address.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await context.read<AuthRepository>().updateProfile(
      displayName: _name.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      otherContact: _other.text.trim(),
      address: _address.text.trim(),
      city: _city,
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    if (user == null || user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Profil annonceur indisponible.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Compléter mon profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Ces informations sont visibles sur votre page publique (story et annonces).',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('profile-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom public'),
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Indiquez votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profile-whatsapp'),
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp / téléphone',
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 8) {
                  return 'Indiquez un numéro de contact';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profile-other'),
              controller: _other,
              decoration: const InputDecoration(
                labelText: 'Autre contact (e-mail, 2e n°)',
              ),
            ),
            const SizedBox(height: 12),
            Text('Ville', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final city in AppConstants.cities)
                  ChoiceChip(
                    label: Text(city),
                    selected: _city == city,
                    onSelected: (_) => setState(() => _city = city),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profile-address'),
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Adresse'),
              validator: (value) {
                if ((value ?? '').trim().length < 4) {
                  return 'Indiquez une adresse';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('profile-save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
