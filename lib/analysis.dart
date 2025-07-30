import 'dart:io';
import 'package:http/http.dart' as http;
import 'questions.dart';

final String token = Platform.environment['BOT_TOKEN'] ?? '';
final String apiUrl = 'https://api.telegram.org/bot$token';

Future<void> sendMessage(int chatId, String text, [Map<String, dynamic>? replyMarkup]) async {
  final url = Uri.parse('$apiUrl/sendMessage');
  final body = {
    'chat_id': chatId,
    'text': text,
    'parse_mode': 'Markdown',
    'reply_markup': json.encode(replyMarkup ?? {}),
  };
  await http.post(url, body: body);
}

void analyzeResults(Map<String, dynamic> userData, int chatId) async {
  final answers = userData['answers'] as List<int>;
  final filtered = userData['filtered'] as List<Question>;

  final byTopic = <String, int>{};
  int correct = 0;

  for (int i = 0; i < 10; i++) {
    final q = filtered[i];
    final isCorrect = answers[i] == q.correctIndex;
    if (isCorrect) {
      correct++;
      byTopic[q.topic] = (byTopic[q.topic] ?? 0) + 1;
    }
  }

  final analysis = '''
🎯 *Тест завершён!*
Ты ответил правильно на *$correct из 10*.

🔍 *Анализ по темам:*
• Основы: ${byTopic['basics'] ?? 0}/3 ${byTopic['basics'] == 3 ? '✅' : byTopic['basics']! >= 2 ? '⚠️' : '❌'}
• Управление памятью: ${byTopic['memory'] ?? 0}/3 ${byTopic['memory'] == 3 ? '✅' : byTopic['memory']! >= 2 ? '⚠️' : '❌'}
• Асинхронность: ${byTopic['async'] ?? 0}/3 ${byTopic['async'] == 3 ? '✅' : byTopic['async']! >= 2 ? '⚠️' : '❌'}
• Виджеты: ${byTopic['widgets'] ?? 0}/3 ${byTopic['widgets'] == 3 ? '✅' : byTopic['widgets']! >= 2 ? '⚠️' : '❌'}
• Архитектура: ${byTopic['architecture'] ?? 0}/1 ${byTopic['architecture'] == 1 ? '✅' : '❌'}

📌 *Рекомендации:*
  ''';

  String recommendations = '';

  if ((byTopic['async'] ?? 0) < 2) {
    recommendations += '🔸 Изучи асинхронность: Future, Isolate, async/await\n';
    recommendations += '• https://dart.dev/codelabs/async-await\n';
  }

  if ((byTopic['architecture'] ?? 0) < 1) {
    recommendations += '\n🔸 Архитектура:\n';
    recommendations += '• BLoC: https://pub.dev/packages/flutter_bloc\n';
    recommendations += '• Clean Architecture: https://github.com/brianegan/flutter_architecture_samples\n';
  }

  if (recommendations.isEmpty) {
    recommendations = "🎉 Отличная работа! Готов к собеседованию!";
  }

  if (correct < 3) {
    recommendations += "\n\n💡 А теперь анекдот:\n_Почему программист не пошёл на свидание?_\n`Because null == true`";
  }

  await sendMessage(chatId, analysis + recommendations);
}