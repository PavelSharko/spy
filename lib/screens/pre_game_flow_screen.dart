import 'dart:math';
import 'package:flutter/material.dart';
import '../data/names_data.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../widgets/game_card.dart';
import '../widgets/menu_button.dart';
import 'game_round_screen.dart';

enum FlowStep { nameSelection, cardReveal, roundReady }

class PreGameFlowScreen extends StatefulWidget {
  final GameSession session;
  final int playerCount;

  const PreGameFlowScreen({
    super.key,
    required this.session,
    required this.playerCount,
  });

  @override
  State<PreGameFlowScreen> createState() => _PreGameFlowScreenState();
}

class _PreGameFlowScreenState extends State<PreGameFlowScreen> {
  FlowStep _currentStep = FlowStep.nameSelection;
  int _currentPlayerIndex = 0;
  
  // Name Selection State
  final TextEditingController _nameController = TextEditingController();
  List<String> _randomNames = [];
  String? _selectedRandomName;

  @override
  void initState() {
    super.initState();
    if (widget.session.currentRound == 1) {
      widget.session.currentSpyIndex = Random().nextInt(widget.playerCount);
      _generateRandomNames();
      _currentStep = FlowStep.nameSelection;
    } else {
      _currentStep = FlowStep.cardReveal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomNames() {
    _randomNames = List.generate(4, (_) => NamesData.generateRandomName());
  }

  void _onRandomNameTap(String name) {
    setState(() {
      _selectedRandomName = name;
      _nameController.text = name; // Update text field to reflect choice
    });
  }

  void _onNameChanged(String val) {
    if (_selectedRandomName != null && val != _selectedRandomName) {
      setState(() {
        _selectedRandomName = null; // User typing means discarding button selection
      });
    }
  }

  void _onConfirmName() {
    String finalName = _nameController.text.trim();
    if (finalName.length < 3 || finalName.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.chooseNameWarning, textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.session.players.add(Player(name: finalName));
    
    // Move to card reveal for this player
    setState(() {
      _currentStep = FlowStep.cardReveal;
    });
  }

  void _onCardTappedToNext() {
    if (_currentPlayerIndex < widget.playerCount - 1) {
      // Next player
      setState(() {
        _currentPlayerIndex++;
        if (widget.session.currentRound == 1) {
          _currentStep = FlowStep.nameSelection;
          // Reset name selection state
          _nameController.clear();
          _selectedRandomName = null;
          _generateRandomNames();
        } else {
          _currentStep = FlowStep.cardReveal;
        }
      });
    } else {
      // All players done, ready to start round
      setState(() {
        _currentStep = FlowStep.roundReady;
      });
    }
  }

  void _onStartRound() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoundScreen(session: widget.session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case FlowStep.nameSelection:
        return _buildNameSelection();
      case FlowStep.cardReveal:
        return _buildCardReveal();
      case FlowStep.roundReady:
        return _buildRoundReady();
    }
  }

  Widget _buildNameSelection() {
    return SingleChildScrollView(
      key: ValueKey('nameSelection_$_currentPlayerIndex'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            '${AppStrings.passPhoneTo} ${_currentPlayerIndex + 1}${AppStrings.playerSuffix}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          
          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              onChanged: _onNameChanged,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: 'Введите имя...',
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Random Name Options
          ..._randomNames.map((name) {
            bool isSelected = name == _selectedRandomName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _onRandomNameTap(name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.shade400 : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }), // Remove .toList() from map

          const SizedBox(height: 40),

          // Confirm Button
          ElevatedButton(
            onPressed: _onConfirmName,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            child: const Text(
              AppStrings.confirmAction,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardReveal() {
    bool isSpy = _currentPlayerIndex == widget.session.currentSpyIndex;
    
    return Column(
      key: ValueKey('cardReveal_$_currentPlayerIndex'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.session.players[_currentPlayerIndex].name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 40),
        GameCard(
          isSpy: isSpy,
          secretLocation: widget.session.currentSecretLocation,
          onCardTapped: _onCardTappedToNext,
        ),
      ],
    );
  }

  Widget _buildRoundReady() {
    return Column(
      key: const ValueKey('roundReady'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer, size: 100, color: Colors.white),
        const SizedBox(height: 20),
        Text(
          '${widget.session.gameTime}:00',
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: MenuButton(
            text: AppStrings.startRound,
            onPressed: _onStartRound,
            isPrimary: true,
          ),
        ),
      ],
    );
  }
}
