// ═══════════════════════════════════════════════════════
// SCREEN: Quiz Screen — mirrors app/quiz/[quizId].tsx
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/mitra_scaffold.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
// ✨ Added our new central Architecture Imports
import '../../models/quiz_model.dart';
import '../../theme/theme_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  // 🛠️ BUG-008 FIX: Use the typed model instead of dynamic list
  List<QuizQuestion> _questions = [];
  int _current = 0;
  int? _selected;
  bool _loading = true;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final res = await QuizAPI.questions(widget.quizId);
      setState(() {
        final rawQuestions = res.data['questions'] as List<dynamic>?;
        if (rawQuestions != null) {
          // ✨ Maps your API JSON directly into our new global model!
          _questions = rawQuestions.map((q) {
            final map = q as Map<String, dynamic>;
            return QuizQuestion(
              questionText: map['question'] as String,
              options: List<String>.from(map['options'] as List),
              correctAnswerIndex: map['correct'] as int,
            );
          }).toList();
        } else {
          _questions = List.from(_mockQuestions);
        }
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _questions = List.from(_mockQuestions);
        _loading = false;
      });
    }
  }

  // ✨ Upgraded to match the new property names
  static final _mockQuestions = [
    const QuizQuestion(
      questionText: 'Which organelle is called the powerhouse of the cell?',
      options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
      correctAnswerIndex: 1,
    ),
    const QuizQuestion(
      questionText: 'What is the chemical formula for water?',
      options: ['CO2', 'H2O2', 'H2O', 'NaCl'],
      correctAnswerIndex: 2,
    ),
    const QuizQuestion(
      questionText: 'How many planets are in our solar system?',
      options: ['7', '8', '9', '10'],
      correctAnswerIndex: 1,
    ),
  ];

  void _selectAnswer(int idx) => setState(() => _selected = idx);

  void _next() {
    if (_selected == null) return;
    // ✨ Uses the new correctAnswerIndex property from the global model
    final correct = _questions[_current].correctAnswerIndex;
    if (_selected == correct) _score++;

    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
      });
    } else {
      final xpEarned = _score * 50;
      context.go('/quiz/result', extra: {
        'score': _score,
        'total': _questions.length,
        'xpEarned': xpEarned
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✨ Fetch the user's dynamic theme so the UI matches their preference!
    final activeTheme = ref.watch(themeProvider);
    final themeHighlight = ThemeHelper.getActiveHighlight(activeTheme);

    if (_loading) {
      return Scaffold(
        // Kept as standard Scaffold for pure loading state
        backgroundColor: MitraColors.bgDeep,
        body: Center(
          // ✨ Dynamic loading color
          child: CircularProgressIndicator(color: themeHighlight),
        ),
      );
    }

    final q = _questions[_current];
    final options = q.options;
    final progress = (_current + 1) / _questions.length;

    return MitraScaffold(
      // 🚨 backgroundColor permanently removed! The smart canvas handles it.
      appBar: AppBar(
        // ✨ Made transparent to let the global gradient & watermark shine!
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Question ${_current + 1}/${_questions.length}',
            style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white)), // White looks best on gradients
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(MitraSpacing.lg),
        child: Column(children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(MitraRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: MitraColors.bgSurface.withValues(alpha: 0.5),
              // ✨ Uses dynamic theme color instead of hardcoded Saffron
              valueColor: AlwaysStoppedAnimation<Color>(themeHighlight),
            ),
          ),
          const SizedBox(height: MitraSpacing.xl),
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MitraSpacing.xl),
            decoration: BoxDecoration(
              color: MitraColors.bgCard.withValues(
                  alpha: 0.8), // Slight transparency looks beautiful
              borderRadius: BorderRadius.circular(MitraRadius.lg),
              border:
                  Border.all(color: MitraColors.border.withValues(alpha: 0.2)),
            ),
            child: Text(q.questionText, // ✨ Updated to use new model property
                style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.4)),
          ),
          const SizedBox(height: MitraSpacing.lg),
          // Options
          ...List.generate(options.length, (i) {
            final selected = _selected == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectAnswer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(MitraSpacing.lg),
                  decoration: BoxDecoration(
                    color: selected
                        ? themeHighlight.withValues(
                            alpha: 0.15) // ✨ Dynamic Highlight
                        : MitraColors.bgCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(MitraRadius.md),
                    border: Border.all(
                        color: selected
                            ? themeHighlight
                            : MitraColors.border.withValues(alpha: 0.2),
                        width: selected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            selected ? themeHighlight : MitraColors.bgSurface,
                        border: Border.all(
                            color: selected
                                ? themeHighlight
                                : MitraColors.border.withValues(alpha: 0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(['A', 'B', 'C', 'D'][i],
                          style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: selected ? Colors.black : Colors.white70)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(options[i],
                            style: TextStyle(
                                fontFamily: 'Mukta',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color:
                                    selected ? themeHighlight : Colors.white))),
                  ]),
                ),
              ),
            );
          }),
          const Spacer(),
          // Next button
          GestureDetector(
            onTap: _selected != null ? _next : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                // ✨ Uses the dynamic theme color for the button
                color: _selected != null
                    ? themeHighlight
                    : MitraColors.bgSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(MitraRadius.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                _current < _questions.length - 1
                    ? 'Next Question →'
                    : 'Submit Quiz →',
                style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    // If button is highlighted, text becomes black for contrast
                    color: _selected != null ? Colors.black : Colors.white54),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
