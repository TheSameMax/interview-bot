import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:interview_bot/analysis.dart';
import 'package:interview_bot/questions.dart';

Map<int, Map<String, dynamic>> userState = {};

final String token = Platform.environment['BOT_TOKEN'] ?? '';
final String apiUrl = 'https://api.telegram.org/bot$token';

Future<void> setWebhook() async {
  final url = Uri.parse('$apiUrl/setWebhook');
  final body = {'url': ''};
  try {
    await http.post(url, body: body);
  } catch (e) {
    print('🔴 Ошибка setWebhook: $e');
  }
}

Future<List<dynamic>> getUpdates(int offset) async {
  final url = Uri.parse('$apiUrl/getUpdates?offset=$offset&timeout=30');
  try {
    final response = await http.get(url);
    final json = jsonDecode(response.body);
    return json['ok'] == true ? json['result'] : [];
  } catch (e) {
    print('🔴 Ошибка getUpdates: $e');
    return [];
  }
}

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
    '🔹 И честные рекомендации\n\n'
    'Готов? Выбери технологию:',
    replyMarkup,
  );
}

Future<void> sendHelp(int chatId) async {
  await sendMessage(
    chatId,
    '📌 *Как это работает?*\n\n'
    '1. Выбери технологию\n'
    '2. Отвечай на 10 вопросов\n'
    '3. В конце получишь анализ и рекомендации\n\n'
    '💡 Совет: не бойся ошибаться — я не @BotFather, чтобы тебя банить.',
  );
}

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

// ИСПРАВЛЕНО: Future<void> async
Future<void> startBot() async {
  final List<Question> questions = loadQuestions();
  int offset = 0;

  await setWebhook();
  print('✅ DevSurvivalBot запущен и готов к бою!');

  while (true) {
    try {
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

        if (text == '🔁 Начать заново') {
          userData['answers'] = [];
          userData['index'] = 0;
          userData['tech'] = null;
          userData['filtered'] = [];
          userState[chatId] = userData;
          await sendWelcome(chatId);
          continue;
        }

        // ИСПРАВЛЕНО: text != null && (...)
        if (text != null && (text == 'Swift' || text == 'Dart' || text == 'Flutter')) {
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
          await analyzeResults(userData, chatId);
        }
      }
    } catch (e, stack) {
      print('🔴 Критическая ошибка: $e\n$stack');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
