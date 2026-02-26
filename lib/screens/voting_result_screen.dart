import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import 'round_score_screen.dart';
import 'spy_last_word_screen.dart';

class VotingResultScreen extends StatelessWidget {
  final GameSession session;
  final bool isSpyFound;

  const VotingResultScreen({
    super.key,
    required this.session,
    required this.isSpyFound,
  });

  void _onNext(BuildContext context) {
    if (isSpyFound) {
      // Spy found -> proceed directly to score screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoundScoreScreen(session: session)),
      );
    } else {
      // Spy not found -> spy gets a chance to guess the location
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SpyLastWordScreen(session: session)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isSpyFound ? Colors.green.shade600 : Colors.red.shade700;
    final String text = isSpyFound ? AppStrings.spyFound : AppStrings.spyNotFound;
    final IconData icon = isSpyFound ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
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
                  fontSize: 20,
                  color: Colors.white70,
                ),
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
                  AppStrings.nextPlayer, // 'ДАЛЬШЕ!' string from before, works well here
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
    );
  }
}
