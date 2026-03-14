import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/game_rules.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import 'round_score_screen.dart';
import '../widgets/exit_game_button.dart';

class SpyLastWordScreen extends StatefulWidget {
  final GameSession session;

  const SpyLastWordScreen({
    super.key,
    required this.session,
  });

  @override
  State<SpyLastWordScreen> createState() => _SpyLastWordScreenState();
}

class _SpyLastWordScreenState extends State<SpyLastWordScreen> {
  // null = not answered, true = guessed, false = did not guess
  bool? _didGuessRight;

  void _onAnswerPressed(bool val) {
    SoundService.instance.playClick();
    setState(() {
      _didGuessRight = val;
    });
  }

  void _onEndRound() {
    SoundService.instance.playClick();
    if (_didGuessRight == true) {
      widget.session.addScoreToSpy(GameRules.spyGuessedAfterFound);
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RoundScoreScreen(session: widget.session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: AnimatedPatternBackground(
              child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  AppStrings.spyLastWordTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.darkAccent,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Spy Name
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppStyles.danger,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.danger.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Text(
                    widget.session.players[widget.session.currentSpyIndex].name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.spyMustGuess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppStyles.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              // Question
              const Center(
                child: Text(
                  AppStrings.spyGuessedQuestion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.darkAccent,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Buttons Yes/No
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswerButton(
                        text: AppStrings.guessedNo,
                        isYes: false,
                        isSelected: _didGuessRight == false,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildAnswerButton(
                        text: AppStrings.guessedYes,
                        isYes: true,
                        isSelected: _didGuessRight == true,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Complete Round Button (appears after selection)
              if (_didGuessRight != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _onEndRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.accent,
                      foregroundColor: AppStyles.cardBg,
                      side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      AppStrings.endRoundVotes,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                if (_didGuessRight == null) const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      const ExitGameButton(),
      ],
    ),
  );
}

  Widget _buildAnswerButton({
    required String text,
    required bool isYes,
    required bool isSelected,
  }) {
    final Color baseColor = isYes ? Colors.green.shade600 : Colors.red.shade600;
    
    return GestureDetector(
      onTap: () => _onAnswerPressed(isYes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : AppStyles.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected) 
              BoxShadow(
                color: baseColor.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppStyles.darkAccent,
            ),
          ),
        ),
      ),
    );
  }
}
