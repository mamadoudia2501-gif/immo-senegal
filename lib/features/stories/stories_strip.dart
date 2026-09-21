import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../shared/widgets/story_media_view.dart';

class StoriesStrip extends StatelessWidget {
  const StoriesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoryRepository>();
    final auth = context.watch<AuthRepository>();
    final authors = stories.publicAuthorPhones();
    final user = auth.currentUser;
    final canPost = user != null && !user.isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'Statuts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        SizedBox(
          key: const Key('stories-strip'),
          height: 108,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              if (canPost)
                _StripItem(
                  key: const Key('story-add'),
                  label: 'Votre statut',
                  avatar: StoryRingAvatar(
                    initials: user.initials,
                    seed: user.phone,
                    seen: true,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(Icons.add, color: AppColors.primaryDark),
                    ),
                  ),
                  onTap: () => context.push('/statuts/nouveau'),
                ),
              for (final phone in authors)
                _AuthorRing(
                  phone: phone,
                  profile: resolveAdvertiserProfile(
                    phone: phone,
                    registered: auth.byPhone(phone),
                  ),
                ),
              if (!canPost && authors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 28),
                  child: Text(
                    'Aucun statut pour le moment',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorRing extends StatelessWidget {
  const _AuthorRing({required this.phone, required this.profile});

  final String phone;
  final AdvertiserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final local = senegalLocalDigits(phone);
    final name = profile?.displayName ?? 'Annonceur';
    return _StripItem(
      key: Key('story-author-$local'),
      label: name.split(' ').first,
      avatar: StoryRingAvatar(initials: profile?.initials ?? 'AN', seed: phone),
      onTap: () => context.push('/statuts/$local'),
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem({
    super.key,
    required this.label,
    required this.avatar,
    required this.onTap,
  });

  final String label;
  final Widget avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              avatar,
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
