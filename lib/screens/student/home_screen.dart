// ═══════════════════════════════════════════════════════
// SCREEN S-05: Student Home Dashboard
// Mirrors app/student/home.tsx from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';
import '../../services/api_service.dart'; // 🛠️ BUG-009 FIX: Added ApiService

// 🛠️ BUG-009 FIX: Riverpod provider to securely fetch real subjects from the server
final subjectsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await CurriculumAPI.tree();
    final rawSubjects = res.data['subjects'] as List<dynamic>? ?? [];

    // Fallback colors to keep the UI looking nice
    final colors = [
      const Color(0x267C5CDD),
      const Color(0x2600C389),
      const Color(0x26FFB800),
      const Color(0x260EA5E9)
    ];

    return List.generate(rawSubjects.length, (i) {
      final s = rawSubjects[i] as Map<String, dynamic>;
      return {
        'emoji': s['emoji'] ?? '📚',
        'name': s['name'] ?? 'Subject',
        'progress': (s['progress'] as num?)?.toDouble() ?? 0.0,
        'ar': s['ar'] ?? s['ar_topics_count'] ?? 0,
        'color': colors[i % colors.length],
      };
    });
  } catch (_) {
    return []; // Return an empty list if the API fails
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // 🛠️ BUG-009 FIX: Removed the hardcoded mock _subjects array

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user?.firstName ?? 'Student';

    // 🛠️ BUG-009 FIX: Listen to the dynamic subjects data we created at the top
    final subjectsAsync = ref.watch(subjectsProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────
          Container(
            color: MitraColors.bgCard,
            padding: const EdgeInsets.all(MitraSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 12,
                                color: MitraColors.textMuted)),
                        Text('$firstName 👋',
                            style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: MitraColors.textPrimary)),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MitraColors.bgSurface,
                        border:
                            Border.all(color: MitraColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(user?.avatarEmoji ?? '🎒',
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Class chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MitraColors.saffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                    border: Border.all(
                        color: MitraColors.saffron.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🏫 ${user?.classGrade ?? "Class IX"} · ${user?.assignedState ?? "India"}',
                    style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: MitraColors.saffron),
                  ),
                ),
                const SizedBox(height: 8),
                // Stats row
                Row(
                  children: [
                    _StatChip('🔥 ${user?.currentStreakDays ?? 0} day streak'),
                    const SizedBox(width: 8),
                    _StatChip('⭐ ${user?.totalXp ?? 0} XP'),
                    const SizedBox(width: 8),
                    const _StatChip('🥇 #1 in class'),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  // Continue Learning
                  _Section(
                    title: 'Continue Learning',
                    trailing: const Text('See all',
                        style: TextStyle(
                            fontSize: 12,
                            color: MitraColors.saffron,
                            fontFamily: 'Mukta')),
                    child: _ContinueLearningCard(),
                  ),

                  // 🛠️ BUG-009 FIX: Subjects grid dynamically fetched from API with loading states
                  _Section(
                    title: 'Subjects',
                    child: subjectsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: MitraColors.saffron)),
                      ),
                      error: (err, stack) => const Text(
                          'Failed to load subjects',
                          style: TextStyle(color: MitraColors.textMuted)),
                      data: (subjects) => subjects.isEmpty
                          ? const Text('No subjects found.',
                              style: TextStyle(color: MitraColors.textMuted))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: subjects.length,
                              itemBuilder: (ctx, i) {
                                final s = subjects[i];
                                return GestureDetector(
                                  onTap: () => context.go('/student/learn'),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(MitraSpacing.md),
                                    decoration: BoxDecoration(
                                      color: s['color'] as Color,
                                      borderRadius:
                                          BorderRadius.circular(MitraRadius.md),
                                      border: Border.all(
                                          color: MitraColors.borderLight),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s['emoji'] as String,
                                            style:
                                                const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 6),
                                        Text(s['name'] as String,
                                            style: const TextStyle(
                                                fontFamily: 'Baloo2',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color:
                                                    MitraColors.textPrimary)),
                                        Text(
                                            '${((s['progress'] as double) * 100).toInt()}% · ${s['ar']} AR topics',
                                            style: const TextStyle(
                                                fontFamily: 'Mukta',
                                                fontSize: 10,
                                                color: MitraColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Quick Actions
                  _Section(
                    title: 'Quick Actions',
                    child: Row(
                      children: [
                        _QuickAction(
                            emoji: '🥽',
                            label: 'Open AR',
                            onTap: () => context.go('/student/ar')),
                        _QuickAction(
                            emoji: '📝',
                            label: 'Take Quiz',
                            onTap: () => context.go('/student/learn')),
                        _QuickAction(
                            emoji: '🏆',
                            label: 'Leaderboard',
                            onTap: () => context.go('/student/ranks')),
                        _QuickAction(
                            emoji: '📴',
                            label: 'Download',
                            onTap: () => context.go('/student/learn')),
                      ],
                    ),
                  ),

                  // Class Rank
                  _Section(
                    title: 'Class Rank',
                    trailing: GestureDetector(
                      onTap: () => context.go('/student/ranks'),
                      child: const Text('View all',
                          style: TextStyle(
                              fontSize: 12,
                              color: MitraColors.saffron,
                              fontFamily: 'Mukta')),
                    ),
                    child: Column(
                      children: [
                        _RankRow(
                            rank: '🥇',
                            name: firstName,
                            xp: user?.totalXp ?? 1200,
                            isMe: true),
                        const SizedBox(height: 8),
                        const _RankRow(
                            rank: '🥈', name: 'Rahul S.', xp: 980, isMe: false),
                        const SizedBox(height: 8),
                        const _RankRow(
                            rank: '🥉', name: 'Priya M.', xp: 860, isMe: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String text;
  const _StatChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: MitraColors.bgSurface,
          borderRadius: BorderRadius.circular(MitraRadius.pill),
          border: Border.all(color: MitraColors.border),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: MitraColors.textSecondary)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _Section({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: MitraColors.textPrimary)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _ContinueLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: MitraColors.bgCard,
          borderRadius: BorderRadius.circular(MitraRadius.md),
          border: Border.all(color: MitraColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 3,
                decoration: const BoxDecoration(
                  color: MitraColors.saffron,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(MitraRadius.md),
                      topRight: Radius.circular(MitraRadius.md)),
                )),
            Padding(
              padding: const EdgeInsets.all(MitraSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SCIENCE · CHAPTER 3',
                      style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 10,
                          color: MitraColors.textMuted,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  const Text('Microscopy & Cell Structure',
                      style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: MitraColors.textPrimary)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 5,
                      backgroundColor: MitraColors.bgSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          MitraColors.saffron),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('13/20 topics',
                          style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: 12,
                              color: MitraColors.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MitraColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(MitraRadius.pill),
                          border: Border.all(
                              color: MitraColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: const Text('+240 XP',
                            style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: MitraColors.gold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(MitraSpacing.md),
            decoration: BoxDecoration(
              color: MitraColors.bgCard,
              borderRadius: BorderRadius.circular(MitraRadius.sm),
              border: Border.all(color: MitraColors.border),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: MitraColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
}

class _RankRow extends StatelessWidget {
  final String rank;
  final String name;
  final int xp;
  final bool isMe;
  const _RankRow(
      {required this.rank,
      required this.name,
      required this.xp,
      required this.isMe});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(MitraSpacing.sm),
        decoration: BoxDecoration(
          color: isMe
              ? MitraColors.saffron.withValues(alpha: 0.1)
              : MitraColors.bgCard,
          borderRadius: BorderRadius.circular(MitraRadius.sm),
          border: Border.all(
              color: isMe
                  ? MitraColors.saffron.withValues(alpha: 0.3)
                  : MitraColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 32,
                child: Text(rank, style: const TextStyle(fontSize: 20))),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: MitraColors.textPrimary))),
            Text('$xp XP',
                style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: MitraColors.gold)),
          ],
        ),
      );
}
