import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';

class AccuseSpyScreen extends StatefulWidget {
  final GameSession session;
  final int accuserIndex;

  const AccuseSpyScreen({
    super.key,
    required this.session,
    required this.accuserIndex,
  });

  @override
  State<AccuseSpyScreen> createState() => _AccuseSpyScreenState();
}

class _AccuseSpyScreenState extends State<AccuseSpyScreen> {
  int? _selectedCandidateIndex;
  late final List<int> _candidates;

  @override
  void initState() {
    super.initState();
    // Candidates are all active players except the accuser
    _candidates = [
      for (int i = 0; i < widget.session.players.length; i++)
        if (i != widget.accuserIndex && widget.session.isActivePlayer(i)) i
    ];
  }

  void _onConfirmVote() {
    if (_selectedCandidateIndex == null) return;
    SoundService.instance.playClick();
    
    // Return the selected candidate index back to the caller (GameRoundScreen)
    Navigator.pop(context, _selectedCandidateIndex);
  }

  void _onCancel() {
    SoundService.instance.playClick();
    Navigator.pop(context, null); // Cancelled accusation
  }

  @override
  Widget build(BuildContext context) {
    final accplayerName = widget.session.players[widget.accuserIndex].name;
    
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      SizedBox(height: context.topPadding5),

                      // Title
                      Text(
                        'КТО ШПИОН?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.danger,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: 10),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$accplayerName готов раскрыть шпиона!\nЕсли вы ошибетесь — вы выбываете, а шпион получает очки.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppStyles.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

                      // Candidates List
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _candidates.length,
                          itemBuilder: (context, index) {
                            final playerIndex = _candidates[index];
                            final bool isSelected = _selectedCandidateIndex == playerIndex;
                            final bool isAlreadyAccused = widget.session.falseAccusations.containsKey(playerIndex);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: GestureDetector(
                                onTap: isAlreadyAccused ? null : () {
                                  SoundService.instance.playClick();
                                  setState(() {
                                    _selectedCandidateIndex = playerIndex;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isAlreadyAccused
                                        ? AppStyles.cardBg.withValues(alpha: 0.4)
                                        : (isSelected ? AppStyles.danger.withValues(alpha: 0.8) : AppStyles.cardBg),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected ? AppStyles.textBright : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Player avatar
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isAlreadyAccused 
                                            ? Colors.grey.withValues(alpha: 0.2)
                                            : (isSelected
                                                ? AppStyles.darkAccent.withValues(alpha: 0.3)
                                                : AppStyles.accent.withValues(alpha: 0.15)),
                                        backgroundImage: widget.session.players[playerIndex].photoBytes != null
                                            ? MemoryImage(widget.session.players[playerIndex].photoBytes!)
                                            : null,
                                        child: widget.session.players[playerIndex].photoBytes == null
                                            ? Icon(
                                                Icons.person,
                                                color: isAlreadyAccused 
                                                    ? Colors.grey.withValues(alpha: 0.5) 
                                                    : (isSelected ? Colors.white70 : AppStyles.textSecondary),
                                                size: 22,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.session.players[playerIndex].name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isAlreadyAccused 
                                                ? AppStyles.textSecondary.withValues(alpha: 0.5)
                                                : (isSelected ? Colors.white : AppStyles.primaryAccent),
                                            decoration: isAlreadyAccused ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 15),

                      // Buttons
                      Padding(
                        padding: EdgeInsets.fromLTRB(context.horizontalMargin, 0, context.horizontalMargin, context.padding4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: _onCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyles.cardBg,
                                  foregroundColor: AppStyles.textBright,
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: AppStyles.accent, width: 2),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'ОТМЕНА',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              flex: 4,
                              child: ElevatedButton(
                                onPressed: _selectedCandidateIndex == null ? null : _onConfirmVote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyles.danger,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppStyles.cardBg,
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: Colors.transparent, width: 2),
                                  ),
                                  elevation: 5,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'ЭТО ШПИОН!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedCandidateIndex != null ? Colors.white : AppStyles.textSecondary2,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
