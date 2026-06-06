// Student Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(MitraSpacing.xl),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: MitraColors.gradientHero)),
            child: Column(children: [
              Text(user?.avatarEmoji ?? '🎒', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(user?.fullName ?? '', style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 22, color: MitraColors.textPrimary)),
              Text('${user?.classGrade ?? ''} · ${user?.assignedState ?? ''}', style: const TextStyle(fontFamily: 'Mukta', fontSize: 13, color: MitraColors.textMuted)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(MitraSpacing.lg),
            child: Column(children: [
              _StatCard(emoji: '⭐', label: 'Total XP', value: '${user?.totalXp ?? 0}'),
              const SizedBox(height: 12),
              _StatCard(emoji: '🔥', label: 'Day Streak', value: '${user?.currentStreakDays ?? 0}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: MitraColors.crimson, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MitraRadius.pill))),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: const Text('Sign Out', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
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
  const _StatCard({required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(MitraSpacing.lg),
    decoration: BoxDecoration(color: MitraColors.bgCard, borderRadius: BorderRadius.circular(MitraRadius.md), border: Border.all(color: MitraColors.border)),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w500, fontSize: 14, color: MitraColors.textSecondary))),
      Text(value, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 20, color: MitraColors.textPrimary)),
    ]),
  );
}
