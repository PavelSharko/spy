import 'package:flutter/material.dart';
import '../utils/app_settings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/menu_button.dart';

/// System settings screen.
/// Currently: sound toggle + back button.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = AppSettings.instance.soundEnabled;
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
      AppSettings.instance.soundEnabled = value;
    });
    // Play a test click only if turning ON
    if (value) SoundService.instance.playClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Title
              const Text(
                'НАСТРОЙКИ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 50),

              // Sound toggle card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Icon(
                        _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _soundEnabled ? Colors.amberAccent : Colors.white38,
                        size: 32,
                      ),
                      const SizedBox(width: 16),

                      // Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Звук',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _soundEnabled ? 'Включён' : 'Выключен',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Toggle
                      Switch(
                        value: _soundEnabled,
                        onChanged: _toggleSound,
                        activeColor: Colors.amberAccent,
                        inactiveThumbColor: Colors.white38,
                        inactiveTrackColor: Colors.white12,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Back button
              Padding(
                padding: const EdgeInsets.all(30),
                child: MenuButton(
                  text: '← НАЗАД',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: false,
                  width: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
