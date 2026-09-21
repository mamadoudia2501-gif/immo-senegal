import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../shared/widgets/story_media_view.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key, required this.authorPhone});

  final String authorPhone;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoryRepository>().byAuthor(
      widget.authorPhone,
      publicOnly: true,
    );
    final auth = context.watch<AuthRepository>();
    final profile = resolveAdvertiserProfile(
      phone: widget.authorPhone,
      registered: auth.byPhone(widget.authorPhone),
    );

    if (stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statut')),
        body: const Center(child: Text('Ce statut n’est plus disponible.')),
      );
    }

    final story = stories[_index.clamp(0, stories.length - 1)];
    final name = profile?.displayName ?? 'Annonceur';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          setState(() {
            if (details.localPosition.dx < width / 3) {
              _index = (_index - 1).clamp(0, stories.length - 1);
            } else if (_index < stories.length - 1) {
              _index += 1;
            } else {
              context.pop();
            }
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            StoryMediaView(media: story.media, expanded: true),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < stories.length; i++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              color: i <= _index
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StoryRingAvatar(
                          initials: profile?.initials ?? 'AN',
                          seed: widget.authorPhone,
                          size: 40,
                          seen: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (story.caption.isNotEmpty)
                      Text(
                        story.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (profile != null)
                      FilledButton(
                        key: const Key('story-open-profile'),
                        onPressed: () => context.push(
                          '/annonceur/${senegalLocalDigits(profile.phone)}',
                        ),
                        child: const Text('Voir le profil'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
