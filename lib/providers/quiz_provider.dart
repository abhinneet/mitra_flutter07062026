import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✨ Make sure this path matches where you saved your model!
import '../models/quiz_model.dart';

// 1. The State Container: Holds all the data for the active quiz
class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int? selectedAnswer; // Null until the user taps an option
  final bool hasSubmitted; // Flips to true when they lock in their answer

  const QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.score = 0,
    this.selectedAnswer,
    this.hasSubmitted = false,
  });

  // Helpful shortcuts for the UI
  QuizQuestion get currentQuestion => questions[currentIndex];
  bool get isComplete => currentIndex >= questions.length;

  QuizState copyWith({
    int? currentIndex,
    int? score,
    int? selectedAnswer,
    bool? hasSubmitted,
    bool clearSelection = false, // Special flag to reset the selection
  }) {
    return QuizState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswer:
          clearSelection ? null : (selectedAnswer ?? this.selectedAnswer),
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    );
  }
}

// 2. The Brain: Handles the logic and math
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(List<QuizQuestion> initialQuestions)
      : super(QuizState(questions: initialQuestions));

  // User taps an option (just highlights it, doesn't submit yet)
  void selectAnswer(int index) {
    if (state.hasSubmitted) return; // Prevent changing answer after submission
    state = state.copyWith(selectedAnswer: index);
  }

  // User taps "Lock It In" / "Submit"
  void submitAnswer() {
    if (state.selectedAnswer == null || state.hasSubmitted) return;

    final isCorrect =
        state.selectedAnswer == state.currentQuestion.correctAnswerIndex;

    state = state.copyWith(
      hasSubmitted: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  // User taps "Next Question"
  void nextQuestion() {
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      hasSubmitted: false,
      clearSelection: true, // Clears the bubble for the new question
    );
  }

  // Restarts the quiz from the beginning
  void resetQuiz() {
    state = QuizState(questions: state.questions);
  }
}

// 3. The Provider: How the UI will talk to the Brain
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  // We will use dummy data for now to test the UI!
  // Later, we can swap this to fetch from Firebase.
  final sampleQuestions = [
    const QuizQuestion(
      questionText: "What is the powerhouse of the cell?",
      options: ["Nucleus", "Mitochondria", "Ribosome", "Endoplasmic Reticulum"],
      correctAnswerIndex: 1,
      explanation:
          "Mitochondria generate most of the chemical energy needed to power the cell's biochemical reactions.",
    ),
    const QuizQuestion(
      questionText: "Which planet is known as the Red Planet?",
      options: ["Venus", "Mars", "Jupiter", "Saturn"],
      correctAnswerIndex: 1,
      explanation:
          "Mars gets its red color from iron oxide (rust) on its surface.",
    ),
    const QuizQuestion(
      questionText: "What is the chemical symbol for Gold?",
      options: ["Ag", "Au", "Fe", "Cu"],
      correctAnswerIndex: 1,
      explanation:
          "Au comes from the Latin word 'aurum', meaning shining dawn.",
    ),
  ];

  return QuizNotifier(sampleQuestions);
});
