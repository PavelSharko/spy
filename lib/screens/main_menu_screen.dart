import 'package:flutter/material.dart';
import '../utils/app_images.dart';
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
        decoration: AppStyles.mainBackgroundDecoration,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  AppImages.appIcon,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
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
