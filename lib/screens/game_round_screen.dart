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
import 'accuse_spy_screen.dart';
import 'round_score_screen.dart';
import 'spy_last_word_screen.dart';
import 'voting_result_screen.dart';
import '../widgets/exit_game_button.dart';
import '../widgets/epic_player_card.dart';
import '../utils/context_extensions.dart';

class GameRoundScreen extends StatefulWidget {
  final GameSession session;

  const GameRoundScreen({super.key, required this.session});

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  late List<int> _roundOrder;

  bool _isLastQuestion = false;
  bool _showLastQuestionText = false;
  bool _isTimeUp = false;
  bool _isDisposed = false;

  DateTime _lastNextPressTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _showSpySurrenderNotification = false;
  bool _showEliminatedNotification = false;
  bool _showSuccessAccusationNotification = false;
  bool _isTransitioning = false;
  bool _isPaused = false;

  int _hintsUsed = 0;
  bool _isHintCooldown = false;
  bool _privateHintsExhausted = false;
  final List<String> _currentHintsText = [];
  
  final GlobalKey<EpicPlayerCardState> _cardKey = GlobalKey<EpicPlayerCardState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _roundOrder = List.generate(widget.session.players.length, (i) => i)..shuffle();
    int startPos = 0;
    while (!widget.session.isActivePlayer(_roundOrder[startPos])) {
      startPos = (startPos + 1) % _roundOrder.length;
    }
    _currentAskerIndex = _roundOrder[startPos];
    
    int targetPos = (startPos + 1) % _roundOrder.length;
    while (!widget.session.isActivePlayer(_roundOrder[targetPos])) {
      targetPos = (targetPos + 1) % _roundOrder.length;
    }
    _currentTargetIndex = _roundOrder[targetPos];

