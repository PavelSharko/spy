import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../widgets/menu_button.dart';
import '../widgets/settings_button.dart';
import '../widgets/number_selector.dart';
import '../models/game_session.dart';
import 'location_selection_screen.dart';
import 'pre_game_flow_screen.dart';
import '../widgets/exit_game_button.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  // Variables to hold the selected values (initially null, so they show as "--not selected--")
  String? _selectedPlayerCount; // Display string
  int _playerCountValue = 3; // Actual Logic Value (Default min)

  String? _selectedGameTime;
  int _gameTimeValue = 3; // Default based on min game time for 3 players

  String? _selectedRoundCount;
  int _roundCountValue = 1; // Default 1 round

  String? _selectedLocation;
  List<String>? _secretLocationsQueue; // Pre-computed queue of secret locations
  
  // Track which setting is currently open (expanded)
  String? _activeSettingId;

  // Dynamic constraints for game time based on player count
  int get _minGameTime => _playerCountValue; // 1 min per player
  int get _maxGameTime => (_playerCountValue * 1.5).ceil(); // 1.5 min per player, rounded up

  void _onSettingPressed(String settingName) async {
    if (settingName == AppStrings.locationSelection) {
      // Block if rounds not selected yet
      if (_selectedRoundCount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              AppStrings.pleaseSelectRoundsFirst,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (_activeSettingId != null) {
        setState(() => _activeSettingId = null);
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationSelectionScreen(roundCount: _roundCountValue),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        final queue = (result['secretLocationsQueue'] as List<dynamic>)
            .map((e) => e as String)
            .toList();
        setState(() {
          _selectedLocation = result['displayGroupName'] as String;
          _secretLocationsQueue = queue;
        });
        debugPrint('Locations queue: $_secretLocationsQueue');
      }
      return;
    }

    setState(() {
      // Toggle: if clicking already active, close it; otherwise open it
      if (_activeSettingId == settingName) {
        _activeSettingId = null;
      } else {
        _activeSettingId = settingName;
      }
    });
  }

  void _onBackgroundTap() {
    if (_activeSettingId != null) {
      setState(() {
        _activeSettingId = null;
      });
    }
  }

  void _updatePlayerCount(int value) {
    setState(() {
      _playerCountValue = value;
      _selectedPlayerCount = value.toString();

      // Adjust game time bounds based on the new player count
      if (_gameTimeValue < _minGameTime) {
        _gameTimeValue = _minGameTime;
      } else if (_gameTimeValue > _maxGameTime) {
        _gameTimeValue = _maxGameTime;
      }

      // Automatically dynamically adjust the displayed game time if it was already selected
      if (_selectedGameTime != null) {
        _selectedGameTime = '$_gameTimeValue мин';
      }
    });
  }

  void _updateGameTime(int value) {
    setState(() {
      _gameTimeValue = value;
      _selectedGameTime = '$value мин';
    });
  }

  void _updateRoundCount(int value) {
    setState(() {
      _roundCountValue = value;
      _selectedRoundCount = value.toString();
      // Reset location selection when round count changes
      _selectedLocation = null;
      _secretLocationsQueue = null;
    });
  }

  void _onPlayPressed() {
    final String? validationError = _firstValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError, textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final session = GameSession(
      players: [],
      totalRounds: _roundCountValue,
      gameTime: _gameTimeValue,
      locationGroupName: _selectedLocation,
      secretLocationsQueue: List<String>.from(_secretLocationsQueue!),
      currentSpyIndex: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PreGameFlowScreen(session: session, playerCount: _playerCountValue),
      ),
    );
  }

  /// Returns the warning message for the first unfilled field, or null if all good.
  String? _firstValidationError() {
    if (_selectedPlayerCount == null) return AppStrings.pleaseSelectPlayerCount;
    if (_selectedGameTime == null) return AppStrings.pleaseSelectGameTime;
    if (_selectedRoundCount == null) return AppStrings.pleaseSelectRoundCount;
    if (_secretLocationsQueue == null) return AppStrings.pleaseSelectWarning;
    return null;
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 180.0; 

    return GestureDetector(
      onTap: _onBackgroundTap, // Close settings when tapping outside
      behavior: HitTestBehavior.translucent, // Ensure taps pass through empty space
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.gameSettingsTitle),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0, 
          automaticallyImplyLeading: false, 
        ),
        extendBodyBehindAppBar: true, 
        backgroundColor: Colors.transparent, // Important for gradient background if provided by Container below
        body: Stack(
          children: [
            Container(
              decoration: AppStyles.mainGradientDecoration,
              child: SafeArea( 
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                
                // Scrollable area for the large buttons
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column( // Trigger "Wrap" behavior vertically but use Column for better full-width control (for sliding drawer)
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 2.1 Players
                          _buildSettingItem(
                            id: AppStrings.playerCount,
                            title: AppStrings.playerCount,
                            value: _selectedPlayerCount,
                            buttonSize: buttonSize,
                            child: NumberSelector(
                              initialValue: _playerCountValue, 
                              minValue: 3,
                              maxValue: 6,
                              onChanged: _updatePlayerCount,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2.2 Game Time
                          _buildSettingItem(
                            id: AppStrings.gameTime,
                            title: AppStrings.gameTime,
                            value: _selectedGameTime,
                            buttonSize: buttonSize,
                            child: NumberSelector(
                              initialValue: _gameTimeValue,
                              minValue: _minGameTime,
                              maxValue: _maxGameTime,
                              onChanged: _updateGameTime,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2.2.1 Round Count
                          _buildSettingItem(
                            id: AppStrings.roundCount,
                            title: AppStrings.roundCount,
                            value: _selectedRoundCount,
                            buttonSize: buttonSize,
                            child: NumberSelector(
                              initialValue: _roundCountValue,
                              minValue: 1,
                              maxValue: 5,
                              onChanged: _updateRoundCount,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2.3 Location (Navigates to new screen, doesn't use accordion child)
                          _buildSettingItem(
                            id: AppStrings.locationSelection,
                            title: AppStrings.locationSelection,
                            value: _selectedLocation,
                            buttonSize: buttonSize,
                            child: const SizedBox.shrink(), // Not used for this item type
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.all(20.0), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BACK Button
                      SizedBox(
                        width: 120, 
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _onBackPressed,
                           style: OutlinedButton.styleFrom(
                               side: const BorderSide(color: Colors.blue, width: 2),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                               backgroundColor: Colors.white.withOpacity(0.5)
                           ),
                          child: const Text(AppStrings.backAction, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(width: 20),

                      // PLAY Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _onPlayPressed,
                            style: ElevatedButton.styleFrom(
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text(AppStrings.playAction, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        const ExitGameButton(), // Add exit button here
      ],
    ),
  ),
);
}

  // Builder helper to handle the expansion logic
  Widget _buildSettingItem({
    required String id, 
    required String title, 
    required String? value, 
    required double buttonSize,
    required Widget child,
  }) {
    final bool isOpen = _activeSettingId == id;

    return Column(
      children: [
        SettingsButton(
          title: title,
          value: value,
          size: buttonSize,
          onPressed: () => _onSettingPressed(id),
        ),
        // Animated Control Panel ("Window")
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOpen
              ? Container(
                  width: buttonSize, // Match button width
                  // Ensure it looks connected or just below
                  margin: const EdgeInsets.only(top: 10), 
                  child: child,
                )
              : const SizedBox.shrink(), // Hidden
        ),
      ],
    );
  }
}
