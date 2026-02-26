import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../data/locations_data.dart';
import '../models/game_session.dart';
import 'voting_screen.dart';
import 'round_score_screen.dart'; // we will create this next

class GameRoundScreen extends StatefulWidget {
  final GameSession session;

  const GameRoundScreen({
    super.key,
    required this.session,
  });

  @override
  State<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends State<GameRoundScreen> {
  late int _mainTimerRemaining;
  int _questionTimerRemaining = 20;

  Timer? _mainTimer;
  Timer? _questionTimer;

  late int _currentAskerIndex;
  late int _currentTargetIndex;

  bool _isLastQuestion = false;
  bool _isTimeUp = false;
  bool _isTransitioning = false;

  int _hintsUsed = 0;
  bool _isHintCooldown = false;
  List<String> _currentHintsText = [];
  List<String> _locationHints = [];

  @override
  void initState() {
    super.initState();
    _mainTimerRemaining = widget.session.gameTime * 60;
    
    // Setup initial players
    _currentAskerIndex = Random().nextInt(widget.session.players.length);
    _currentTargetIndex = (_currentAskerIndex + 1) % widget.session.players.length;

    // Load available hints for the location
    _loadLocationHints();

    _startTimers();
  }

  void _loadLocationHints() {
    for (var group in LocationsData.groups) {
      for (var loc in group['locations']) {
        if (loc['name'] == widget.session.currentSecretLocation) {
          _locationHints = List<String>.from(loc['hints']);
          break;
        }
      }
    }
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
        }

        if (_questionTimerRemaining == 0) {
          _onQuestionTimeUp();
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
    if (_isLastQuestion) {
      _navigateToVoting();
    } else {
      _transitionToNextPlayer();
    }
  }

  void _navigateToVoting() {
    _mainTimer?.cancel();
    _questionTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => VotingScreen(session: widget.session)),
    );
  }

  void _showStopRoundDialog() {
    // Pause timers
    _mainTimer?.cancel();
    _questionTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppStrings.whatHappened,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(AppStrings.spyGuessedLoc, textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text(AppStrings.spyFailed, textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Ничего, играем дальше -> resume timers
                  _startTimers();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text(AppStrings.continueGame, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RoundScoreScreen(session: widget.session)),
    );
  }

  void _transitionToNextPlayer() async {
    setState(() {
      _isTransitioning = true;
      _isTimeUp = false;
    });

    // Simulate transition delay (1 second) for the rotation animation (which will be in the build method)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _currentAskerIndex = _currentTargetIndex;
      _currentTargetIndex = (_currentTargetIndex + 1) % widget.session.players.length;

      _hintsUsed = 0;
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
      const SnackBar(
        content: Text(
          AppStrings.lastQuestionToast,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onHintPressed() {
    if (_isHintCooldown || _hintsUsed >= 2 || _locationHints.isEmpty) return;

    setState(() {
      _isHintCooldown = true;
      String newHint = _locationHints[Random().nextInt(_locationHints.length)];
      _currentHintsText.add(newHint);
      _hintsUsed++;
    });

    // Reset cooldown after 0.5s
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isHintCooldown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _questionTimer?.cancel();
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
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              
                // 1. Main Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${AppStrings.roundPrefix}${widget.session.currentRound}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
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
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync, color: Colors.white, size: 80),
                                SizedBox(height: 20),
                                Text(
                                  AppStrings.transitionText,
                                  style: TextStyle(
                                    color: Colors.white,
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
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    color: Colors.blue.shade900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.arrow_downward, size: 30, color: Colors.blueAccent),
                ),
                Text(
                  widget.session.players[_currentTargetIndex].name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
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
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
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
              backgroundColor: Colors.amber.shade400,
              foregroundColor: Colors.blue.shade900,
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
          child: ElevatedButton(
            onPressed: _isTimeUp ? null : _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLastQuestion ? Colors.red.shade600 : Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 6,
            ),
            child: Text(
              _isLastQuestion ? AppStrings.endRound : AppStrings.nextPlayer,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 7. Stop Round Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
          child: OutlinedButton(
            onPressed: _showStopRoundDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white.withOpacity(0.9),
            ),
            child: const Text(
              AppStrings.stopRound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
