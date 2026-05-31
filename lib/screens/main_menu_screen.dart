import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_service.dart';
import 'game_settings_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import '../utils/app_styles.dart';
import '../widgets/common/game_button.dart';
import '../utils/context_extensions.dart';
import 'game_history_screen.dart';

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ), // Ограничение для планшетов
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Cartoonish title with stroke ──────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalMargin,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Stack(
                      children: [
                        // Stroke / outline layer
                        Text(
                          'ШПИОН',
                          style: GoogleFonts.russoOne(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6
                              ..color = _darkAccent,
                          ),
                        ),
                        // Fill layer on top
                        Text(
                          'ШПИОН',
                          style: GoogleFonts.russoOne(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.08),

                // ── PLAY button ──────────────────────────────────────
                GameButton(
                  text: 'ИГРАТЬ',
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameSettingsScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.padding2),

                GameButton(
                  text: 'ПРАВИЛА ИГРЫ',
                  type: GameButtonType.secondary,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RulesScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.padding2),

                GameButton(
                  text: 'ИСТОРИЯ ИГР',
                  type: GameButtonType.secondary,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameHistoryScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.padding2),

                GameButton(
                  text: 'НАСТРОЙКИ',
                  type: GameButtonType.secondary,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
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
