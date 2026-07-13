// Ranks / Leaderboard Screen
// Back button handled entirely by StudentShell
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';

class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  static const _leaders = [
    {
      'rank': 1,
      'emoji': '🥇',
      'name': 'You',
      'xp': 1240,
      'streak': 12,
      'me': true
    },
    {
      'rank': 2,
      'emoji': '🥈',
      'name': 'Rahul S.',
      'xp': 980,
      'streak': 8,
      'me': false
    },
    {
      'rank': 3,
      'emoji': '🥉',
      'name': 'Priya M.',
      'xp': 860,
      'streak': 6,
      'me': false
    },
    {
      'rank': 4,
      'emoji': '4️⃣',
      'name': 'Arjun K.',
      'xp': 720,
      'streak': 5,
      'me': false
    },
    {
      'rank': 5,
      'emoji': '5️⃣',
      'name': 'Divya R.',
      'xp': 680,
      'streak': 4,
      'me': false
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // ── NO PopScope — StudentShell.BackButtonListener handles ALL back logic ──
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(MitraSpacing.lg),
              child: const Row(children: [
                Text('🏆', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text('Leaderboard',
                    style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: MitraColors.textPrimary)),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                // ✨ Auto-calculates the bottom glass bar thickness
                padding: EdgeInsets.fromLTRB(
                  MitraSpacing.lg,
                  MitraSpacing.lg,
                  MitraSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + MitraSpacing.lg,
                ),
                itemCount: _leaders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final l = _leaders[i];
                  final isMe = l['me'] as bool;
                  return Container(
                    padding: const EdgeInsets.all(MitraSpacing.md),
                    decoration: BoxDecoration(
                      color: isMe
                          ? MitraColors.saffron.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(MitraRadius.md),
                      border: Border.all(
                          color: isMe
                              ? MitraColors.saffron.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Text(l['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                isMe
                                    ? (user?.firstName ?? 'You')
                                    : l['name'] as String,
                                style: const TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: MitraColors.textPrimary)),
                            Text('🔥 ${l['streak']} day streak',
                                style: const TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 12,
                                    color: MitraColors.textMuted)),
                          ])),
                      Text('${l['xp']} XP',
                          style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: MitraColors.gold)),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
