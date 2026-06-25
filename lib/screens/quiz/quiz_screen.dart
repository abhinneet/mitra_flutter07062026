// ═══════════════════════════════════════════════════════
// SCREEN: Quiz Screen
// Features: answer reveal, explanation, dot indicators,
//           locked options after answer, question review
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/mitra_scaffold.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../models/quiz_model.dart';
import '../../theme/theme_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../stores/auth_store.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _current = 0;
  int? _selected;
  bool _loading = true;
  int _score = 0;
  bool _answered = false;
  DateTime _quizStartTime = DateTime.now();
  DateTime _questionStartTime = DateTime.now();

  final List<int?> _studentAnswers = [];
  final List<Map<String, dynamic>> _mcqResponses = [];

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
          _questions = rawQuestions.map((q) {
            final map = q as Map<String, dynamic>;
            // Backend returns option_a..option_d + correct_answer as "A"/"B"/"C"/"D"
            final options = [
              map['option_a'] as String? ?? '',
              map['option_b'] as String? ?? '',
              map['option_c'] as String? ?? '',
              map['option_d'] as String? ?? '',
            ];
            final correctLetter =
                (map['correct_answer'] as String? ?? 'A').toUpperCase();
            final correctIndex = ['A', 'B', 'C', 'D'].indexOf(correctLetter);
            return QuizQuestion(
              questionText: map['question_text'] as String? ?? '',
              options: options,
              correctAnswerIndex: correctIndex < 0 ? 0 : correctIndex,
              explanation: map['explanation'] as String?,
            );
          }).toList();
        } else {
          _questions = List.from(_mockQuestions);
        }
        _studentAnswers.addAll(List.filled(_questions.length, null));
        _loading = false;
        _quizStartTime = DateTime.now();
      });
    } catch (_) {
      setState(() {
        _questions = List.from(_mockQuestions);
        _studentAnswers.addAll(List.filled(_questions.length, null));
        _loading = false;
        _quizStartTime = DateTime.now();
      });
    }
  }

  static final _mockQuestions = [
    const QuizQuestion(
      questionText: 'Which organelle is called the powerhouse of the cell?',
      options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
      correctAnswerIndex: 1,
      explanation:
          'The mitochondria produces ATP energy for the cell through cellular respiration.',
    ),
    const QuizQuestion(
      questionText: 'What is the chemical formula for water?',
      options: ['CO2', 'H2O2', 'H2O', 'NaCl'],
      correctAnswerIndex: 2,
      explanation: 'Water is made of 2 hydrogen atoms and 1 oxygen atom — H2O.',
    ),
    const QuizQuestion(
      questionText: 'How many planets are in our solar system?',
      options: ['7', '8', '9', '10'],
      correctAnswerIndex: 1,
      explanation:
          'There are 8 planets. Pluto was reclassified as a dwarf planet in 2006.',
    ),
  ];

  // Called when student taps an option — locks in the answer and reveals result
  void _selectAnswer(int idx) {
    if (_answered) return;
    final timeMs = DateTime.now().difference(_questionStartTime).inMilliseconds;
    final isCorrect = idx == _questions[_current].correctAnswerIndex;
    setState(() {
      _selected = idx;
      _answered = true;
      _studentAnswers[_current] = idx;
      if (isCorrect) _score++;
      _mcqResponses.add({
        'question_id': 'q${_current + 1}',
        'answer': ['A', 'B', 'C', 'D'][idx],
        'correct': isCorrect,
        'time_ms': timeMs,
      });
    });
  }

  void _next() {
    if (!_answered) return;

    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
        _questionStartTime = DateTime.now();
      });
    } else {
      // Submit
      final durationSeconds =
          DateTime.now().difference(_quizStartTime).inSeconds;
      final xpEarned = _score * 50;

      // Backend submit (fire and forget)
      final user = ref.read(currentUserProvider);
      // POST /api/quiz/attempts — PostgreSQL path (no auth required)
      unawaited(QuizAPI.submit({
        'quiz_id': widget.quizId,
        'student_id': user?.id ?? 'anonymous',
        'state': user?.assignedState ?? '',
        'district': user?.assignedDistrict ?? '',
        'class_grade': user?.classGrade ?? '',
        'score': _score,
        'max_score': _questions.length,
        'questions_attempted': _questions.length,
        'correct_answers': _score,
        'time_taken_secs': durationSeconds,
        'completed': true,
        'app_language': user?.languagePreference ?? 'en',
      }));

      // Firestore telemetry path — per-question breakdown → BigQuery
      final telemetry = ref.read(telemetryServiceProvider);
      if (telemetry != null) {
        unawaited(telemetry.logQuizSubmit(
          quizId: widget.quizId,
          quizTitle: widget.quizId,
          correctAnswers: _score,
          totalQuestions: _questions.length,
          durationSeconds: durationSeconds,
          completed: true,
          mcqResponses: _mcqResponses,
        ));
      }

      context.go('/quiz/result', extra: {
        'score': _score,
        'total': _questions.length,
        'xpEarned': xpEarned,
        'quizId': widget.quizId,
        'questions': _questions,
        'studentAnswers': _studentAnswers,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = ref.watch(themeProvider);
    final themeHighlight = ThemeHelper.getActiveHighlight(activeTheme);

    if (_loading) {
      return Scaffold(
        backgroundColor: MitraColors.bgDeep,
        body: Center(
          child: CircularProgressIndicator(color: themeHighlight),
        ),
      );
    }

    final q = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return MitraScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Question ${_current + 1}/${_questions.length}',
          style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white),
        ),
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            MitraSpacing.lg, 0, MitraSpacing.lg, MitraSpacing.lg),
        child: Column(
          children: [
            // ── Progress bar ──────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(MitraRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: MitraColors.bgSurface.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(themeHighlight),
              ),
            ),

            const SizedBox(height: 12),

            // ── Question dot indicators ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_questions.length, (i) {
                Color dotColor;
                if (i < _current) {
                  // Already answered
                  final wasCorrect =
                      _studentAnswers[i] == _questions[i].correctAnswerIndex;
                  dotColor =
                      wasCorrect ? MitraColors.emerald : MitraColors.crimson;
                } else if (i == _current) {
                  dotColor = themeHighlight;
                } else {
                  dotColor = Colors.white.withValues(alpha: 0.2);
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                  ),
                );
              }),
            ),

            const SizedBox(height: MitraSpacing.lg),

            // ── Scrollable content ────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(MitraSpacing.xl),
                      decoration: BoxDecoration(
                        color: MitraColors.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(MitraRadius.lg),
                        border: Border.all(
                            color: MitraColors.border.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        q.questionText,
                        style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.4),
                      ),
                    ),

                    const SizedBox(height: MitraSpacing.lg),

                    // ── Options ───────────────────────
                    ...List.generate(q.options.length, (i) {
                      final isSelected = _selected == i;
                      final isCorrect = i == q.correctAnswerIndex;
                      final showResult = _answered;

                      // Determine tile color after answer reveal
                      Color borderColor;
                      Color bgColor;
                      Color textColor;
                      Color letterBg;
                      Color letterText;

                      if (!showResult) {
                        // Pre-answer state
                        borderColor = isSelected
                            ? themeHighlight
                            : MitraColors.border.withValues(alpha: 0.2);
                        bgColor = isSelected
                            ? themeHighlight.withValues(alpha: 0.15)
                            : MitraColors.bgCard.withValues(alpha: 0.5);
                        textColor = isSelected ? themeHighlight : Colors.white;
                        letterBg =
                            isSelected ? themeHighlight : MitraColors.bgSurface;
                        letterText = isSelected ? Colors.black : Colors.white70;
                      } else if (isCorrect) {
                        // Correct answer — always green
                        borderColor = MitraColors.emerald;
                        bgColor = MitraColors.emerald.withValues(alpha: 0.15);
                        textColor = MitraColors.emerald;
                        letterBg = MitraColors.emerald;
                        letterText = Colors.white;
                      } else if (isSelected && !isCorrect) {
                        // Wrong selection — red
                        borderColor = MitraColors.crimson;
                        bgColor = MitraColors.crimson.withValues(alpha: 0.12);
                        textColor = MitraColors.crimson;
                        letterBg = MitraColors.crimson;
                        letterText = Colors.white;
                      } else {
                        // Other unselected options — dim out
                        borderColor = MitraColors.border.withValues(alpha: 0.1);
                        bgColor = MitraColors.bgCard.withValues(alpha: 0.2);
                        textColor = Colors.white.withValues(alpha: 0.3);
                        letterBg = Colors.white.withValues(alpha: 0.05);
                        letterText = Colors.white.withValues(alpha: 0.3);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _selectAnswer(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            padding: const EdgeInsets.all(MitraSpacing.lg),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius:
                                  BorderRadius.circular(MitraRadius.md),
                              border: Border.all(
                                  color: borderColor,
                                  width: showResult && (isCorrect || isSelected)
                                      ? 1.5
                                      : 1),
                            ),
                            child: Row(children: [
                              // Letter badge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: letterBg,
                                  border: Border.all(
                                      color:
                                          borderColor.withValues(alpha: 0.5)),
                                ),
                                alignment: Alignment.center,
                                child: showResult && isCorrect
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : showResult && isSelected && !isCorrect
                                        ? const Icon(Icons.close,
                                            size: 14, color: Colors.white)
                                        : Text(
                                            ['A', 'B', 'C', 'D'][i],
                                            style: TextStyle(
                                                fontFamily: 'SpaceMono',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: letterText),
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.options[i],
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),

                    // ── Explanation card ──────────────
                    if (_answered && q.explanation != null) ...[
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.all(MitraSpacing.lg),
                        decoration: BoxDecoration(
                          color:
                              MitraColors.indigoLight.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(MitraRadius.md),
                          border: Border.all(
                              color: MitraColors.indigoLight
                                  .withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: MitraColors.indigoLight, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.explanation!,
                                style: const TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 13,
                                  color: MitraColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: MitraSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Next / Submit button ──────────────────
            // Only visible after answering
            if (_answered)
              GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: themeHighlight,
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _current < _questions.length - 1
                        ? 'Next Question →'
                        : 'See Results →',
                    style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: MitraColors.bgSurface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(MitraRadius.pill),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Select an answer',
                  style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
