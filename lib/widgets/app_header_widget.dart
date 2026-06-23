import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════
/// REUSABLE APP HEADER WIDGET
/// Matches home_screen.dart glass morphism design
/// ═══════════════════════════════════════════════════════

class AppHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showAvatar;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? extraContent;

  const AppHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.showAvatar = true,
    this.backgroundColor,
    this.borderColor,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04));

    final glassBorder = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08));

    final mainTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: glassBorder, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: back button + title/subtitle ──
              Expanded(
                child: Row(
                  children: [
                    if (showBackButton)
                      _BackButton(
                        color: mainTextColor,
                        isDark: isDark,
                        onTap:
                            onBackPressed ?? () => Navigator.of(context).pop(),
                      ),
                    Expanded(
                      child: _TitleBlock(
                        title: title,
                        subtitle: subtitle,
                        titleIcon: titleIcon,
                        mainTextColor: mainTextColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right: actions + avatar ──
              Row(
                children: [
                  if (actions != null) ...actions!,
                  if (showAvatar) ...[
                    const SizedBox(width: 12),
                    const _Avatar(),
                  ],
                ],
              ),
            ],
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 16),
            extraContent!,
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _BackButton({
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.arrow_back_ios_new, color: color, size: 18),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final Color mainTextColor;
  final Color mutedTextColor;

  const _TitleBlock({
    required this.title,
    required this.mainTextColor,
    required this.mutedTextColor,
    this.subtitle,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[
              Icon(titleIcon, color: mainTextColor, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: mainTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: 12,
              color: mutedTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFF59E0B), width: 2),
        ),
      ),
      alignment: Alignment.center,
      child: const Text('👤', style: TextStyle(fontSize: 24)),
    );
  }
}

// ── Common extra-content helpers ─────────────────────────

/// A hint chip shown below the header title.
class HeaderHintChip extends StatelessWidget {
  final String text;

  const HeaderHintChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Mukta',
          fontSize: 11,
          color: Color(0xFFFCD34D),
        ),
      ),
    );
  }
}

/// A question counter + animated progress bar.
class HeaderProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const HeaderProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question $current of $total',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.lerp(
                const Color(0xFF34D399),
                const Color(0xFFEF4444),
                progress,
              )!,
            ),
          ),
        ),
      ],
    );
  }
}

/// An AR readiness indicator row.
class HeaderARStatus extends StatelessWidget {
  final bool isSupported;

  const HeaderARStatus({super.key, required this.isSupported});

  @override
  Widget build(BuildContext context) {
    final color =
        isSupported ? const Color(0xFF34D399) : const Color(0xFFFCD34D);
    return Row(
      children: [
        Icon(
          isSupported ? Icons.check_circle : Icons.info,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          isSupported ? 'AR Ready' : 'View Only',
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// HEADER VARIANTS FOR COMMON SCREENS
// ═══════════════════════════════════════════════════════

class LearnScreenHeader extends StatelessWidget {
  final String subjectName;
  final String subjectEmoji;
  final VoidCallback onBackPressed;

  const LearnScreenHeader({
    super.key,
    required this.subjectName,
    required this.subjectEmoji,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeaderWidget(
      title: '$subjectEmoji $subjectName',
      subtitle: 'Chapter List',
      onBackPressed: onBackPressed,
      extraContent:
          const HeaderHintChip(text: '📚 Tap any topic to begin learning'),
    );
  }
}

class QuizScreenHeader extends StatelessWidget {
  final String quizName;
  final int questionNumber;
  final int totalQuestions;
  final VoidCallback onBackPressed;

  const QuizScreenHeader({
    super.key,
    required this.quizName,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeaderWidget(
      title: '🎯 Quiz',
      subtitle: quizName,
      onBackPressed: onBackPressed,
      extraContent: HeaderProgressBar(
        current: questionNumber,
        total: totalQuestions,
      ),
    );
  }
}

class ARScreenHeader extends StatelessWidget {
  final String modelName;
  final bool isARSupported;
  final VoidCallback onBackPressed;

  const ARScreenHeader({
    super.key,
    required this.modelName,
    required this.isARSupported,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeaderWidget(
      title: '🔮 AR Viewer',
      subtitle: modelName,
      onBackPressed: onBackPressed,
      extraContent: HeaderARStatus(isSupported: isARSupported),
    );
  }
}