    _startTimers();
  }

  void _startTimers() {
    if (_isPaused) return;
    
    _mainTimer?.cancel();
    _questionTimer?.cancel();
    
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mainTimerRemaining > 0 &&
          !_showSpySurrenderNotification &&
          !_isTransitioning) {
        setState(() {
          _mainTimerRemaining--;
        });
      }
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_showSpySurrenderNotification || _isTransitioning) return;

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
            _isTimeUp = true;
            _isTransitioning = true;
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
    final now = DateTime.now();
    if (now.difference(_lastNextPressTime).inSeconds < 3) {
      return; // Защита от двойного клика (кулдаун 3 сек)
    }
    _lastNextPressTime = now;

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
    
    setState(() {
      _isPaused = true;
    });
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
                  // Переход на экран проверки досрочного ответа шпиона
                  _mainTimer?.cancel();
                  _questionTimer?.cancel();
                  storageService.resetPrivateHints(widget.session.currentSecretLocation);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpyLastWordScreen(
                        session: widget.session,
                        isEarlyGuess: true,
                      ),
                    ),
                  );
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  
                  // Если кнопку нажал сам шпион
                  if (_currentAskerIndex == widget.session.currentSpyIndex) {
                    widget.session.addScoreToCivilians(2);
                    widget.session.addScoreToSpy(-3);
                    widget.session.earlyEndReasons[widget.session.currentRound] = 'Шпион добровольно сдался';
                    _mainTimer?.cancel();
                    _questionTimer?.cancel();
                    storageService.resetPrivateHints(widget.session.currentSecretLocation);
                    
                    SoundService.instance.playLocalsWin();
                    
                    setState(() {
                      _showSpySurrenderNotification = true;
                    });
                    
                    return;
                  }
                  
                  // Иначе - переход на экран обвинения
                  _mainTimer?.cancel();
                  _questionTimer?.cancel();
                  
                  final selectedTargetIndex = await Navigator.push<int?>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccuseSpyScreen(
                        session: widget.session,
                        accuserIndex: _currentAskerIndex,
                      ),
                    ),
                  );
                  
                  if (!mounted) return;
                  
                  if (selectedTargetIndex == null) {
                    // Отменили обвинение
                    setState(() {
                      _isPaused = false;
                    });
                    _startTimers();
                    return;
                  }
                  
                  if (selectedTargetIndex == widget.session.currentSpyIndex) {
                    // УГАДАЛ!
                    widget.session.addScoreToSpy(-2);
                    widget.session.addScoreToCivilians(1);
                    widget.session.players[_currentAskerIndex].addScore(1); // Доп бонус обвинителю (+2 в сумме)
                    widget.session.earlyEndReasons[widget.session.currentRound] = 'Кровавый суд (Шпион пойман)';
                    
                    storageService.resetPrivateHints(widget.session.currentSecretLocation);
                    
                    SoundService.instance.playLocalsWin();
                    setState(() {
                      _showSuccessAccusationNotification = true;
                    });
                    
                    Future.delayed(const Duration(seconds: 4), () {
                      if (mounted && _showSuccessAccusationNotification) {
                        setState(() { _showSuccessAccusationNotification = false; });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VotingResultScreen(
                              session: widget.session,
                              isSpyFound: true,
                              customTitle: 'ШПИОН ПОЙМАН!',
                              skipRoleGuess: true,
                            ),
                          ),
                        );
                      }
                    });
                  } else {
                    // ОШИБСЯ!
                    widget.session.players[_currentAskerIndex].addScore(-2); // Штраф обвинителю
                    
                    // Выбывание
                    widget.session.eliminatedPlayers.add(_currentAskerIndex);
                    
                    // Запись для утешительного приза
                    widget.session.falseAccusations[selectedTargetIndex] = _currentAskerIndex;
                    
                    if (widget.session.activePlayersCount < 3) {
                      // Раунд сразу заканчивается - шпиону +2
                      widget.session.addScoreToSpy(2);
                      widget.session.earlyEndReasons[widget.session.currentRound] = 'Осталось мало местных (Шпион победил)';
                      
                      // Победа шпиона
                      storageService.resetPrivateHints(widget.session.currentSecretLocation);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VotingResultScreen(
                            session: widget.session,
                            isSpyFound: false,
                            customTitle: 'ШПИОН НЕ НАЙДЕН!',
                            customSubtitle: 'Осталось слишком мало местных жителей.',
                          ),
                        ),
                      );
                    } else {
                      // Раунд продолжается - шпиону только +1
                      widget.session.addScoreToSpy(1);
                      
                      SoundService.instance.playErrorPavian();
                      setState(() {
                        _showEliminatedNotification = true;
                      });
                      
                      Future.delayed(const Duration(seconds: 4), () {
                        if (mounted && _showEliminatedNotification) {
                          setState(() { _showEliminatedNotification = false; });
                          _transitionToNextPlayer();
                          _startTimers();
                        }
                      });
                    }
                  }
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
                  setState(() {
                    _isPaused = false;
                  });
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
      _additionalTimerRemaining = 0;
    });

    int nextAsker = _currentTargetIndex;
    int nextAskerPos = _roundOrder.indexOf(nextAsker);
    while (!widget.session.isActivePlayer(_roundOrder[nextAskerPos])) {
      nextAskerPos = (nextAskerPos + 1) % _roundOrder.length;
    }
    nextAsker = _roundOrder[nextAskerPos];

    int nextTargetPos = (nextAskerPos + 1) % _roundOrder.length;
    while (!widget.session.isActivePlayer(_roundOrder[nextTargetPos])) {
      nextTargetPos = (nextTargetPos + 1) % _roundOrder.length;
    }
    int nextTarget = _roundOrder[nextTargetPos];

    String topName = widget.session.players[nextAsker].name;
    String bottomName = widget.session.players[nextTarget].name;

    _cardKey.currentState?.flipToNewPlayers(topName, bottomName);

    // Ждем окончания анимации (600 мс) вместо 2 секунд
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _currentAskerIndex = nextAsker;
      _currentTargetIndex = nextTarget;

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
      
      // Штраф: -0.1 очка за просмотр подсказки
      widget.session.players[_currentAskerIndex].addScore(-0.1);
      
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _mainTimer?.cancel();
      _questionTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimers();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
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
    if (_showSpySurrenderNotification) {
      return Scaffold(
        backgroundColor: AppStyles.bgColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showSpySurrenderNotification) {
              setState(() {
                _showSpySurrenderNotification = false;
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VotingResultScreen(
                    session: widget.session,
                    isSpyFound: true,
                    customTitle: 'ШПИОН СДАЛСЯ!',
                    customSubtitle: 'Шпион рассекретил себя без права угадать локацию.',
                    goToScoreDirectly: true,
                  ),
                ),
              );
            }
          },
          child: Container(
            color: AppStyles.bgColor,
            child: SizedBox.expand(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppStyles.danger, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.danger.withValues(alpha: 0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppStyles.danger, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          'ШПИОН СДАЛСЯ!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.danger,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Шпион рассекретил себя без права угадать локацию.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_showEliminatedNotification) {
      return Scaffold(
        backgroundColor: AppStyles.bgColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showEliminatedNotification) {
              setState(() { _showEliminatedNotification = false; });
              _transitionToNextPlayer();
              _startTimers();
            }
          },
          child: Container(
            color: AppStyles.bgColor,
            child: SizedBox.expand(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppStyles.danger, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.danger.withValues(alpha: 0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: AppStyles.danger, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          'КРИТИЧЕСКАЯ\nОШИБКА!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.danger,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Вы обвинили местного жителя!\nВы выбываете из текущего раунда.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_showSuccessAccusationNotification) {
      return Scaffold(
        backgroundColor: AppStyles.bgColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showSuccessAccusationNotification) {
              setState(() { _showSuccessAccusationNotification = false; });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VotingResultScreen(
                    session: widget.session,
                    isSpyFound: true,
                    customTitle: 'ШПИОН ПОЙМАН!',
                    skipRoleGuess: true,
                  ),
                ),
              );
            }
          },
          child: Container(
            color: AppStyles.bgColor,
            child: SizedBox.expand(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppStyles.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.accent.withValues(alpha: 0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppStyles.accent, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          'ШПИОН ПОЙМАН!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Отличная интуиция!\nМестные побеждают.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
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

                    // Main Content
                    Expanded(
                      child: _buildRoundContent(context),
                    ),
                  ],
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
    final double circleSize = (context.screenWidth * 0.3).clamp(80.0, 130.0);
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool isCompact = screenHeight < 720;

    final double hintButtonVerticalPadding = isCompact ? 8.0 : 10.0;
    final double hintContainerHeight = isCompact ? 75.0 : 90.0;
    final double spacingHeight = isCompact ? 16.0 : 24.0;

    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Зафиксированная область, адаптивная под экран
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4. Card with Players
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalMargin * 2,
                ),
                child: Center(
                  child: EpicPlayerCard(
                    key: _cardKey,
                    topName: widget.session.players[_currentAskerIndex].name,
                    bottomName: widget.session.players[_currentTargetIndex].name,
                  ),
                ),
              ),

              SizedBox(height: spacingHeight),

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
                    padding: EdgeInsets.symmetric(vertical: hintButtonVerticalPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              SizedBox(height: spacingHeight),

              // Текст подсказки (занимает зарезервированное место фиксированного размера)
              Expanded(
                child: Center(
                  child: Container(
                    height: hintContainerHeight,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentHintsText.isNotEmpty
                          ? Padding(
                              key: ValueKey(_currentHintsText.join('\n')),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.horizontalMargin,
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppStyles.accent.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppStyles.warning,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _currentHintsText.join('\n'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        color: AppStyles.bgColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: spacingHeight),

              // 3. Блок Таймера / ВРЕМЯ ВЫШЛО / Штрафа
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Таймер (прячем, если время вышло, но размер сохраняем)
                    Visibility(
                      visible: !_isTimeUp && !_isAdditionalTime,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
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

                    // Текст "ВРЕМЯ ВЫШЛО" (показывается вместо таймера)
                    if (_isTimeUp || _isAdditionalTime)
                      FadeTransition(
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
                      ),

                    // Окно штрафа (поверх всего)
                    if (_showPenaltyNotification)
                      IgnorePointer(
                        child: Container(
                          width: context.screenWidth * 0.8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppStyles.danger.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppStyles.cardBg,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.darkAccent.withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: Text(
                            '$_penaltyPlayerName − теряет часть своего очка 😭\n${GameRules.penaltyOvertime}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                        fontSize: 18,
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
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppStyles.danger,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.red.shade900, width: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  AppStrings.stopRound,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/banner.png',
                  width: 320,
                  height: 50,
                  fit: BoxFit.cover,
                  // Делаем баннер черно-белым/серым, чтобы еще меньше отвлекал
                  color: Colors.grey,
                  colorBlendMode: BlendMode.saturation,
                ),
              ),
            ),
          ),
        if (subscribe_payed) SizedBox(height: context.padding3),
      ],
    );
  }
}
