import 'dart:convert';
import 'dart:io';

List<Question> loadQuestions() {
  final file = File('data/questions.json');
  final content = file.readAsStringSync();
  final List<dynamic> jsonList = json.decode(content);

  return jsonList.map((json) => Question.fromJson(json)).toList();
}

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
      tech: json['technology'] as String,
      difficulty: json['difficulty'] as String,
      topic: json['topic'] as String,
      text: json['question'] as String,
      options: (json['options'] as List).map((e) => e.toString()).toList(),
      correctIndex: json['correct'] as int,
      recommendation: json['recommendation'] as String,
    );
  }
}