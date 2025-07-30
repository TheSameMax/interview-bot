import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:interview_bot/analysis.dart';
import 'package:interview_bot/questions.dart';

// Хранилище пользователей
Map<int, Map<String, dynamic>> userState = {};

// Глобальный токен
final String token = Platform.environment['BOT_TOKEN'] ?? '';
final String apiUrl = 'https://api.telegram.org/bot$token';

// Отправка сообщения
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

// Установка вебхука (не нужен для polling)
Future<void> setWebhook() async {
  final url = Uri.parse('$apiUrl/setWebhook');
  final body = {'url': ''}; // Удаляем вебхук
  await http.post(url, body: body);
}

// Получение обновлений
Future<List<dynamic>> getUpdates(int offset) async {
  final url = Uri.parse('$apiUrl/getUpdates?offset=$offset&timeout=30');
  final response = await http.get(url);
  final json = jsonDecode(response.body);
  return json['ok'] == true ? json['result'] : [];
}

// Приветствие
Future<void> sendWelcome(int chatId) async {
  final replyMarkup = {
    'keyboard': [
      [{'text': 'Swift'}, {'text': 'Dart'}, {'text': 'Flutter'}],
      [{'text': '❓ Помощь'}]
    ],
    'resize_keyboard': true,
  };

  await sendMessage(
    chatId,
    '👋 Привет, будущий Senior!\n\n'
    'Я — *DevSurvivalBot*, и я помогу тебе подготовиться к собеседованию '
    'по **Swift, Dart или Flutter**.\n\n'
    '🔹 Отвечай на 10 вопросов\n'
    '🔹 Получи анализ своих знаний\n'
    '🔹 И честные рекомендации, куда смотреть, если что-то пошло не так\n\n'
    'Готов? Выбери технологию:',
    replyMarkup,
  );
}

// Показать помощь
Future<void> sendHelp(int chatId) async {
  await sendMessage(
    chatId,
    '📌 *Как это работает?*\n\n'
    '1. Выбери технологию: Swift, Dart или Flutter\n'
    '2. Отвечай на 10 вопросов\n'
    '3. В конце получишь:\n'
    '   • Статистику\n'
    '   • Анализ слабых мест\n'
    '   • Ссылки для изучения\n\n'
    '💡 Совет: не бойся ошибаться — я не @BotFather, чтобы тебя банить.',
  );
}

// Задать вопрос
Future<void> askQuestion(int chatId, int index, List<Question> filtered) async {
  final question = filtered[index];
  final replyMarkup = {
    'keyboard': question.options.map((opt) => [{'text': opt}]).toList(),
    'resize_keyboard': true,
    'one_time_keyboard': true,
  };

  await sendMessage(
    chatId,
    '*Вопрос ${index + 1}:*\n\n${question.text}',
    replyMarkup,
  );
}

// Показать результат
Future<void> showResult(int chatId, List<int> answers, List<Question> filtered) async {
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

// Основной цикл бота
Future<void> startBot() async {
  final List<Question> questions = loadQuestions();
  int offset = 0;

  // Удаляем вебхук (используем polling)
  await setWebhook();

  print('✅ DevSurvivalBot запущен и готов к бою!');

  while (true) {
    final updates = await getUpdates(offset);
    for (final update in updates) {
      offset = update['update_id'] + 1;
      final message = update['message'];
      if (message == null) continue;

      final chatId = message['chat']['id'];
      final text = message['text'] as String?;

      final userData = userState[chatId] ?? {
        'answers': <int>[],
        'index': 0,
        'tech': null,
        'filtered': [],
      };

      if (text == '/start') {
        userData['answers'] = [];
        userData['index'] = 0;
        userData['tech'] = null;
        userData['filtered'] = [];
        userState[chatId] = userData;
        await sendWelcome(chatId);
        continue;
      }

      if (text == '❓ Помощь') {
        await sendHelp(chatId);
        continue;
      }

      if (text == 'Swift' || text == 'Dart' || text == 'Flutter') {
        final tech = text.toLowerCase();
        final filtered = questions.where((q) => q.tech == tech).toList();
        userData['tech'] = tech;
        userData['filtered'] = filtered;
        userState[chatId] = userData;
        await askQuestion(chatId, 0, filtered);
        continue;
      }

      final index = userData['index'];
      if (index >= 10) continue;

      final filtered = userData['filtered'] as List<Question>;
      final question = filtered[index];
      final selectedOption = question.options.indexOf(text!);
      if (selectedOption == -1) continue;

      userData['answers'].add(selectedOption);
      userState[chatId] = userData;

      final isCorrect = selectedOption == question.correctIndex;
      await sendMessage(chatId, isCorrect ? '✅ Правильно!' : '❌ Неверно. Правильный ответ: ${question.options[question.correctIndex]}');

      final nextIndex = index + 1;
      userData['index'] = nextIndex;
      userState[chatId] = userData;

      if (nextIndex < 10) {
        await Future.delayed(const Duration(seconds: 1));
        await askQuestion(chatId, nextIndex, filtered);
      } else {
        await showResult(chatId, userData['answers'], filtered);
      }
    }
  }
}