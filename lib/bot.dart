import 'dart:convert';
import 'dart:io';
import 'package:telegraf/telegraf.dart';
import 'package:interview_bot/questions.dart';

final bot = Bot(Platform.environment['BOT_TOKEN'] ?? '');

// Хранилище пользователей
Map<int, Map<String, dynamic>> userState = {};

// Инициализация вопросов
List<Question> questions = loadQuestions();

// Установка меню команд
void setCommands() {
  bot.setMyCommands([
    BotCommand("start", "🚀 Начать сначала"),
    BotCommand("help", "❓ Помощь и подсказки"),
    BotCommand("restart", "🔁 Перезапустить тест"),
  ]);
}

// Приветствие
Future<void> sendWelcome(TelegramContext ctx) async {
  await ctx.reply(
    '👋 Привет, будущий Senior!\n\n'
    'Я — *DevSurvivalBot*, и я помогу тебе подготовиться к собеседованию '
    'по **Swift, Dart или Flutter**.\n\n'
    '🔹 Отвечай на 10 вопросов\n'
    '🔹 Получи анализ своих знаний\n'
    '🔹 И честные рекомендации, куда смотреть, если что-то пошло не так\n\n'
    'Готов? Выбери технологию:',
    replyMarkup: ReplyKeyboardMarkup(
      keyboard: [
        [KeyboardButton(text: 'Swift'), KeyboardButton(text: 'Dart'), KeyboardButton(text: 'Flutter')],
        [KeyboardButton(text: '❓ Помощь')]
      ],
      resizeKeyboard: true,
    ),
    parseMode: ParseMode.markdown,
  );
}

// Начало теста
void setupBot() {
  setCommands();

  bot.onCommand('start', (ctx) async {
    final userId = ctx.from.id;
    userState[userId] = {
      'answers': <int>[],
      'index': 0,
      'tech': null,
      'filtered': [],
    };
    await sendWelcome(ctx);
  });

  bot.onCommand('help', (ctx) async {
    await ctx.reply(
      '📌 *Как это работает?*\n\n'
      '1. Выбери технологию: Swift, Dart или Flutter\n'
      '2. Отвечай на 10 вопросов\n'
      '3. В конце получишь:\n'
      '   • Статистику\n'
      '   • Анализ слабых мест\n'
      '   • Ссылки для изучения\n\n'
      '💡 Совет: не бойся ошибаться — я не @BotFather, чтобы тебя банить.',
      parseMode: ParseMode.markdown,
    );
  });

  bot.onCommand('restart', (ctx) async {
    final userId = ctx.from.id;
    userState[userId] = {
      'answers': <int>[],
      'index': 0,
      'tech': null,
      'filtered': [],
    };
    await ctx.reply('🔄 Тест перезапущен. Выбери технологию:', replyMarkup: ReplyKeyboardMarkup(
      keyboard: [
        [KeyboardButton(text: 'Swift'), KeyboardButton(text: 'Dart'), KeyboardButton(text: 'Flutter')],
        [KeyboardButton(text: '❓ Помощь')]
      ],
      resizeKeyboard: true,
    ));
  });

  bot.onMessage((ctx) async {
    final text = ctx.message.text;
    final userId = ctx.from.id;
    final userData = userState[userId];
    if (userData == null) return;

    if (text == 'Swift' || text == 'Dart' || text == 'Flutter') {
      final tech = text.toLowerCase();
      final filtered = questions.where((q) => q.tech == tech).toList();
      userData['tech'] = tech;
      userData['filtered'] = filtered;
      await askQuestion(ctx);
      return;
    }

    if (text == '❓ Помощь') {
      await bot.handlers['help']!(ctx);
      return;
    }

    final index = userData['index'];
    if (index >= 10) return;

    final filtered = userData['filtered'];
    final question = filtered[index];
    final selectedOption = question.options.indexOf(text!);
    if (selectedOption == -1) return;

    userData['answers'].add(selectedOption);

    final isCorrect = selectedOption == question.correctIndex;
    await ctx.reply(
      isCorrect ? '✅ Правильно!' : '❌ Неверно. Правильный ответ: ${question.options[question.correctIndex]}',
    );

    userData['index'] = index + 1;
    if (index + 1 < 10) {
      await Future.delayed(const Duration(seconds: 1));
      await askQuestion(ctx);
    } else {
      await showResult(ctx);
    }
  });
}

// Задать вопрос
Future<void> askQuestion(TelegramContext ctx) async {
  final userId = ctx.from.id;
  final userData = userState[userId]!;
  final index = userData['index'];
  final filtered = userData['filtered'];

  final question = filtered[index];

  await ctx.reply(
    '*Вопрос ${index + 1}:*\n\n${question.text}',
    replyMarkup: ReplyKeyboardMarkup(
      keyboard: question.options.map((opt) => [KeyboardButton(text: opt)]).toList(),
      resizeKeyboard: true,
      oneTimeKeyboard: true,
    ),
    parseMode: ParseMode.markdown,
  );
}

// Показать результат
Future<void> showResult(TelegramContext ctx) async {
  final userId = ctx.from.id;
  final userData = userState[userId]!;
  final filtered = userData['filtered'];
  final answers = userData['answers'];

  final byTopic = {
    'basics': 0,
    'memory': 0,
    'async': 0,
    'widgets': 0,
    'architecture': 0,
  };

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
• Основы: ${byTopic['basics']}/3 ${byTopic['basics'] == 3 ? '✅' : byTopic['basics']! >= 2 ? '⚠️' : '❌'}
• Управление памятью: ${byTopic['memory']}/3 ${byTopic['memory'] == 3 ? '✅' : byTopic['memory']! >= 2 ? '⚠️' : '❌'}
• Асинхронность: ${byTopic['async']}/3 ${byTopic['async'] == 3 ? '✅' : byTopic['async']! >= 2 ? '⚠️' : '❌'}
• Виджеты: ${byTopic['widgets']}/3 ${byTopic['widgets'] == 3 ? '✅' : byTopic['widgets']! >= 2 ? '⚠️' : '❌'}
• Архитектура: ${byTopic['architecture']}/1 ${byTopic['architecture'] == 1 ? '✅' : '❌'}

📌 *Рекомендации:*
  ''';

  String recommendations = '';

  if (byTopic['async']! < 2) {
    recommendations += '🔸 Изучи асинхронность: Future, Isolate, async/await\n';
    recommendations += '• https://dart.dev/codelabs/async-await\n';
  }

  if (byTopic['architecture']! < 1) {
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

  await ctx.reply(analysis + recommendations, parseMode: ParseMode.markdown);
}