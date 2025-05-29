import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuestionService {
  static Future<List<Question>> fetchRandomQuestions(int count) async {
    final String response =
        await rootBundle.loadString('assets/questions.json');
    List<dynamic> data = json.decode(response);

    // تبدیل به مدل سوال
    List<Question> questions = data.map((q) => Question.fromJson(q)).toList();

    // مخلوط کردن لیست و انتخاب تعدادی سوال تصادفی
    questions.shuffle(Random());
    return questions.take(count).toList();
  }
}
