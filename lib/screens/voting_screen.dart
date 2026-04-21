import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import 'voting_result_screen.dart';
import '../widgets/exit_game_button.dart';
import '../utils/context_extensions.dart';

class VotingScreen extends StatefulWidget {
  final GameSession session;

  const VotingScreen({super.key, required this.session});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late List<int> _votes;
  late List<int> _votingQueue;
  int _currentVoterIndexInQueue = 0;

  int? _selectedCandidateIndex;

  // If there is a tie, this list will contain the indices of the tied players
  List<int> _tieCandidates = [];

  bool _showTieNotification = false;

  @override
  void initState() {
    super.initState();
    _startVotingRound();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startVotingRound() {
    _votes = List.filled(widget.session.players.length, 0);
    _votingQueue = List.generate(widget.session.players.length, (i) => i)
      ..shuffle();
    _currentVoterIndexInQueue = 0;
    _selectedCandidateIndex = null;
  }

  void _onConfirmVote() {
    if (_selectedCandidateIndex == null) return;
    SoundService.instance.playClick();

    setState(() {
      _votes[_selectedCandidateIndex!]++;

      _currentVoterIndexInQueue++;
      _selectedCandidateIndex = null;

      if (_currentVoterIndexInQueue >= _votingQueue.length) {
        _tallyVotes();
      }
    });
  }

  void _tallyVotes() {
    int maxVotes = 0;
    for (int v in _votes) {
      if (v > maxVotes) maxVotes = v;
    }

    List<int> tiedIndices = [];
    for (int i = 0; i < _votes.length; i++) {
      if (_votes[i] == maxVotes) {
        tiedIndices.add(i);
      }
    }

    if (tiedIndices.length > 1) {
      // Tie breaker
      setState(() {
        _tieCandidates = tiedIndices;
        _showTieNotification = true;
      });
      _playTieSound();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _showTieNotification) {
          setState(() {
            _showTieNotification = false;
            _startVotingRound();
          });
        }
      });
    } else {
      // Winner decided
      int chosenIndex = tiedIndices.first;
      bool isSpyFound = chosenIndex == widget.session.currentSpyIndex;

      if (isSpyFound) {
        widget.session.addScoreToCivilians(1);
      } else {
        widget.session.addScoreToSpy(2);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VotingResultScreen(
            session: widget.session,
            isSpyFound: isSpyFound,
          ),
        ),
      );
    }
  }

  void _playTieSound() async {
    SoundService.instance.playTiePig();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTieNotification) {
      return Scaffold(
        backgroundColor: AppStyles.bgColor,
        body: GestureDetector(
          onTap: () {
            if (_showTieNotification) {
              setState(() {
                _showTieNotification = false;
                _startVotingRound();
              });
            }
          },
          child: Container(
            color: const Color(0xFF1565C0),
            child: Container(
              child: const SizedBox.expand(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Одинаковое количество голосов\nнадо переголосовать !!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_currentVoterIndexInQueue >= _votingQueue.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int currentVoter = _votingQueue[_currentVoterIndexInQueue];

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
                      children: [
                        SizedBox(height: context.topPadding5),

                        // Title
                        Text(
                          AppStrings.votingTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.accent,
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: 30),

                        // Current Voter
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppStyles.cardBg,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.darkAccent.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.votingPlayerPrefix.trim(),
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: AppStyles.textBright,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                widget.session.players[currentVoter].name,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppStyles.textBright,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // Prompt
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.votePrompt,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: context.padding2),

                        // Candidates Keyboard
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: widget.session.players.length,
                            itemBuilder: (context, index) {
                              if (index == currentVoter)
                                return const SizedBox.shrink();

                              if (_tieCandidates.isNotEmpty &&
                                  !_tieCandidates.contains(index)) {
                                return const SizedBox.shrink();
                              }

                              bool isSelected =
                                  _selectedCandidateIndex == index;

                              return Padding(
                                padding: EdgeInsets.only(bottom: 15),
                                child: GestureDetector(
                                  onTap: () {
                                    SoundService.instance.playClick();
                                    setState(() {
                                      _selectedCandidateIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppStyles.accent
                                          : AppStyles.cardBg,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppStyles.darkAccent
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Player avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isSelected
                                              ? AppStyles.darkAccent.withValues(
                                                  alpha: 0.3,
                                                )
                                              : AppStyles.accent.withValues(
                                                  alpha: 0.15,
                                                ),
                                          backgroundImage:
                                              widget
                                                      .session
                                                      .players[index]
                                                      .photoBytes !=
                                                  null
                                              ? MemoryImage(
                                                  widget
                                                      .session
                                                      .players[index]
                                                      .photoBytes!,
                                                )
                                              : null,
                                          child:
                                              widget
                                                      .session
                                                      .players[index]
                                                      .photoBytes ==
                                                  null
                                              ? Icon(
                                                  Icons.person,
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : AppStyles.textSecondary,
                                                  size: 22,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.session.players[index].name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppStyles.darkAccent
                                                  : AppStyles.primaryAccent,
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

                        // Votes counter summary
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 5,
                            children: List.generate(
                              widget.session.players.length,
                              (index) {
                                if (_tieCandidates.isNotEmpty &&
                                    !_tieCandidates.contains(index))
                                  return const SizedBox.shrink();
                                return Text(
                                  '${widget.session.players[index].name}: ${_votes[index]}',
                                  style: TextStyle(
                                    color: AppStyles.textSecondary,
                                    fontSize: 18,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        // Confirm Button
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalMargin,
                            context.padding2,
                            context.horizontalMargin,
                            context.padding4,
                          ),
                          child: ElevatedButton(
                            onPressed: _selectedCandidateIndex == null
                                ? null
                                : _onConfirmVote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.accent,
                              foregroundColor: AppStyles.cardBg,
                              disabledBackgroundColor: AppStyles.cardBg,
                              side: BorderSide(
                                color: AppStyles.darkAccent,
                                width: 2,
                              ),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.confirmVote,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedCandidateIndex != null
                                      ? AppStyles.primaryBg
                                      : AppStyles.textSecondary2,
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
          const ExitGameButton(),
        ],
      ),
    );
  }
}
