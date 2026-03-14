import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import 'game_settings_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  // ── Color palette — sandy cream ────────────────────────────────────
  static const Color _bgColor   = Color(0xFFF5E6CC);  // sandy cream
  static const Color _accent    = Color(0xFF6D4C41);   // warm brown (buttons & text)
  static const Color _darkAccent = Color(0xFF3E2723);  // deep espresso (outlines & title stroke)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: _bgColor,
        child: AnimatedPatternBackground(
          backgroundColor: _bgColor,
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
                      foregroundColor: const Color(0xFFFFF8F0), // warm white
                      side: const BorderSide(color: _darkAccent, width: 2.5),
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
                      foregroundColor: _darkAccent,
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
                      foregroundColor: _darkAccent,
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
