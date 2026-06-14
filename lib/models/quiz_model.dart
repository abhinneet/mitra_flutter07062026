class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex; // 0 for A, 1 for B, 2 for C, etc.
  final String? explanation; // Optional: Shows after they answer!

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  // ✨ BONUS: This will make fetching from Firebase incredibly easy later!
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }
}
