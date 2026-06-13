// ═══════════════════════════════════════════════════════
// SCREEN: Quiz Screen — mirrors app/quiz/[quizId].tsx
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/mitra_scaffold.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

// 🛠️ BUG-008 FIX: Strict, type-safe model for Quiz Questions
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion.fromJson(Map<String, dynamic> json)
      : question = json['question'] as String,
        options = List<String>.from(json['options'] as List),
        correctIndex = json['correct'] as int;
}

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
        // 🛠️ BUG-008 FIX: Parse data into QuizQuestion objects safely
        final rawQuestions = res.data['questions'] as List<dynamic>?;
        if (rawQuestions != null) {
          _questions = rawQuestions
              .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
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

  // 🛠️ BUG-008 FIX: Mock data converted to typed objects
  static final _mockQuestions = [
    QuizQuestion.fromJson({
      'question': 'Which organelle is called the powerhouse of the cell?',
      'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
      'correct': 1,
    }),
    QuizQuestion.fromJson({
      'question': 'What is the chemical formula for water?',
      'options': ['CO2', 'H2O2', 'H2O', 'NaCl'],
      'correct': 2,
    }),
    QuizQuestion.fromJson({
      'question': 'How many planets are in our solar system?',
      'options': ['7', '8', '9', '10'],
      'correct': 1,
    }),
  ];

  void _selectAnswer(int idx) => setState(() => _selected = idx);

  void _next() {
    if (_selected == null) return;
    // 🛠️ BUG-008 FIX: Use typed getter
    final correct = _questions[_current].correctIndex;
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: MitraColors.bgDeep,
        body: Center(
            child: CircularProgressIndicator(color: MitraColors.saffron)),
      );
    }
    // 🛠️ BUG-008 FIX: Extract properties directly from the typed model
    final q = _questions[_current];
    final options = q.options;
    final progress = (_current + 1) / _questions.length;

    return MitraScaffold(
      //backgroundColor: MitraColors.bgDeep,
      appBar: AppBar(
        backgroundColor: MitraColors.bgCard,
        title: Text('Question ${_current + 1}/${_questions.length}',
            style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: MitraColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(Icons.close, color: MitraColors.textMuted),
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
              backgroundColor: MitraColors.bgSurface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(MitraColors.saffron),
            ),
          ),
          const SizedBox(height: MitraSpacing.xl),
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MitraSpacing.xl),
            decoration: BoxDecoration(
              color: MitraColors.bgCard,
              borderRadius: BorderRadius.circular(MitraRadius.lg),
              border: Border.all(color: MitraColors.border),
            ),
            child: Text(q.question, // 🛠️ BUG-008 FIX: Typed getter
                style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: MitraColors.textPrimary,
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
                        ? MitraColors.saffron.withValues(alpha: 0.15)
                        : MitraColors.bgCard,
                    borderRadius: BorderRadius.circular(MitraRadius.md),
                    border: Border.all(
                        color:
                            selected ? MitraColors.saffron : MitraColors.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? MitraColors.saffron
                            : MitraColors.bgSurface,
                        border: Border.all(
                            color: selected
                                ? MitraColors.saffron
                                : MitraColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(['A', 'B', 'C', 'D'][i],
                          style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : MitraColors.textMuted)),
                    ),
                    const SizedBox(width: 12),
                    // 🛠️ BUG-008 FIX: Typed getter doesn't need "as String"
                    Expanded(
                        child: Text(options[i],
                            style: TextStyle(
                                fontFamily: 'Mukta',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: selected
                                    ? MitraColors.saffron
                                    : MitraColors.textPrimary))),
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
                gradient: _selected != null
                    ? const LinearGradient(colors: MitraColors.gradientSaffron)
                    : null,
                color: _selected == null ? MitraColors.bgSurface : null,
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
                    color: _selected != null
                        ? Colors.white
                        : MitraColors.textMuted),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
