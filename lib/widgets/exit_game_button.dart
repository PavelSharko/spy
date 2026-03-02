import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';
import '../utils/sound_service.dart';

class ExitGameButton extends StatelessWidget {
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const ExitGameButton({
    super.key,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40, // typical safe area
      right: 20,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 30),
        onPressed: () {
          SoundService.instance.playClick();
          // Pause the game if necessary
          onPause?.call();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext ctx) {
              return AlertDialog(
                title: const Text('Внимание'),
                content: const Text('Вы действительно хотите выйти?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.of(ctx).pop();
                      onResume?.call();
                    },
                    child: const Text('Нет'),
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
                    child: const Text('Да', style: TextStyle(color: Colors.red)),
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
