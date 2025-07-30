import 'dart:convert';
import 'dart:io';
import 'package:teler/teler.dart';
import 'questions.dart';
import 'analysis.dart';

final bot = Teler(token: Platform.environment['BOT_TOKEN'] ?? '');

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
    replyMarkup: {
      'keyboard': [
        [{'text': 'Swift'}, {'text': 'Dart'}, {'text': 'Flutter'}],
        [{'text': '❓ Помощь'}]
      ],
      'resize_keyboard': true,
      'one_time_keyboard': false,
    },
    parseMode: 'Markdown',
  );
}

// Начало теста
void setupBot() {
  setCommands();

  bot.command('start', (ctx) async {
    final userId = ctx.from.id;
    userState[userId] = {
      'answers': <int>[],
      'index': 0,
      'tech': null,
      'filtered': [],
    };
    await sendWelcome(ctx);
  });

  bot.command('help', (ctx) async {
    await ctx.reply(
      '📌 *Как это работает?*\n\n'
      '1. Выбери технологию: Swift, Dart или Flutter\n'
      '2. Отвечай на 10 вопросов\n'
      '3. В конце получишь:\n'
      '   • Статистику\n'
      '   • Анализ слабых мест\n'
      '   • Ссылки для изучения\n\n'
      '💡 Совет: не бойся ошибаться — я не @BotFather, чтобы тебя банить.',
      parseMode: 'Markdown',
    );
  });

  bot.command('restart', (ctx) async {
    final userId = ctx.from.id;
    userState[userId] = {
      'answers': <int>[],
      'index': 0,
      'tech': null,
      'filtered': [],
    };
    await ctx.reply('🔄 Тест перезапущен. Выбери технологию:', replyMarkup: {
      'keyboard': [
        [{'text': 'Swift'}, {'text': 'Dart'}, {'text': 'Flutter'}],
        [{'text': '❓ Помощь'}]
      ],
      'resize_keyboard': true,
    });
  });

  bot.hears(['Swift', 'Dart', 'Flutter'], (ctx) async {
    final userId = ctx.from.id;
    final tech = ctx.message.text!.toLowerCase();
    final filtered = questions.where((q) => q.tech == tech).toList();
    userState[userId]!['tech'] = tech;
    userState[userId]!['filtered'] = filtered;
    await askQuestion(ctx);
  });

  bot.hears('❓ Помощь', (ctx) async {
    await bot.handlers['help']!(ctx);
  });

  bot.on('message', (ctx) async {
    final text = ctx.message.text;
    final userId = ctx.from.id;
    final userData = userState[userId];
    if (userData == null || userData['tech'] == null) return;

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
    replyMarkup: {
      'keyboard': question.options.map((opt) => [{'text': opt}]).toList(),
      'resize_keyboard': true,
      'one_time_keyboard': true,
    },
    parseMode: 'Markdown',
  );
}

// Показать результат
Future<void> showResult(TelegramContext ctx) async {
  final userId = ctx.from.id;
  final userData = userState[userId]!;
  final filtered = userData['filtered'];
  final answers = userData['answers'];

  analyzeResults(ctx, userData);
}