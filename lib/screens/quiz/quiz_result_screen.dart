// ═══════════════════════════════════════════════════════
// SCREEN: Quiz Result — mirrors app/quiz/result.tsx
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';

class QuizResultScreen extends StatelessWidget {
  final int score, total, xpEarned;
  const QuizResultScreen({super.key, required this.score, required this.total, required this.xpEarned});

  @override
  Widget build(BuildContext context) {
    final pct     = total > 0 ? (score / total * 100).toInt() : 0;
    final passed  = pct >= 60;
    final emoji   = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪';
    final message = pct >= 80 ? 'Excellent work!' : pct >= 60 ? 'Good job!' : 'Keep practising!';

    return Scaffold(
      backgroundColor: MitraColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MitraSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: MitraSpacing.lg),
              Text(message, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 28, color: MitraColors.textPrimary)),
              const SizedBox(height: MitraSpacing.xl),
              // Score ring
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: passed ? MitraColors.emerald : MitraColors.saffron, width: 6),
                ),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$pct%', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 36,
                      color: passed ? MitraColors.emerald : MitraColors.saffron)),
                  Text('$score/$total', style: const TextStyle(fontFamily: 'Mukta', fontSize: 14, color: MitraColors.textMuted)),
                ]),
              ),
              const SizedBox(height: MitraSpacing.xl),
              // XP chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: MitraColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(MitraRadius.pill),
                  border: Border.all(color: MitraColors.gold.withOpacity(0.4)),
                ),
                child: Text('+$xpEarned XP Earned!',
                    style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 18, color: MitraColors.gold)),
              ),
              const SizedBox(height: MitraSpacing.xl * 2),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => context.go('/student/home'),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: MitraColors.gradientSaffron),
                      borderRadius: BorderRadius.circular(MitraRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Back to Home', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/student/learn'),
                child: const Text('Try Another Quiz', style: TextStyle(fontFamily: 'Mukta', fontSize: 14, color: MitraColors.sky)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
