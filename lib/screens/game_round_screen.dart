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

class GameRoundScreen extends StatefulWidget {
  final GameSession session;

  const GameRoundScreen({
    super.key,
    required this.session,
  });

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> with SingleTickerProviderStateMixin {
  late int _mainTimerRemaining;
  int _questionTimerRemaining = 20;

  int _additionalTimerRemaining = 0;
  bool _isAdditionalTime = false;

  // Penalty notification
  bool _showPenaltyNotification = false;
  String _penaltyPlayerName = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _mainTimer;
  Timer? _questionTimer;

  late int _currentAskerIndex;
  late int _currentTargetIndex;

  bool _isLastQuestion = false;
  bool _isTimeUp = false;
  bool _isTransitioning = false;

  int _hintsUsed = 0;
  bool _isHintCooldown = false;
  bool _privateHintsExhausted = false;
  List<String> _currentHintsText = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        }
      });

    _mainTimerRemaining = widget.session.gameTime * 60;
    
    // Setup initial players
    _currentAskerIndex = Random().nextInt(widget.session.players.length);
    _currentTargetIndex = (_currentAskerIndex + 1) % widget.session.players.length;

    _startTimers();
  }

  void _startTimers() {
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mainTimerRemaining > 0 && !_isTimeUp && !_isTransitioning && !_isLastQuestion) {
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
            final penalisedPlayer = widget.session.players[_currentAskerIndex];
            penalisedPlayer.addScore(GameRules.penaltyOvertime);
            _showPenalty(penalisedPlayer.name);
            _onQuestionTimeUp();
          }
        }
      });
    });
  }

  void _onQuestionTimeUp() async {
    setState(() {
      _isTimeUp = true;
    });

    // Wait 2 seconds showing "ВРЕМЯ ВЫШЛО!"
    await Future.delayed(const Duration(seconds: 2));

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
      MaterialPageRoute(builder: (context) => VotingScreen(session: widget.session)),
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
          backgroundColor: AppStyles.bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppStyles.darkAccent.withValues(alpha: 0.1), width: 2),
          ),
          title: Text(
            AppStrings.whatHappened,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: AppStyles.accent),
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
                  backgroundColor: AppStyles.success,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.green.shade900, width: 2),
                ),
                child: const Text(AppStrings.spyGuessedLoc, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
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
                  backgroundColor: AppStyles.danger,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.red.shade900, width: 2),
                ),
                child: const Text(AppStrings.spyCaught, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Ничего, играем дальше -> resume timers
                  _startTimers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.warning,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.orange.shade900, width: 2),
                ),
                child: const Text(AppStrings.continueGame, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
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
      MaterialPageRoute(builder: (context) => RoundScoreScreen(session: widget.session)),
    );
  }

  void _transitionToNextPlayer() async {
    setState(() {
      _isTransitioning = true;
      _isTimeUp = false;
      _isAdditionalTime = false;
      _additionalTimerRemaining = 0;
    });

    // Simulate transition delay (1 second) for the rotation animation (which will be in the build method)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _currentAskerIndex = _currentTargetIndex;
      _currentTargetIndex = (_currentTargetIndex + 1) % widget.session.players.length;

      _hintsUsed = 0;
      _privateHintsExhausted = false;
      _currentHintsText.clear();
      _questionTimerRemaining = 20;

      // Check if it's the last question based on the main timer
      if (_mainTimerRemaining <= 20) {
        _isLastQuestion = true;
        _showLastQuestionToast();
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
        backgroundColor: AppStyles.danger,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPenalty(String playerName) {
    setState(() {
      _penaltyPlayerName = playerName;
      _showPenaltyNotification = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showPenaltyNotification = false);
    });
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
          widget.session.currentSecretLocation);
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
    if (_questionTimerRemaining <= 5) return Colors.red;
    if (_questionTimerRemaining <= 10) return Colors.orange; // yellow/orange
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: Container(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 1. Main Timer
                Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppStyles.darkAccent.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
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
                                  color: AppStyles.accent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                _formatTime(_mainTimerRemaining),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('СКИП\nТАЙМЕРА', textAlign: TextAlign.center),
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
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return RotationTransition(
                          turns: Tween<double>(begin: -0.5, end: 0.0).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: _isTransitioning
                          ? Center(
                              key: const ValueKey('transition'),
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: AppStyles.accent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync, color: AppStyles.accent, size: 80),
                                SizedBox(height: 20),
                                    Text(
                                      AppStrings.transitionText,
                                      style: TextStyle(
                                        color: AppStyles.darkAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppStyles.danger.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppStyles.cardBg, width: 2),
                  boxShadow: [BoxShadow(color: AppStyles.darkAccent.withValues(alpha: 0.5), blurRadius: 20)],
                    ),
                    child: Text(
                      '$_penaltyPlayerName − теряет часть своего очка 😭\n${GameRules.penaltyOvertime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
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
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2. Current turn text
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  Text(
                    widget.session.players[_currentAskerIndex].name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.accent,
                    ),
                  ),
                  Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward, size: 45, color: AppStyles.accent),
                  ),
                  Text(
                    widget.session.players[_currentTargetIndex].name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const Spacer(),

        // 3. Question Timer (20s)
        if (_isTimeUp)
          Text(
            AppStrings.timeIsUp,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 2,
            ),
          )
        else
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getQuestionTimerColor(),
                  width: 8,
                ),
              ),
              child: Center(
                child: Text(
                  _questionTimerRemaining.toString(),
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: _getQuestionTimerColor(),
                  ),
                ),
              ),
            ),
          ),

        const Spacer(),

        // 4. Hints Display
        if (_currentHintsText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: _currentHintsText.map((hint) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyles.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppStyles.warning, width: 2),
                  ),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      color: AppStyles.darkAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // 5. Hint Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton.icon(
            onPressed: (_hintsUsed >= 2) ? null : _onHintPressed,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text('${AppStrings.hintButton} (${2 - _hintsUsed})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.warning,
              foregroundColor: AppStyles.darkAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 6. Action Button ("ДАЛЬШЕ!" / "Завершить раунд")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: ElevatedButton(
              onPressed: _isTimeUp ? null : _onNextPressed,
              style: ElevatedButton.styleFrom(
                // Red during overtime flash, otherwise normal colour
                backgroundColor: _isAdditionalTime
                    ? Colors.red.shade700
                    : (_isLastQuestion ? Colors.red.shade600 : AppStyles.accent),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
              ),
              child: Text(
                _isAdditionalTime
                    ? "${_isLastQuestion ? AppStrings.endRound : AppStrings.nextPlayer} ⏰ $_additionalTimerRemaining"
                    : (_isLastQuestion ? AppStrings.endRound : AppStrings.nextPlayer),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 100),

        // 7. Stop Round Button
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
            child: ElevatedButton(
              onPressed: _showStopRoundDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.danger,
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.red.shade900, width: 3),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
              ),
              child: const Text(
                AppStrings.stopRound,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
