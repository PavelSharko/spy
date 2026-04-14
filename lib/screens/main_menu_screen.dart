import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_service.dart';
import 'game_settings_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import '../utils/app_styles.dart';

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
                SizedBox(
                  width: 220,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GameSettingsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: AppStyles.primaryBg, // warm white -> primaryBg to contrast yellow
                      side: BorderSide(color: _darkAccent, width: 2.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      elevation: 6,
                    ),
                    child: const Text('ИГРАТЬ'),
                  ),
                ),
                const SizedBox(height: 18),

                // ── RULES button ─────────────────────────────────────
                SizedBox(
                  width: 220,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RulesScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _accent.withValues(alpha: 0.08),
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('ПРАВИЛА ИГРЫ'),
                  ),
                ),
                const SizedBox(height: 14),

                // ── SETTINGS button ──────────────────────────────────
                SizedBox(
                  width: 220,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _accent.withValues(alpha: 0.08),
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('НАСТРОЙКИ'),
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
