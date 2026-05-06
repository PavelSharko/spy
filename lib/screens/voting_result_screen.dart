import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import 'role_guess_screen.dart';
import 'spy_last_word_screen.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SpyLastWordScreen(
          session: session,
          isSpyFound: isSpyFound,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Semantic background: green = spy found, red = spy not found
    final Color bgColor = isSpyFound ? AppStyles.success : AppStyles.danger;
    final String text = isSpyFound
        ? AppStrings.spyFound
        : AppStrings.spyNotFound;
    final IconData icon = isSpyFound
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Icon
                      Icon(icon, size: 150, color: Colors.white),

                      SizedBox(height: context.padding3),

                      // Text
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      SizedBox(height: context.padding2),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalMargin * 2,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
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
                      ),

                      SizedBox(height: context.padding2),

                      // Secret Location Display (Tasks 3 & 4)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Локация была:',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
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
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalMargin * 1.5,
                          context.padding3,
                          context.horizontalMargin * 1.5,
                          context.padding4,
                        ),
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
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.nextPlayer,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const ExitGameButton(),
        ],
      ),
    );
  }
}
