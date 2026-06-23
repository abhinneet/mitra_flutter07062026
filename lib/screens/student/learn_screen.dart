// ═══════════════════════════════════════════════════════
// SCREEN: Learn Screen — Curriculum tree + AR topics
// Back button handled entirely by StudentShell
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header_widget.dart';

final curriculumProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await CurriculumAPI.tree();
  return res.data['subjects'] as List<dynamic>? ?? [];
});

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  static const _subjects = [
    {'emoji': '🔬', 'name': 'Science', 'chapters': 8, 'arTopics': 12},
    {'emoji': '📐', 'name': 'Maths', 'chapters': 10, 'arTopics': 8},
    {'emoji': '🏛️', 'name': 'History', 'chapters': 6, 'arTopics': 6},
    {'emoji': '🌍', 'name': 'Geography', 'chapters': 7, 'arTopics': 5},
    {'emoji': '🔠', 'name': 'English', 'chapters': 9, 'arTopics': 3},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── NO PopScope — StudentShell.BackButtonListener handles ALL back logic ──
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LearnScreenHeader(
            subjectName: 'All Subjects',
            subjectEmoji: '📚',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(MitraSpacing.lg),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final s = _subjects[i];
                return Container(
                  padding: const EdgeInsets.all(MitraSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(MitraRadius.md),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(s['emoji'] as String,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] as String,
                                style: const TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: MitraColors.textPrimary)),
                            Text(
                                '${s['chapters']} chapters · ${s['arTopics']} AR topics',
                                style: const TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 12,
                                    color: MitraColors.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MitraColors.saffron.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(MitraRadius.pill),
                          border: Border.all(
                              color:
                                  MitraColors.saffron.withValues(alpha: 0.3)),
                        ),
                        child: const Text('AR',
                            style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                color: MitraColors.saffron)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
