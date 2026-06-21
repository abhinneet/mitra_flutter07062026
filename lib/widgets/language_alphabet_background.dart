import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════
// BACKGROUND ANIMATION - Falling Language Alphabets
// Used globally across all screens
// ═══════════════════════════════════════════════════════

class LanguageAlphabetBackground extends ConsumerWidget {
  const LanguageAlphabetBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final accentColor = ThemeHelper.getActiveHighlight(theme);

    const particleCount = 15;
    const fontSizes = [
      36.0,
      32.0,
      40.0,
      30.0,
      38.0,
      34.0,
      42.0,
      28.0,
      37.0,
      33.0,
      39.0,
      31.0,
      41.0,
      35.0,
      36.0
    ];

    const durations = [
      12.0,
      14.0,
      11.0,
      13.5,
      15.0,
      12.5,
      13.0,
      14.5,
      11.5,
      15.5,
      12.0,
      13.0,
      14.0,
      11.0,
      12.5
    ];

    const delays = [
      0.0,
      1.5,
      3.0,
      4.5,
      6.0,
      0.8,
      2.3,
      3.8,
      5.3,
      6.8,
      1.2,
      2.7,
      4.2,
      5.7,
      0.5
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final positions = _scatterPositions(particleCount, w, h);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var i = 0; i < particleCount; i++)
              _LanguageAlphabetParticle(
                character: _characterFor(i),
                color: accentColor,
                left: positions[i].left,
                top: positions[i].top,
                fontSize: fontSizes[i],
                duration: durations[i],
                delay: delays[i],
              ),
          ],
        );
      },
    );
  }
}

// ── Helper Functions ────────────────────────────────────
const List<String> _kIndianLanguageAlphabets = [
  'अ', // Devanagari (Hindi)
  'অ', // Bengali
  'અ', // Gujarati
  'ਅ', // Gurmukhi (Punjabi)
  'ಅ', // Kannada
  'അ', // Malayalam
  'ଅ', // Odia
  'அ', // Tamil
  'అ', // Telugu
  'ا', // Urdu
];

String _characterFor(int index) =>
    _kIndianLanguageAlphabets[index % _kIndianLanguageAlphabets.length];

List<({double left, double top})> _scatterPositions(
  int count,
  double w,
  double h,
) {
  const phi = 0.6180339887;
  return List.generate(count, (i) {
    final frac = (i * phi) % 1.0;
    final left = frac < 0.5
        ? 0.30 * w + (frac * 0.40 * w)
        : 0.70 * w + ((frac - 0.5) * 0.30 * w);
    final top = (i / count) * h;
    return (left: left, top: top);
  });
}

// ── Language Alphabet Falling Particle ──────────────────
class _LanguageAlphabetParticle extends StatefulWidget {
  final Color color;
  final String character;
  final double left;
  final double top;
  final double fontSize;
  final double duration;
  final double delay;

  const _LanguageAlphabetParticle({
    required this.color,
    required this.character,
    required this.left,
    required this.top,
    required this.fontSize,
    required this.duration,
    required this.delay,
  });

  @override
  State<_LanguageAlphabetParticle> createState() =>
      _LanguageAlphabetParticleState();
}

class _LanguageAlphabetParticleState extends State<_LanguageAlphabetParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.duration * 1000).round()),
      vsync: this,
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.06), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.06), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: 0.0), weight: 20),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(
      Duration(milliseconds: (widget.delay * 1000).round()),
      () {
        if (mounted) _controller.repeat();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Positioned(
        left: widget.left,
        top: widget.top + (_controller.value * 500),
        child: Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Text(
              widget.character,
              style: TextStyle(
                fontSize: widget.fontSize,
                color: widget.color,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
