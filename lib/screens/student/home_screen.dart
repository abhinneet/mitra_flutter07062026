// ═══════════════════════════════════════════════════════
// SCREEN S-05: Student Home Dashboard
// Back button handled entirely by StudentShell
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';
import '../../services/api_service.dart';
import '../../stores/offline_store.dart';

class Subject {
  final String emoji;
  final String name;
  final double progress;
  final int arCount;
  final Color color;

  const Subject({
    required this.emoji,
    required this.name,
    required this.progress,
    required this.arCount,
    required this.color,
  });

  factory Subject.fromJson(Map<String, dynamic> json, Color color) {
    return Subject(
      emoji: json['emoji'] as String? ?? '📚',
      name: json['name'] as String? ?? 'Subject',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      arCount: (json['ar'] ?? json['ar_topics_count'] ?? 0) as int,
      color: color,
    );
  }
}

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final res = await CurriculumAPI.tree();
  final rawSubjects = res.data['subjects'] as List<dynamic>? ?? [];

  const colors = [
    Color(0x267C5CDD),
    Color(0x2600C389),
    Color(0x26FFB800),
    Color(0x260EA5E9),
  ];

  return [
    for (var i = 0; i < rawSubjects.length; i++)
      Subject.fromJson(
        rawSubjects[i] as Map<String, dynamic>,
        colors[i % colors.length],
      ),
  ];
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    final subjectsAsync = ref.watch(subjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);
    final mainTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white70 : Colors.black54;

    // ── NO PopScope here — StudentShell.BackButtonListener handles ALL back logic ──
    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(color: glassBorder, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: 15,
                              color: mutedTextColor),
                        ),
                        Text(
                          '$firstName 👋',
                          style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              color: mainTextColor),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded,
                              color: mainTextColor, size: 28),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            border: Border.all(
                                color: MitraColors.saffron, width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(user?.avatarEmoji ?? '🎒',
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Class chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: MitraColors.saffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                    border: Border.all(
                        color: MitraColors.saffron.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '🏫 ${user?.classGrade ?? "Class IX"} · ${user?.assignedState ?? "India"}',
                    style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: MitraColors.saffron),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _StatChip('🔥 ${user?.currentStreakDays ?? 0} day streak',
                        isDark),
                    const SizedBox(width: 8),
                    _StatChip('⭐ ${user?.totalXp ?? 0} XP', isDark),
                    const SizedBox(width: 8),
                    _StatChip('🥇 #1 in class', isDark),
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
                    child: const _ContinueLearningCard(),
                  ),

                  // Subjects
                  _Section(
                    title: 'Subjects',
                    child: subjectsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: MitraColors.saffron)),
                      ),
                      error: (err, stack) => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Failed to load subjects',
                            style: TextStyle(color: MitraColors.textMuted)),
                      ),
                      data: (subjects) => subjects.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No subjects found.',
                                  style:
                                      TextStyle(color: MitraColors.textMuted)),
                            )
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
                              itemBuilder: (ctx, i) =>
                                  _SubjectCard(subject: subjects[i]),
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
                            onTap: () => context.go('/student/quiz')),
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
  final bool isDark;
  const _StatChip(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(MitraRadius.pill),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Text(text,
            style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87)),
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
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(MitraRadius.sm),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 5,
                      backgroundColor: MitraColors.bgSurface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(MitraColors.saffron),
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

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go('/student/learn'),
        child: Container(
          padding: const EdgeInsets.all(MitraSpacing.md),
          decoration: BoxDecoration(
            color: subject.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MitraRadius.md),
            border: Border.all(color: MitraColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(subject.name,
                  style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: MitraColors.textPrimary)),
              Text(
                  '${(subject.progress * 100).toInt()}% · ${subject.arCount} AR topics',
                  style: const TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 10,
                      color: MitraColors.textMuted)),
            ],
          ),
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
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(MitraRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
              ? MitraColors.saffron.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
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
