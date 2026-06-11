// Student Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';
import '../../theme/theme_provider.dart'; // ✨ Imported the theme engine
//import '../../widgets/mitra_glass_card.dart'; // ✨ Imported your glass component

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeTheme = ref.watch(themeProvider); // ✨ Watch the global theme

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Hero Section ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MitraSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), // Glass Hero
              border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(children: [
              Text(user?.avatarEmoji ?? '🎒',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(user?.fullName ?? '',
                  style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: MitraColors.textPrimary)),
              Text('${user?.classGrade ?? ''} · ${user?.assignedState ?? ''}',
                  style: const TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 13,
                      color: MitraColors.textMuted)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(MitraSpacing.lg),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Stats ──────────────────────────────────────────
              _StatCard(
                  emoji: '⭐',
                  label: 'Total XP',
                  value: '${user?.totalXp ?? 0}'),
              const SizedBox(height: 12),
              _StatCard(
                  emoji: '🔥',
                  label: 'Day Streak',
                  value: '${user?.currentStreakDays ?? 0}'),
              const SizedBox(height: 32),

              // ── Appearance / Theme Selector ────────────────────
              const Text('Appearance',
                  style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Column(
                children: MitraTheme.values.map((theme) {
                  final isSelected = activeTheme == theme;
                  final highlight = ThemeHelper.getActiveHighlight(theme);
                  final gradient = ThemeHelper.getBackgroundGradient(theme);

                  return GestureDetector(
                    onTap: () {
                      ref.read(themeProvider.notifier).state = theme;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? highlight.withValues(alpha: 0.1)
                            : Colors.white
                                .withValues(alpha: 0.05), // ✨ Glass tile
                        borderRadius: BorderRadius.circular(MitraRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? highlight
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LEFT: Checkmark & Theme Name
                          Row(
                            children: [
                              if (isSelected) ...[
                                Icon(Icons.check_circle,
                                    color: highlight, size: 20),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                ThemeHelper.getThemeName(theme),
                                style: TextStyle(
                                  fontFamily: 'Baloo2',
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          // RIGHT: Visual Color Samples
                          Row(
                            children: [
                              // Sample 1: The Background Gradient
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Sample 2: The Highlight/Active Color
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: highlight,
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // ── Sign Out ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: MitraColors.crimson,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MitraRadius.pill))),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: const Text('Sign Out',
                      style: TextStyle(
                          fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  const _StatCard(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(MitraSpacing.lg),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08), // Glass Card
            borderRadius: BorderRadius.circular(MitraRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Mukta',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: MitraColors.textSecondary))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: MitraColors.textPrimary)),
        ]),
      );
}
