import 'dart:io';
import 'package:interview_bot/bot.dart';
import 'package:interview_bot/questions.dart';

void main() async {
  // 🔐 Проверяем, задан ли BOT_TOKEN
  final token = Platform.environment['BOT_TOKEN'];
  if (token == null || token.isEmpty) {
    print('❌ Ошибка: Переменная окружения BOT_TOKEN не задана.');
    print('💡 Решение:');
    print('   1. Перейди в Settings → Codespaces → Secrets');
    print('   2. Добавь секрет с именем BOT_TOKEN и значением токена');
    print('   3. Перезапусти Codespaces');
    exit(1); // Останавливаем выполнение
  }

  // ✅ Если токен есть — запускаем бота
  print('✅ BOT_TOKEN найден. Запускаем бота...');
  setupBot();
  bot.launch();
  print('🚀 DevSurvivalBot запущен и готов к бою!');
}