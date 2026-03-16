import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import 'role_guess_screen.dart';
import 'spy_last_word_screen.dart';
import '../widgets/exit_game_button.dart';

class VotingResultScreen extends StatelessWidget {
  final GameSession session;
  final bool isSpyFound;

  const VotingResultScreen({
    super.key,
    required this.session,
    required this.isSpyFound,
  });

  void _onNext(BuildContext context) {
    SoundService.instance.playClick();
    if (isSpyFound) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoleGuessScreen(session: session)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SpyLastWordScreen(session: session)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Semantic background: green = spy found, red = spy not found
    final Color bgColor = isSpyFound ? AppStyles.success : AppStyles.danger;
    final String text = isSpyFound ? AppStrings.spyFound : AppStrings.spyNotFound;
    final IconData icon = isSpyFound ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          AnimatedPatternBackground(
            lineColor: AppStyles.deriveStripeColor(bgColor),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
              
              // Icon
              Icon(
                icon,
                size: 150,
                color: Colors.white,
              ),
              
              const SizedBox(height: 30),
              
              // Text
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isSpyFound 
                    ? 'Мирные получают по 1 очку.' 
                    : 'Шпион получает 2 очка.\nГотовьтесь к последнему слову!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              
              // Secret Location Display (Tasks 3 & 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Локация была:',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    Text(
                      session.currentSecretLocation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Next button
              Padding(
                padding: const EdgeInsets.all(30),
                child: ElevatedButton(
                  onPressed: () => _onNext(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bgColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    AppStrings.nextPlayer,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
        const ExitGameButton(),
      ],
    ),
  );
  }
}
