import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import 'main_menu_screen.dart';
import 'pre_game_flow_screen.dart';
import '../widgets/exit_game_button.dart';

class RoundScoreScreen extends StatefulWidget {
  final GameSession session;

  const RoundScoreScreen({
    super.key,
    required this.session,
  });

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
    
    // Create a copy to sort without mutating the original list order (though mutating is fine too)
    _sortedPlayers = List.from(widget.session.players);
    _sortedPlayers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
  }

  void _onNextAction() {
    SoundService.instance.playClick();
    if (_isLastRound) {
      // Go to main menu
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        (route) => false,
      );
    } else {
      // Prepare next round
      widget.session.currentRound++;
      widget.session.resetRoundScores();

      // Select new Spy
      widget.session.currentSpyIndex =
          Random().nextInt(widget.session.players.length);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
              
              // Title
              Center(
                child: Text(
                  _isLastRound ? "Итоги игры" : AppStrings.roundScoreTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.accent,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Winner display if last round
              if (_isLastRound && _sortedPlayers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1).copyWith(bottom: 30),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppStyles.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppStyles.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 60, color: AppStyles.warning),
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

              // Subtitle
              if (!_isLastRound)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: Text(
                      '${AppStrings.roundPrefix}${widget.session.currentRound}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

              // Final round card (generated AI art)
              Builder(builder: (context) {
                final round = widget.session.currentRound;
                final cards = widget.session.roundFinalCards[round];
                // Determine which card to show based on whether spy won this round
                // We check if spy's round score is positive (spy won) or not
                final spyWon = widget.session.players[widget.session.currentSpyIndex].roundScore > 0;
                final Uint8List? cardBytes = cards?[spyWon ? 'win' : 'loss'];

                if (cardBytes == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(
                      cardBytes,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                );
              }),

              // Players List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _sortedPlayers[index];
                    final isFirst = index == 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isFirst 
                            ? AppStyles.accent.withOpacity(0.45)
                            : AppStyles.cardBg,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.darkAccent.withOpacity(0.45),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isFirst ? AppStyles.accent : AppStyles.accent.withOpacity(0.4),
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
                              color: isFirst ? AppStyles.textBright : AppStyles.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isFirst ? AppStyles.darkAccent : AppStyles.darkAccent,
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
                              backgroundColor: AppStyles.accent.withOpacity(0.45),
                              backgroundImage: MemoryImage(player.photoBytes!),
                            ),
                            const SizedBox(width: 10),
                          ],
                          
                          // Name
                          Expanded(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isFirst ? FontWeight.w900 : FontWeight.w500,
                                color: isFirst ? AppStyles.darkAccent : AppStyles.accent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Round Score (if not last round or even if last round to show what happened)
                          if (!_isLastRound || player.roundScore != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: player.roundScore > 0 ? Colors.green.shade100 : (player.roundScore < 0 ? Colors.red.shade100 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                player.roundScore > 0 ? '+${player.roundScore % 1 == 0 ? player.roundScore.toInt() : player.roundScore.toStringAsFixed(1)}' : '${player.roundScore % 1 == 0 ? player.roundScore.toInt() : player.roundScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: player.roundScore > 0 ? Colors.green.shade800 : (player.roundScore < 0 ? Colors.red.shade800 : Colors.grey.shade600),
                                ),
                              ),
                            ),
                            
                          // Total Score
                          Text(
                            '${player.totalScore % 1 == 0 ? player.totalScore.toInt() : player.totalScore.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: isFirst ? FontWeight.w900 : FontWeight.bold,
                              color: isFirst ? AppStyles.darkAccent : AppStyles.textBright,
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
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _onNextAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLastRound ? AppStyles.accent : AppStyles.accent,
                    foregroundColor: AppStyles.cardBg,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    _isLastRound ? AppStrings.toMainMenu : AppStrings.nextRound,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      const ExitGameButton(),
    ],
  ),
);
}
}
