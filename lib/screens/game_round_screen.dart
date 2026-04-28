import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/app_settings.dart';
import '../config/app_environment.dart';
import '../utils/game_rules.dart';
import '../utils/game_sounds.dart';
import '../utils/sound_service.dart';

import '../models/game_session.dart';
import '../services/storage_service.dart';
import 'voting_screen.dart';
import 'round_score_screen.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';

class GameRoundScreen extends StatefulWidget {
  final GameSession session;

  const GameRoundScreen({super.key, required this.session});

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen>
    with SingleTickerProviderStateMixin {
  late int _mainTimerRemaining;
  int _questionTimerRemaining = 20;

  int _additionalTimerRemaining = 0;
  bool _isAdditionalTime = false;

  // Penalty notification
  bool _showPenaltyNotification = false;
  String _penaltyPlayerName = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _mainTimer;
  Timer? _questionTimer;

  late int _currentAskerIndex;
  late int _currentTargetIndex;

  bool _isLastQuestion = false;
  bool _showLastQuestionText = false;
  bool _isTimeUp = false;
  bool _isTransitioning = false;

  int _hintsUsed = 0;
  bool _isHintCooldown = false;
  bool _privateHintsExhausted = false;
  List<String> _currentHintsText = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pulseController.reverse();
          }
        });
    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainTimerRemaining = widget.session.gameTime * 60;

    // Setup initial players
    _currentAskerIndex = Random().nextInt(widget.session.players.length);
    _currentTargetIndex =
        (_currentAskerIndex + 1) % widget.session.players.length;

    _startTimers();
  }

  void _startTimers() {
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mainTimerRemaining > 0 &&
          !_isTimeUp &&
          !_isTransitioning &&
          !_isLastQuestion) {
        setState(() {
          _mainTimerRemaining--;
        });
      }
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimeUp || _isTransitioning) return;

      setState(() {
        if (_questionTimerRemaining > 0) {
          _questionTimerRemaining--;

          if (_questionTimerRemaining == 0 && !_isAdditionalTime) {
            _isAdditionalTime = true;
            _additionalTimerRemaining = GameRules.overtimeSeconds;
            _pulseController.forward(from: 0.0);
            SoundService.instance.playSiren();
          }
        } else if (_isAdditionalTime) {
          if (_additionalTimerRemaining > 0) {
            _additionalTimerRemaining--;
            if (_additionalTimerRemaining > 0) {
              _pulseController.forward(from: 0.0);
              SoundService.instance.playSiren();
            }
          }

          if (_additionalTimerRemaining == 0) {
            _isAdditionalTime = false;
            _isTimeUp =
                true; // Отключаем кнопку "ДАЛЬШЕ!" для предотвращения нажатий во время показа штрафа
            final penalisedPlayer = widget.session.players[_currentAskerIndex];
            penalisedPlayer.addScore(GameRules.penaltyOvertime);

            // Сначала показываем штраф, затем запускаем логику окончания времени
            Future.microtask(() async {
              await _showPenalty(penalisedPlayer.name);
              _onQuestionTimeUp();
            });
          }
        }
      });
    });
  }

  void _onQuestionTimeUp() async {
    // Текст "ВРЕМЯ ВЫШЛО!" уже показывался в течение 3 сек (во время _isAdditionalTime).
    // Штраф тоже уже был показан (2 сек).
    // Теперь сразу переходим к следующему игроку.
    if (!mounted) return;

    if (_isLastQuestion) {
      _navigateToVoting();
    } else {
      _transitionToNextPlayer();
    }
  }

  void _onNextPressed() {
    SoundService.instance.playClick();
    if (_isLastQuestion) {
      _navigateToVoting();
    } else {
      _transitionToNextPlayer();
    }
  }

  void _navigateToVoting() {
    _mainTimer?.cancel();
    _questionTimer?.cancel();
    // Reset private hints at end of round so next round starts fresh
    storageService.resetPrivateHints(widget.session.currentSecretLocation);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VotingScreen(session: widget.session),
      ),
    );
  }

  void _showStopRoundDialog() {
    SoundService.instance.playClick();
    // Pause timers
    _mainTimer?.cancel();
    _questionTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppStyles.bgColor, // Фоновый цвет диалога
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppStyles.darkAccent.withValues(alpha: 0.1),
              width: 2,
            ), // Цвет рамки диалога
          ),
          title: Text(
            AppStrings.whatHappened,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppStyles.accent,
            ), // Цвет заголовка диалога
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Шпион уже отгадал локацию -> Шпион +3 очка, мирные 0
                  widget.session.addScoreToSpy(3);
                  _navigateToScores();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles
                      .success, // Цвет кнопки "Шпион угадал локацию" (зеленый)
                  foregroundColor: Colors.white, // Цвет текста кнопки
                  side: BorderSide(
                    color: Colors.green.shade900,
                    width: 2,
                  ), // Цвет рамки кнопки
                ),
                child: const Text(
                  AppStrings.spyGuessedLoc,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Провал шпиона -> Мирные +2, Шпион -2
                  widget.session.addScoreToCivilians(2);
                  widget.session.addScoreToSpy(-2);
                  _navigateToScores();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppStyles.danger, // Цвет кнопки "Шпион пойман" (красный)
                  foregroundColor: Colors.white, // Цвет текста кнопки
                  side: BorderSide(
                    color: Colors.red.shade900,
                    width: 2,
                  ), // Цвет рамки кнопки
                ),
                child: const Text(
                  AppStrings.spyCaught,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Ничего, играем дальше -> resume timers
                  _startTimers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles
                      .warning, // Цвет кнопки "Продолжить игру" (оранжевый)
                  foregroundColor: Colors.white, // Цвет текста кнопки
                  side: BorderSide(
                    color: Colors.orange.shade900,
                    width: 2,
                  ), // Цвет рамки кнопки
                ),
                child: const Text(
                  AppStrings.continueGame,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToScores() {
    _mainTimer?.cancel();
    _questionTimer?.cancel();
    // Reset private hints at end of round so next round starts fresh
    storageService.resetPrivateHints(widget.session.currentSecretLocation);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoundScoreScreen(session: widget.session),
      ),
    );
  }

  void _transitionToNextPlayer() async {
    setState(() {
      _isTransitioning = true;
      _isTimeUp = false;
      _isAdditionalTime = false;
      _additionalTimerRemaining = 0;
    });

    // Simulate transition delay (2 seconds) for the rotation animation (which will be in the build method)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _currentAskerIndex = _currentTargetIndex;
      _currentTargetIndex =
          (_currentTargetIndex + 1) % widget.session.players.length;

      _hintsUsed = 0;
      _privateHintsExhausted = false;
      _currentHintsText.clear();
      _questionTimerRemaining = 20;

      // Check if it's the last question based on the main timer
      if (_mainTimerRemaining <= 20) {
        _isLastQuestion = true;
        _showLastQuestionText = true;

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showLastQuestionText = false;
            });
          }
        });
        // _showLastQuestionToast(); // Выключено: теперь отображается над кнопкой "Завершить раунд" вместо всплывающего окна
      }

      _isTransitioning = false;
    });
  }

  void _showLastQuestionToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          AppStrings.lastQuestionToast,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            AppStyles.danger, // Цвет фона уведомления о последнем вопросе
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showPenalty(String playerName) async {
    if (!mounted) return;
    setState(() {
      _penaltyPlayerName = playerName;
      _showPenaltyNotification = true;
    });

    // Показываем уведомление ровно 2 секунды
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _showPenaltyNotification = false);
    }

    // Даем окну полностью исчезнуть до начала анимации вращения экрана (избегаем наслоения)
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _onHintPressed() {
    if (_isHintCooldown || _hintsUsed >= 2) return;

    setState(() => _isHintCooldown = true);

    _pickHint().then((hintText) {
      if (!mounted) return;
      setState(() {
        _currentHintsText.clear();
        _currentHintsText.add(hintText);
        _hintsUsed++;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isHintCooldown = false);
      });
    });
  }

  /// Selection logic:
  /// - Hint 1 (hintsUsed == 0): always universal
  /// - Hint 2 (hintsUsed == 1): private if available, else universal
  /// If all private hints are exhausted for this round → always universal
  Future<String> _pickHint() async {
    if (_hintsUsed == 0 || _privateHintsExhausted) {
      // Universal turn
      return storageService.pickNextUniversalHint();
    } else {
      // Try private first
      final privateHint = await storageService.pickNextPrivateHint(
        widget.session.currentSecretLocation,
      );
      if (privateHint != null) {
        return privateHint;
      } else {
        // Private exhausted — fall back to universal from now on
        _privateHintsExhausted = true;
        return storageService.pickNextUniversalHint();
      }
    }
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _questionTimer?.cancel();
    _pulseController.dispose();
    SoundService.instance.stopSiren();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getQuestionTimerColor() {
    if (_questionTimerRemaining <= 5)
      return Colors.red; // Цвет таймера вопроса, когда осталось мало времени
    if (_questionTimerRemaining <= 10)
      return Colors.orange; // Цвет таймера вопроса (желтый/оранжевый)
    return Colors.white; // Обычный цвет таймера вопроса
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor, // Основной фоновый цвет экрана
            child: Container(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 1. Main Timer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.screenWidth * 0.15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.darkAccent.withValues(
                          alpha: 0.01,
                        ), // Цвет фона плашки таймера (с прозрачностью)
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${AppStrings.roundPrefix}${widget.session.currentRound}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles
                                      .accent, // Цвет текста номера раунда
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                _formatTime(_mainTimerRemaining),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .white, // Цвет цифр главного таймера
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          if (AppEnvironment.showDeveloperFeatures) ...[
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _mainTimerRemaining = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .redAccent, // Цвет кнопки "СКИП ТАЙМЕРА" (только для разработчиков)
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text(
                                'СКИП\nТАЙМЕРА',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Transition animation or Content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return RotationTransition(
                                turns: Tween<double>(
                                  begin: -0.5,
                                  end: 0.0,
                                ).animate(animation),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: _isTransitioning
                            ? Center(
                                key: const ValueKey('transition'),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sync,
                                      color: AppStyles.accent,
                                      size: 140,
                                    ), // Цвет иконки синхронизации
                                    const SizedBox(height: 20),
                                    Text(
                                      AppStrings.transitionText,
                                      style: TextStyle(
                                        color: AppStyles
                                            .accent, // Цвет текста "Передайте телефон"
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : _buildRoundContent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Penalty notification overlay
          if (_showPenaltyNotification)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyles.danger.withValues(
                        alpha: 0.25,
                      ), // Цвет фона штрафного окна
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppStyles.cardBg,
                        width: 2,
                      ), // Цвет рамки штрафного окна
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.darkAccent.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ], // Цвет тени штрафного окна
                    ),
                    child: Text(
                      '$_penaltyPlayerName − теряет часть своего очка 😭\n${GameRules.penaltyOvertime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, // Цвет текста в штрафном окне
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ExitGameButton(
            onPause: () {
              _mainTimer?.cancel();
              _questionTimer?.cancel();
            },
            onResume: () {
              _startTimers();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundContent(BuildContext context) {
    bool subscribe_payed = false;
    final double circleSize = (context.screenWidth * 0.35).clamp(100.0, 180.0);

    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Зафиксированная область, адаптивная под экран
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2. Current turn text
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalMargin,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppStyles.cardBg,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.darkAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.session.players[_currentAskerIndex].name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.accent,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 45,
                          color: AppStyles.accent,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.session.players[_currentTargetIndex].name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Hint Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalMargin * 2,
                ),
                child: ElevatedButton.icon(
                  onPressed: (_hintsUsed >= 2) ? null : _onHintPressed,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('${AppStrings.hintButton} (${2 - _hintsUsed})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.warning,
                    foregroundColor: AppStyles.darkAccent,
                    disabledBackgroundColor: AppStyles.cardBg,
                    disabledForegroundColor: AppStyles.accent.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              // Expanded space 1: Текст подсказки
              Expanded(
                flex: 3,
                child: Center(
                  child: (_currentHintsText.isNotEmpty && !_isTimeUp)
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.horizontalMargin,
                            vertical: 10,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _currentHintsText.map((hint) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppStyles.accent.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppStyles.warning,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    hint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          20, // чуть уменьшил для вместимости
                                      color: AppStyles.bgColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),

              // 3. Question Timer
              Visibility(
                visible: !_isTimeUp,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getQuestionTimerColor(),
                        width: 8,
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _questionTimerRemaining.toString(),
                          style: TextStyle(
                            fontSize: circleSize * 0.4,
                            fontWeight: FontWeight.bold,
                            color: _getQuestionTimerColor(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded space 2: ВРЕМЯ ВЫШЛО текст
              Expanded(
                flex: 2,
                child: Center(
                  child: (_isTimeUp || _isAdditionalTime)
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.timeIsUp,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.redAccent,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        ),

        // Pinned Bottom Actions
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Нотификация "Последний вопрос" - теперь без Positioned, просто анимированная прозрачность
            AnimatedOpacity(
              opacity: _showLastQuestionText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.center,
                child: _showLastQuestionText
                    ? Text(
                        AppStrings.lastQuestionToast,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppStyles.danger,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox(
                        height: 22,
                      ), // Preserve height when invisible to prevent layout jumps
              ),
            ),

            // 6. Action Button ("ДАЛЬШЕ!" / "Завершить раунд")
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalMargin,
              ),
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: ElevatedButton(
                  onPressed: _isTimeUp ? null : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAdditionalTime
                        ? Colors.red.shade700
                        : (_isLastQuestion
                              ? Colors.red.shade600
                              : AppStyles.accent),
                    foregroundColor: (_isAdditionalTime || _isLastQuestion)
                        ? Colors.white
                        : AppStyles.darkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isAdditionalTime
                          ? "${_isLastQuestion ? AppStrings.endRound : AppStrings.nextPlayer} ⏰ $_additionalTimerRemaining"
                          : (_isLastQuestion
                                ? AppStrings.endRound
                                : AppStrings.nextPlayer),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 7. Stop Round Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalMargin,
              ),
              child: ElevatedButton(
                onPressed: _showStopRoundDialog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: AppStyles.danger,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.red.shade900, width: 3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  AppStrings.stopRound,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        // Баннер
        if (!subscribe_payed)
          Container(
            height: 50,
            alignment: Alignment.center,
            margin: EdgeInsets.only(
              top: context.padding2,
              bottom: context.padding2,
            ),
            child: Container(
              width: 320,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Рекламный баннер (320x50)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        if (subscribe_payed) SizedBox(height: context.padding3),
      ],
    );
  }
}
