import 'package:flutter/material.dart';
import '../utils/app_settings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import '../widgets/menu_button.dart';

/// System settings screen.
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
    if (value) SoundService.instance.playClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppStyles.bgColor,
        child: AnimatedPatternBackground(
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
                    color: AppStyles.darkAccent,
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
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppStyles.accent.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: _soundEnabled ? AppStyles.warning : AppStyles.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Звук',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.darkAccent,
                                ),
                              ),
                              Text(
                                _soundEnabled ? 'Включён' : 'Выключен',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: _soundEnabled,
                          onChanged: _toggleSound,
                          activeColor: AppStyles.accent,
                          inactiveThumbColor: AppStyles.textSecondary,
                          inactiveTrackColor: AppStyles.accent.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Developer features toggle card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppStyles.accent.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bug_report_rounded,
                          color: AppStyles.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Секретные функции разработчика',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.darkAccent,
                                ),
                              ),
                              Text(
                                'По умолчанию выключено',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: AppSettings.instance.developerFeaturesEnabled,
                          onChanged: (value) {
                            setState(() {
                              AppSettings.instance.developerFeaturesEnabled = value;
                            });
                          },
                          activeColor: AppStyles.accent,
                          inactiveThumbColor: AppStyles.textSecondary,
                          inactiveTrackColor: AppStyles.accent.withValues(alpha: 0.12),
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
      ),
    );
  }
}
