import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/app_settings.dart';
import '../utils/sound_service.dart';
import 'spy_last_word_screen.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';

class VotingResultScreen extends StatefulWidget {
  final GameSession session;
  final bool isSpyFound;

  const VotingResultScreen({
    super.key,
    required this.session,
    required this.isSpyFound,
  });

  @override
  State<VotingResultScreen> createState() => _VotingResultScreenState();
}

class _VotingResultScreenState extends State<VotingResultScreen> {
  Timer? _pollingTimer;
  Uint8List? _cardBytes;

  @override
  void initState() {
    super.initState();
    _checkCard();
    // Start polling if card is not ready yet and unique cards are enabled
    if (AppSettings.instance.uniqueCardsEnabled && _cardBytes == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _checkCard();
      });
    }

    // Play sound based on the voting result
    if (widget.isSpyFound) {
      // Locals successfully found the spy
      SoundService.instance.playLocalsWin();
    } else {
      // Spy successfully hid
      SoundService.instance.playSpyWin();
    }
  }

  void _checkCard() {
    final round = widget.session.currentRound;
    final cards = widget.session.roundFinalCards[round];
    // If spy is found, spy lost (loss). If spy not found, spy won (win).
    final String cardKey = widget.isSpyFound ? 'loss' : 'win';
    final bytes = cards?[cardKey];

    if (bytes != null) {
      if (mounted) {
        setState(() {
          _cardBytes = bytes;
        });
      }
      _pollingTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _onNext(BuildContext context) {
    SoundService.instance.playClick();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SpyLastWordScreen(
          session: widget.session,
          isSpyFound: widget.isSpyFound,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final String titleText = widget.isSpyFound
        ? 'ШПИОН НАЙДЕН!'
        : 'ШПИОН НЕ НАЙДЕН!';

    final String subtitleText = widget.isSpyFound
        ? 'мирные получают по 1 очку\nно шпион вправе попробовать угадать локацию'
        : 'шпион получает 2 очка\nи возможность угадать локацию!';

    final Color accentColor = widget.isSpyFound ? Colors.greenAccent : Colors.redAccent;
    final Color containerColor = widget.isSpyFound ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: AppStyles.primaryBg,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalMargin,
                    vertical: context.padding2,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: (screenHeight * 0.06).clamp(16.0, 48.0)),

                      // 1. Top Header Verdict Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: containerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                titleText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.russoOne(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitleText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer above Card to push it down
                      const Spacer(),

                      // 2. Card / Image Area (Centered dynamically)
                      Container(
                        height: (screenHeight * 0.40).clamp(240.0, 420.0),
                        width: (screenWidth * 0.70).clamp(200.0, 360.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildCardContent(),
                        ),
                      ),

                      // Spacer below Card to push it up
                      const Spacer(),

                      // 3. Bottom Action Button
                      SizedBox(
                        width: (screenWidth * 0.65).clamp(200.0, 300.0),
                        height: (screenHeight * 0.07).clamp(48.0, 60.0),
                        child: ElevatedButton(
                          onPressed: () => _onNext(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.accent,
                            foregroundColor: AppStyles.bgColor,
                            side: BorderSide(
                              color: AppStyles.darkAccent,
                              width: 2.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: AppStyles.buttonTextStyle,
                            elevation: 6,
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.nextPlayer,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: context.padding2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const ExitGameButton(),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    if (_cardBytes != null && AppSettings.instance.uniqueCardsEnabled) {
      return Image.memory(
        _cardBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Default fallback image depending on spy win/lose state.
    // isSpyFound == true means Spy Lost.
    // isSpyFound == false means Spy Won.
    final String defaultImagePath = widget.isSpyFound
        ? 'assets/images/card_after_round_defolt_spy_lose.jpeg'
        : 'assets/images/card_after_round_defolt_spy_win.jpeg';

    return Image.asset(
      defaultImagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

