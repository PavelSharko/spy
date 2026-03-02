import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import 'game_settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                'ШПИОН',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GameSettingsScreen()),
                      );
                  },
                  child: const Text('ИГРАТЬ'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    // TODO: Show rules
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Правила игры (Заглушка)')));
                  },
                  child: const Text('ПРАВИЛА ИГРЫ'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    // TODO: System settings
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Настройки (Заглушка)')));
                  },
                  child: const Text('НАСТРОЙКИ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
