import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/settings_button.dart';
import '../widgets/number_selector.dart';
import '../models/game_session.dart';
import 'location_selection_screen.dart';
import 'pre_game_flow_screen.dart';
import '../widgets/exit_game_button.dart';
import '../widgets/common/game_button.dart';
import '../widgets/common/game_screen_title.dart';

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
          SnackBar(
            content: const Text(
              AppStrings.pleaseSelectRoundsFirst,
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppStyles.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
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
        
        // UX improvement: set default values on first click
        if (settingName == AppStrings.playerCount && _selectedPlayerCount == null) {
          _updatePlayerCount(_playerCountValue);
        } else if (settingName == AppStrings.gameTime && _selectedGameTime == null) {
          _updateGameTime(_gameTimeValue);
        } else if (settingName == AppStrings.roundCount && _selectedRoundCount == null) {
          _updateRoundCount(_roundCountValue);
        }
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
    SoundService.instance.playClick();
    final String? validationError = _firstValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError, textAlign: TextAlign.center),
          backgroundColor: AppStyles.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    SoundService.instance.playClick();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onBackgroundTap,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppStyles.bgColor,
        body: Stack(
          children: [
            // Background covers everything including SafeArea areas
            Container(child: const SizedBox.expand()),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: GameScreenTitle(title: AppStrings.gameSettingsTitle),
                  ),
                  const SizedBox(height: 50),

                  // Scrollable Settings
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            _buildSettingItem(
                              id: AppStrings.playerCount,
                              title: AppStrings.playerCount,
                              value: _selectedPlayerCount,
                              buttonSize: double.infinity,
                              child: NumberSelector(
                                initialValue: _playerCountValue,
                                minValue: 3,
                                maxValue: 6,
                                onChanged: _updatePlayerCount,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingItem(
                              id: AppStrings.gameTime,
                              title: AppStrings.gameTime,
                              value: _selectedGameTime,
                              buttonSize: double.infinity,
                              child: NumberSelector(
                                initialValue: _gameTimeValue,
                                minValue: _minGameTime,
                                maxValue: _maxGameTime,
                                onChanged: _updateGameTime,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingItem(
                              id: AppStrings.roundCount,
                              title: AppStrings.roundCount,
                              value: _selectedRoundCount,
                              buttonSize: double.infinity,
                              child: NumberSelector(
                                initialValue: _roundCountValue,
                                minValue: 1,
                                maxValue: 5,
                                onChanged: _updateRoundCount,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingItem(
                              id: AppStrings.locationSelection,
                              title: AppStrings.locationSelection,
                              value: _selectedLocation,
                              buttonSize: double.infinity,
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      children: [
                        GameButton(
                          text: AppStrings.backAction,
                          type: GameButtonType.secondary,
                          width: 120,
                          height: 50,
                          onPressed: _onBackPressed,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GameButton(
                            text: AppStrings.playAction,
                            width: double.infinity,
                            height: 50,
                            onPressed: _onPlayPressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const ExitGameButton(),
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
                  margin: const EdgeInsets.only(top: 8, bottom: 8), 
                  child: child,
                )
              : const SizedBox.shrink(), // Hidden
        ),
      ],
    );
  }
}
