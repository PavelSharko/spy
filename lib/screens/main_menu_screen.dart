import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_service.dart';
import 'game_settings_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import '../utils/app_styles.dart';
import '../widgets/common/game_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  // ── Color palette ────────────────────────────────────
  static Color get _bgColor => AppStyles.bgColor;
  static Color get _accent => AppStyles.accent;
  static Color get _darkAccent => AppStyles.darkAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Container(
        color: _bgColor,
        child: Container(
          color: _bgColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Cartoonish title with stroke ──────────────────────
                Stack(
                  children: [
                    // Stroke / outline layer
                    Text(
                      'ШПИОН',
                      style: GoogleFonts.russoOne(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 5
                          ..color = _darkAccent,
                      ),
                    ),
                    // Fill layer on top
                    Text(
                      'ШПИОН',
                      style: GoogleFonts.russoOne(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // ── PLAY button ──────────────────────────────────────
                GameButton(
                  text: 'ИГРАТЬ',
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GameSettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 18),

                GameButton(
                  text: 'ПРАВИЛА ИГРЫ',
                  type: GameButtonType.secondary,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RulesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                GameButton(
                  text: 'НАСТРОЙКИ',
                  type: GameButtonType.secondary,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
