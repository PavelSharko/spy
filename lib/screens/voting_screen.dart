import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_session.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startVotingRound();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
    try {
      await _audioPlayer.play(AssetSource('audio/pig.wav'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
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
            color: Colors.blue.shade800,
            width: double.infinity,
            height: double.infinity,
            child: const Center(
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
            decoration: AppStyles.mainBackgroundDecoration,
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
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 30),

              // Current Voter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Text(
                  '${AppStrings.votingPlayerPrefix}${widget.session.players[currentVoter].name}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade900,
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
                  color: Colors.white.withOpacity(0.7),
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
                            color: isSelected ? Colors.amber.shade400 : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.session.players[index].name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.blue.shade900,
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
                       style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
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
      const ExitGameButton(),
    ],
  ),
);
}
}
