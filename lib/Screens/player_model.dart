class Player {
  final String id;
  int correctAnswers;
  double timeTaken; // با دقت صدم ثانیه

  Player({
    required this.id,
    this.correctAnswers = 0,
    this.timeTaken = 0.0,
  });

  // متد افزایش امتیاز
  void addCorrectAnswer(double responseTime) {
    correctAnswers++;
    timeTaken += responseTime;
  }
}
