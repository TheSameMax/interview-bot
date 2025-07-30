import 'dart:convert';
import 'dart:io';

class Question {
  final String tech;
  final String difficulty;
  final String topic;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String recommendation;

  Question({
    required this.tech,
    required this.difficulty,
    required this.topic,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.recommendation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      tech: json['technology'],
      difficulty: json['difficulty'],
      topic: json['topic'],
      text: json['question'],
      options: List<String>.from(json['options']),
      correctIndex: json['correct'],
      recommendation: json['recommendation'] ?? '',
    );
  }
}

List<Question> loadQuestions() {
  final file = File('data/questions.json');
  final content = file.readAsStringSync();
  final jsonList = json.decode(content) as List;
  return jsonList.map((q) => Question.fromJson(q)).toList();
}