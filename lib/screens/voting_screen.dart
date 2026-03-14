import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import 'voting_result_screen.dart';
import '../widgets/exit_game_button.dart';

class VotingScreen extends StatefulWidget {
  final GameSession session;

  const VotingScreen({
    super.key,
    required this.session,
  });

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
    _votingQueue = List.generate(widget.session.players.length, (i) => i)..shuffle();
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
            child: AnimatedPatternBackground(
              lineColor: AppStyles.deriveStripeColor(const Color(0xFF1565C0)),
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
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: AnimatedPatternBackground(
              child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
              
              // Title
              const Text(
                AppStrings.votingTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.darkAccent,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 30),

              // Current Voter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: AppStyles.cardBg,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.darkAccent.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Text(
                  '${AppStrings.votingPlayerPrefix}${widget.session.players[currentVoter].name}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.darkAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Prompt
              Text(
                AppStrings.votePrompt,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppStyles.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Candidates Keyboard
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.session.players.length,
                  itemBuilder: (context, index) {
                    if (index == currentVoter) return const SizedBox.shrink();
                    
                    if (_tieCandidates.isNotEmpty && !_tieCandidates.contains(index)) {
                      return const SizedBox.shrink();
                    }

                    bool isSelected = _selectedCandidateIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: GestureDetector(
                        onTap: () {
                          SoundService.instance.playClick();
                          setState(() {
                            _selectedCandidateIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? AppStyles.warning : AppStyles.cardBg,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? AppStyles.darkAccent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.session.players[index].name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppStyles.darkAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Votes counter summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 5,
                  children: List.generate(widget.session.players.length, (index) {
                     if (_tieCandidates.isNotEmpty && !_tieCandidates.contains(index)) return const SizedBox.shrink();
                     return Text(
                       '${widget.session.players[index].name}: ${_votes[index]}',
                       style: const TextStyle(color: AppStyles.textSecondary, fontSize: 12),
                     );
                  }),
                ),
              ),

              const SizedBox(height: 15),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _selectedCandidateIndex == null ? null : _onConfirmVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.accent,
                    foregroundColor: AppStyles.cardBg,
                    disabledBackgroundColor: Colors.grey.shade300,
                    side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    AppStrings.confirmVote,
                    style: TextStyle(
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
