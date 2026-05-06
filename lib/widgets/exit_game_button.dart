import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

class ExitGameButton extends StatelessWidget {
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const ExitGameButton({super.key, this.onPause, this.onResume});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40, // typical safe area
      right: 20,
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppStyles.textBright,
              width: 1.5,
            ),
          ),
          child: Icon(Icons.close, color: AppStyles.textBright, size: 24),
        ),
        onPressed: () {
          SoundService.instance.playClick();
          // Pause the game if necessary
          onPause?.call();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext ctx) {
              return AlertDialog(
                backgroundColor: AppStyles.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Внимание',
                  style: TextStyle(
                    color: AppStyles.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: Text(
                  'Вы действительно хотите выйти?',
                  style: TextStyle(
                    color: AppStyles.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.of(ctx).pop();
                      onResume?.call();
                    },
                    child: Text(
                      'Нет',
                      style: TextStyle(
                        color: AppStyles.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      // Navigate to start screen and clear stack
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MainMenuScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text(
                      'Да',
                      style: TextStyle(
                        color: AppStyles.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
