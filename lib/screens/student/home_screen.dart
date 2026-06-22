// ═══════════════════════════════════════════════════════
// SCREEN S-05: Student Home Dashboard
// Back button handled entirely by StudentShell
// Background animation moved to lib/widgets/language_alphabet_background.dart
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../constants/colors.dart';
import '../../stores/auth_store.dart';
import '../../services/api_service.dart';
import '../../stores/offline_store.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/word_bank_service.dart';
import '../../services/sentence_generator_service.dart';
import '../../theme/theme_provider.dart';
import '../../services/quotes_service.dart';

// ═══════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════

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

// ── TTS Instance ────────────────────────────────────────
final flutterTts = FlutterTts();

// ── Word Data Model ─────────────────────────────────────
class WordData {
  final String word, meaning, usage, partOfSpeech;
  final String difficulty;
  late final String generatedUsage;

  WordData({
    required this.word,
    required this.meaning,
    required this.usage,
    required this.partOfSpeech,
    this.difficulty = 'intermediate',
  }) {
    generatedUsage = usage.isNotEmpty ? usage : '';
  }

  factory WordData.fromJson(Map<String, dynamic> json) {
    return WordData(
      word: json['word'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'intermediate',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'usage': usage,
        'partOfSpeech': partOfSpeech,
        'difficulty': difficulty,
      };
}

// ═══════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════

final dailyMotivationProvider = FutureProvider<String>((ref) async {
  return QuotesService.instance.getQuoteOfDay().quote;
});

final quoteAuthorProvider = FutureProvider<String>((ref) async {
  return QuotesService.instance.getQuoteOfDay().author;
});

final quoteProfessionProvider = FutureProvider<String>((ref) async {
  return QuotesService.instance.getQuoteOfDay().profession;
});

final wordOfTheDayProvider = FutureProvider<WordData>((ref) async {
  return WordBankService().getWordOfDay();
});

final wordSearchProvider =
    FutureProvider.family<List<WordData>, String>((ref, query) async {
  return WordBankService().searchWords(query);
});

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

// ═══════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _wordSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage('hi');
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text, {String? language}) async {
    final lang = language ?? 'hi';
    await flutterTts.setLanguage(lang);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _wordSearchController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
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
                  // Thought for the Day
                  const SizedBox(height: 8),
                  ref.watch(dailyMotivationProvider).when(
                        loading: () => const _LoadingCard(),
                        error: (err, st) => const _ErrorCard('Failed to load'),
                        data: (thought) => _ThoughtTile(
                          thought: thought,
                          onSpeak: () => _speak(thought, language: 'hi'),
                        ),
                      ),

                  // 📖Word of the Day
                  const SizedBox(height: 8),
                  ref.watch(wordOfTheDayProvider).when(
                        loading: () => const _LoadingCard(),
                        error: (err, st) => const _ErrorCard('Failed to load'),
                        data: (word) => _WordOfDayTile(
                          word: word,
                          wordSearchController: _wordSearchController,
                          onSpeak: _speak,
                        ),
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

                  // Continue Learning
                  const _Section(
                    title: 'Continue Learning',
                    trailing: Text('See all',
                        style: TextStyle(
                            fontSize: 12,
                            color: MitraColors.saffron,
                            fontFamily: 'Mukta')),
                    child: _ContinueLearningCard(),
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

// ═══════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════

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

class _MotivationCard extends ConsumerWidget {
  final String thought;
  final VoidCallback onSpeak;

  const _MotivationCard({required this.thought, required this.onSpeak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(quoteAuthorProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(thought,
          style: const TextStyle(
              fontFamily: 'Courgette',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: MitraColors.textPrimary,
              height: 1.8,
              letterSpacing: 0.5)),
      const SizedBox(height: 8),
      authorAsync.when(
        loading: () => const Text(
          '— Loading...',
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: 11,
            color: MitraColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        error: (_, __) => const Text(
          '— Anonymous',
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: 11,
            color: MitraColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        data: (author) => Text(
          '— $author',
          style: const TextStyle(
            fontFamily: 'Mukta',
            fontSize: 11,
            color: MitraColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      const SizedBox(height: 12),
      IconButton(
          icon:
              const Icon(Icons.volume_up, color: MitraColors.saffron, size: 22),
          onPressed: onSpeak,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints()),
    ]);
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
          child: CircularProgressIndicator(color: MitraColors.saffron)));
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(message, style: TextStyle(color: Colors.red[300])));
}

// ── Thought Tile ───────────────────────────────────────
class _ThoughtTile extends ConsumerWidget {
  final String thought;
  final VoidCallback onSpeak;

  const _ThoughtTile({
    required this.thought,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final accentColor = ThemeHelper.getActiveHighlight(theme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💭 Thought for the day',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: MitraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _MotivationCard(
              thought: thought,
              onSpeak: onSpeak,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Word of Day Tile with 📖 Rain ───────────────────────
class _WordOfDayTile extends ConsumerWidget {
  final WordData word;
  final TextEditingController wordSearchController;
  final Function(String, {String? language}) onSpeak;

  const _WordOfDayTile({
    required this.word,
    required this.wordSearchController,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final accentColor = ThemeHelper.getActiveHighlight(theme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖WORD OF THE DAY',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: MitraColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _WordOfDayContent(
                  word: word,
                  wordSearchController: wordSearchController,
                  onSpeak: onSpeak,
                  accentColor: accentColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Word of Day Content (word display + meaning + usage + search) ──
class _WordOfDayContent extends StatefulWidget {
  final WordData word;
  final TextEditingController wordSearchController;
  final Function(String, {String? language}) onSpeak;
  final Color accentColor;

  const _WordOfDayContent({
    required this.word,
    required this.wordSearchController,
    required this.onSpeak,
    required this.accentColor,
  });

  @override
  State<_WordOfDayContent> createState() => _WordOfDayContentState();
}

class _WordOfDayContentState extends State<_WordOfDayContent> {
  bool _isSearchExpanded = false;
  String _searchQuery = '';
  List<WordData> _searchResults = [];
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    setState(() => _isSearchExpanded = _searchFocus.hasFocus);
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = [];
        _isSearching = false;
        return;
      }
      _isSearching = true;
    });

    if (query.isEmpty) return;

    // Debounce: wait 300ms before searching
    await Future.delayed(const Duration(milliseconds: 300));

    // If query changed during delay, skip stale result
    if (query != _searchQuery) return;

    final results = await WordBankService().searchWords(query);

    if (mounted && query == _searchQuery) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.word.word,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        color: widget.accentColor,
                      ),
                    ),
                    Text(
                      widget.word.partOfSpeech,
                      style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 11,
                        color: MitraColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.volume_up, color: widget.accentColor, size: 24),
                onPressed: () => widget.onSpeak(widget.word.word),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Usage Sentence
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usage:',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.word.usage,
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: MitraColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearchExpanded ? 52 : 40,
            child: TextField(
              controller: widget.wordSearchController,
              focusNode: _searchFocus,
              style: const TextStyle(
                fontFamily: 'Mukta',
                color: MitraColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                hintStyle: const TextStyle(
                  color: MitraColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.accentColor,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: MitraColors.textMuted, size: 16),
                        onPressed: () {
                          widget.wordSearchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.accentColor,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search Results
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No results for "$_searchQuery"',
                  style: const TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 12,
                    color: MitraColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.2)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, i) {
                    final result = _searchResults[i];
                    return InkWell(
                      onTap: () => widget.onSpeak(result.word),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.word,
                                    style: TextStyle(
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                  Text(
                                    result.meaning,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: 11,
                                      color: MitraColors.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.volume_up,
                                size: 16, color: widget.accentColor),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      );
}
