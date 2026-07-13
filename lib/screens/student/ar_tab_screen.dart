// AR Tab Screen — links to AR viewer
// Back button handled entirely by StudentShell
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';

class ArTabScreen extends StatelessWidget {
  const ArTabScreen({super.key});

  static const _topics = [
    {
      'emoji': '🔬',
      'name': 'Cell Division',
      'subject': 'Science',
      'id': 'cell-division'
    },
    {
      'emoji': '🌍',
      'name': 'Solar System',
      'subject': 'Geography',
      'id': 'solar-system'
    },
    {
      'emoji': '⚗️',
      'name': 'Atom Structure',
      'subject': 'Science',
      'id': 'atom-structure'
    },
    {
      'emoji': '🏛️',
      'name': 'Ancient Rome',
      'subject': 'History',
      'id': 'ancient-rome'
    },
    {
      'emoji': '🌊',
      'name': 'Ocean Layers',
      'subject': 'Geography',
      'id': 'ocean-layers'
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                Text('🥽', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AR Viewer',
                      style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: MitraColors.textPrimary)),
                  Text('Point & learn in augmented reality',
                      style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 12,
                          color: MitraColors.textMuted)),
                ]),
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
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final t = _topics[i];
                  return GestureDetector(
                    onTap: () => context.go('/ar/${t['id']}'),
                    child: Container(
                      padding: const EdgeInsets.all(MitraSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(MitraRadius.md),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Text(t['emoji'] as String,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(t['name'] as String,
                                  style: const TextStyle(
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: MitraColors.textPrimary)),
                              Text(t['subject'] as String,
                                  style: const TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: 12,
                                      color: MitraColors.textMuted)),
                            ])),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: MitraColors.gradientSaffron),
                                borderRadius:
                                    BorderRadius.circular(MitraRadius.pill)),
                            child: const Text('Launch AR',
                                style: TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.white))),
                      ]),
                    ),
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
