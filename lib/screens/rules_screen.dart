import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/game_rules.dart';
import '../widgets/common/game_button.dart';

/// Rules screen — all numbers are read from [GameRules] dynamically.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Container(
        color: AppStyles.bgColor,
        child: Container(
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 24),

                // Title
                Text(
                  'ПРАВИЛА ИГРЫ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.accent,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('🎯 Цель игры', _goalText),
                        _section('👥 Роли', _rolesText),
                        _section('🕹️ Ход игры', _gameplayText),
                        _section('⭐ Очки', _scoringText),
                        _section('🏆 Победитель', _winnerText),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Back button
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 24),
                  child: GameButton(
                    text: '← НАЗАД',
                    type: GameButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                    width: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builder ─────────────────────────────────────────────────────
  static Widget _section(String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppStyles.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppStyles.accent.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppStyles.accent,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 15,
                color: AppStyles.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text blocks ────────────────────────────────────────────────────────
  static const String _goalText =
      'Мирные жители должны вычислить шпиона и проголосовать за его исключение.\n'
      'Шпион должен остаться незамеченным и угадать секретную локацию.';

  static const String _rolesText =
      '🕵️ ШПИОН — один из ${GameRules.minPlayers}–${GameRules.maxPlayers} игроков. Не знает локацию. '
      'Должен вести себя так, будто он в теме, и угадать место.\n\n'
      '👤 МИРНЫЙ — знает локацию. Отвечает на вопросы так, чтобы не раскрыть место шпиону, '
      'но и не казаться шпионом самому.';

  static String get _gameplayText =>
      'Игроки задают друг другу вопросы по кругу.\n\n'
      '⏱ Таймер вопроса: ${GameRules.questionTimerSeconds} секунд. '
      'Если не успел ответить — штраф ${GameRules.penaltyOvertime.toStringAsFixed(1)} очка.\n\n'
      '💡 Можно попросить подсказку (до 2 раз за ход).\n\n'
      'После окончания времени раунда — голосование за шпиона.';

  static String get _scoringText =>
      '✅ Мирные нашли шпиона:\n'
      '   • Каждый мирный жилетель: +${GameRules.civiliansWinsVote.toStringAsFixed(0)} очко\n'
      '   • Шпион: 0 очков\n\n'
      '❌ Мирного выгнали вместо шпиона:\n'
      '   • Шпион: +${GameRules.spyNotFound.toStringAsFixed(0)} очка\n'
      '   • Мирные: 0 очков\n\n'
      '🎯 Шпион угадал локацию после разоблачения:\n'
      '   • Шпион: +${GameRules.spyGuessedAfterFound.toStringAsFixed(0)} очко бонус\n\n'
      '⚠️ Штраф за просроченный вопрос:\n'
      '   • ${GameRules.penaltyOvertime.toStringAsFixed(1)} очка';

  static const String _winnerText =
      'После всех раундов побеждает игрок с наибольшим количеством очков.\n\n'
      'При ничье — побеждает тот, кто чаще угадывал правильно.';
}
