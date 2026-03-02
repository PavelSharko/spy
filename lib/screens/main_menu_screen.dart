import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import 'game_settings_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

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
              // Logo icon
              const Icon(
                Icons.security,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'ШПИОН',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 50),

              // PLAY
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

              // RULES
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RulesScreen()),
                    );
                  },
                  child: const Text('ПРАВИЛА ИГРЫ'),
                ),
              ),
              const SizedBox(height: 20),

              // SETTINGS
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
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
