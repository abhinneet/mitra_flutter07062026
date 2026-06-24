import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

// ═══════════════════════════════════════════════════════
// BACKGROUND ANIMATION - Falling Language Alphabets
// Used globally across all screens
// ═══════════════════════════════════════════════════════

class LanguageAlphabetBackground extends ConsumerWidget {
  const LanguageAlphabetBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final accentColor = ThemeHelper.getActiveHighlight(theme);

    const particleCount = 15;
    const fontSizes = [
      40.5,
      36.0,
      45.0,
      33.75,
      42.75,
      38.25,
      47.25,
      31.5,
      41.625,
      37.125,
      43.875,
      34.875,
      46.125,
      39.375,
      40.5
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
  'अ', // 1.  Hindi      (Devanagari)
  'অ', // 2.  Bengali    (Bengali script)
  'અ', // 3.  Gujarati   (Gujarati script)
  'ਅ', // 4.  Punjabi    (Gurmukhi script)
  'ಅ', // 5.  Kannada    (Kannada script)
  'അ', // 6.  Malayalam  (Malayalam script)
  'ଅ', // 7.  Odia       (Odia script)
  'அ', // 8.  Tamil      (Tamil script)
  'అ', // 9.  Telugu     (Telugu script)
  'ৰ', // 11. Assamese   (Assamese script — unique letter ৰ, distinct from Bengali)
  'ম', // 12. Marathi    (Devanagari — using ম to distinguish from Hindi अ)
  'ञ', // 13. Nepali     (Devanagari — using ञ to distinguish from Hindi अ)
  'ꯑ', // 14. Meitei     (Meitei Mayek script — correct)
  'ᱚ', // 15. Santali    (Ol Chiki script — correct)
  'ಕ', // 16. Konkani    (also written in Kannada script in Goa region)
  'کٲ', // 17. Kashmiri   (Nastaliq — کٲ is the correct Kashmiri opener)
  'ਡ', // 18. Dogri      (Dogri uses Takri/Devanagari — ਡ in its Gurmukhī variant)
  'मै', // 19. Maithili   (Devanagari — मै is the distinctive opener)
  'س', // 20. Sindhi     (Arabic script — correct)
  'ব', // 21. Bodo       (Devanagari/Bengali — ব in Bengali-based Bodo script)
  'ॐ', // 22. Sanskrit   (Devanagari — ॐ is iconic for Sanskrit)
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
    final left = frac * w; // Evenly spread across full width (0 to 100%)
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
