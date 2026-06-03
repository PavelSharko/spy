import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/app_settings.dart';
import '../utils/sound_service.dart';
import 'main_menu_screen.dart';
import 'pre_game_flow_screen.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';
import '../models/game_history_entry.dart';
import '../services/game_history_service.dart';
import '../widgets/photo_carousel_dialog.dart';

class RoundScoreScreen extends StatefulWidget {
  final GameSession session;

  const RoundScoreScreen({super.key, required this.session});

  @override
  State<RoundScoreScreen> createState() => _RoundScoreScreenState();
}

class _RoundScoreScreenState extends State<RoundScoreScreen> {
  late List<Player> _sortedPlayers;
  late bool _isLastRound;

  @override
  void initState() {
    super.initState();
    _isLastRound = widget.session.currentRound >= widget.session.totalRounds;

    // Save snapshot of round scores for history
    final round = widget.session.currentRound;
    if (!widget.session.roundScoresHistory.containsKey(round)) {
      widget.session.roundScoresHistory[round] = {
        for (var p in widget.session.players) p.name: p.roundScore
      };
      widget.session.spyWonHistory[round] = 
          widget.session.players[widget.session.currentSpyIndex].roundScore > 0;
    }

    // Create a copy to sort without mutating the original list order (though mutating is fine too)
    _sortedPlayers = List.from(widget.session.players);
    _sortedPlayers.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    if (_isLastRound) {
      SoundService.instance.playGameEndAirhorn();
    }
  }

  void _onNextAction() {
    SoundService.instance.playClick();
    if (_isLastRound) {
      // Save game history
      GameHistoryService.saveGame(widget.session);
      
      // Go to main menu
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        (route) => false,
      );
    } else {
      // Prepare next round
      setState(() {
        widget.session.currentRound++;
        widget.session.resetRoundScores();
        widget.session.resetRoundState(); // Reset eliminated players and false accusations
        _isLastRound = widget.session.currentRound >= widget.session.totalRounds;

        // Select new Spy
        widget.session.currentSpyIndex = Random().nextInt(
          widget.session.players.length,
        );
      });

      // Location is already pre-computed in secretLocationsQueue —
      // currentSecretLocation getter returns queue[currentRound - 1] automatically.

      // Navigate to pre game flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PreGameFlowScreen(
            session: widget.session,
            playerCount: widget.session.players.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: Container(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: context.topPadding5),

                        // Title
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.horizontalMargin,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isLastRound
                                    ? "Итоги игры"
                                    : "Раунд ${widget.session.currentRound}: Результаты игры",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppStyles.accent,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: context.padding3),

                        // Winner display if last round
                        if (_isLastRound && _sortedPlayers.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.horizontalMargin,
                            ).copyWith(bottom: context.padding3),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppStyles.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppStyles.accent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    size: 60,
                                    color: AppStyles.warning,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${AppStrings.winnerPrefix}\n${_sortedPlayers.first.name}!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: AppStyles.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),



                        // Button to view photo history of the current game
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.horizontalMargin,
                            vertical: context.padding2,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final List<RoundHistory> allRounds = [];
                              for (int r = 1; r <= widget.session.currentRound; r++) {
                                final spyWon = widget.session.spyWonHistory[r] ?? false;
                                final resultBytes = widget.session.roundFinalCards[r]?[spyWon ? 'win' : 'loss'];
                                final locName = widget.session.secretLocationsQueue[r - 1];
                                final locBytes = widget.session.locationImages[locName];
                                
                                allRounds.add(RoundHistory(
                                  roundNumber: r,
                                  locationName: locName,
                                  locationImageBytes: locBytes,
                                  resultImageBytes: resultBytes,
                                  playerScores: widget.session.roundScoresHistory[r] ?? {},
                                  spyWon: spyWon,
                                  earlyEndReason: widget.session.earlyEndReasons[r],
                                ));
                              }
                              
                              showDialog(
                                context: context,
                                builder: (context) => PhotoCarouselDialog(rounds: allRounds),
                              );
                            },
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            label: Text(
                              'Фото история игры',
                              style: TextStyle(
                                color: AppStyles.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppStyles.accent, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: AppStyles.cardBg,
                            ),
                          ),
                        ),

                        // Players List
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.horizontalMargin,
                            ),
                            itemCount: _sortedPlayers.length,
                            itemBuilder: (context, index) {
                              final player = _sortedPlayers[index];
                              final isFirst = index == 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? AppStyles.accent.withOpacity(0.45)
                                      : AppStyles.cardBg,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppStyles.darkAccent.withOpacity(
                                        0.45,
                                      ),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isFirst
                                        ? AppStyles.accent
                                        : AppStyles.accent.withOpacity(0.4),
                                    width: isFirst ? 3 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Rank
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isFirst
                                            ? AppStyles.textBright
                                            : AppStyles.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isFirst
                                                ? AppStyles.darkAccent
                                                : AppStyles.darkAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Player Avatar
                                    if (player.photoBytes != null) ...[
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppStyles.accent
                                            .withOpacity(0.45),
                                        backgroundImage: MemoryImage(
                                          player.photoBytes!,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],

                                    // Name
                                    Expanded(
                                      child: Text(
                                        player.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isFirst
                                              ? FontWeight.w900
                                              : FontWeight.w500,
                                          color: AppStyles.accent,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Round Score (if not last round or even if last round to show what happened)
                                    if (!_isLastRound || player.roundScore != 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: player.roundScore > 0
                                              ? Colors.green.shade100
                                              : (player.roundScore < 0
                                                    ? Colors.red.shade100
                                                    : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          player.roundScore > 0
                                              ? '+${player.roundScore % 1 == 0 ? player.roundScore.toInt() : player.roundScore.toStringAsFixed(1)}'
                                              : '${player.roundScore % 1 == 0 ? player.roundScore.toInt() : player.roundScore.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: player.roundScore > 0
                                                ? Colors.green.shade800
                                                : (player.roundScore < 0
                                                      ? Colors.red.shade800
                                                      : Colors.grey.shade600),
                                          ),
                                        ),
                                      ),

                                    // Total Score
                                    Text(
                                      '${player.totalScore % 1 == 0 ? player.totalScore.toInt() : player.totalScore.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: isFirst
                                            ? FontWeight.w900
                                            : FontWeight.bold,
                                        color: isFirst
                                            ? AppStyles.darkAccent
                                            : AppStyles.textBright,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Action Button
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalMargin,
                            context.padding2,
                            context.horizontalMargin,
                            context.padding4,
                          ),
                          child: ElevatedButton(
                            onPressed: _onNextAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLastRound
                                  ? AppStyles.accent
                                  : AppStyles.accent,
                              foregroundColor: AppStyles.cardBg,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isLastRound
                                    ? AppStrings.toMainMenu
                                    : AppStrings.nextRound,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
