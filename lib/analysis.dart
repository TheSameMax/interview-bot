import 'package:teler/teler.dart';

void analyzeResults(TelegramContext ctx, Map<String, dynamic> userData) {
  final answers = userData['answers'];
  final filtered = userData['filtered'];
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

  final recommendations = generateRecommendations(byTopic, filtered);

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
${recommendations.isEmpty ? "🎉 Отличная работа! Готов к собеседованию!" : recommendations}
''';

  ctx.reply(analysis, parseMode: 'Markdown');
}

String generateRecommendations(Map<String, int> byTopic, List<Question> filtered) {
  final recommendations = StringBuffer();

  if (byTopic['basics']! < 2) {
    recommendations.writeln('- 🔹 Изучи основы:');
    recommendations.writeln('  • https://docs.swift.org/swift-book/');
    recommendations.writeln('  • https://dart.dev/guides/language/language-tour');
    recommendations.writeln('  • https://docs.flutter.dev/get-started');
  }

  if (byTopic['memory']! < 2) {
    recommendations.writeln('- 🔹 Управление памятью:');
    recommendations.writeln('  • https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/');
    recommendations.writeln('  • https://dart.dev/guides/language/effective-dart/design#memory-management');
  }

  if (byTopic['async']! < 2) {
    recommendations.writeln('- 🔹 Асинхронность:');
    recommendations.writeln('  • https://dart.dev/codelabs/async-await');
    recommendations.writeln('  • https://docs.flutter.dev/cookbook/networking/fetch-data');
  }

  if (byTopic['widgets']! < 2) {
    recommendations.writeln('- 🔹 Виджеты в Flutter:');
    recommendations.writeln('  • https://docs.flutter.dev/ui/widgets');
    recommendations.writeln('  • https://docs.flutter.dev/perf');
  }

  if (byTopic['architecture']! < 1) {
    recommendations.writeln('- 🔹 Архитектура:');
    recommendations.writeln('  • BLoC: https://pub.dev/packages/flutter_bloc');
    recommendations.writeln('  • Clean Architecture: https://github.com/brianegan/flutter_architecture_samples');
  }

  return recommendations.toString();
}