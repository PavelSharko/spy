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
import '../utils/context_extensions.dart';

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
  int get _maxGameTime =>
      (_playerCountValue * 1.5).ceil(); // 1.5 min per player, rounded up

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          builder: (context) =>
              LocationSelectionScreen(roundCount: _roundCountValue),
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
        if (settingName == AppStrings.playerCount &&
            _selectedPlayerCount == null) {
          _updatePlayerCount(_playerCountValue);
        } else if (settingName == AppStrings.gameTime &&
            _selectedGameTime == null) {
          _updateGameTime(_gameTimeValue);
        } else if (settingName == AppStrings.roundCount &&
            _selectedRoundCount == null) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      SizedBox(height: context.topPadding5),
                      const Center(
                        child: GameScreenTitle(
                          title: AppStrings.gameSettingsTitle,
                        ),
                      ),
                      SizedBox(height: context.padding3),

                      // Scrollable Settings
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Расчет динамической высоты для 4 кнопок + 3 отступов между ними (отступ = 20% высоты кнопки).
                            // 4 * H + 3 * 0.2H = 4.6H = max space.
                            final double calculatedHeight =
                                constraints.maxHeight / 4.6;
                            final double itemHeight = calculatedHeight.clamp(
                              60.0,
                              95.0,
                            );
                            final double gapHeight = itemHeight * 0.2;

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.horizontalMargin,
                                  vertical: gapHeight,
                                ),
                                child: Column(
                                  children: [
                                    _buildSettingItem(
                                      id: AppStrings.playerCount,
                                      title: AppStrings.playerCount,
                                      value: _selectedPlayerCount,
                                      itemHeight: itemHeight,
                                      child: NumberSelector(
                                        initialValue: _playerCountValue,
                                        minValue: 3,
                                        maxValue: 6,
                                        onChanged: _updatePlayerCount,
                                      ),
                                    ),
                                    SizedBox(height: gapHeight),
                                    _buildSettingItem(
                                      id: AppStrings.gameTime,
                                      title: AppStrings.gameTime,
                                      value: _selectedGameTime,
                                      itemHeight: itemHeight,
                                      child: NumberSelector(
                                        initialValue: _gameTimeValue,
                                        minValue: _minGameTime,
                                        maxValue: _maxGameTime,
                                        onChanged: _updateGameTime,
                                      ),
                                    ),
                                    SizedBox(height: gapHeight),
                                    _buildSettingItem(
                                      id: AppStrings.roundCount,
                                      title: AppStrings.roundCount,
                                      value: _selectedRoundCount,
                                      itemHeight: itemHeight,
                                      child: NumberSelector(
                                        initialValue: _roundCountValue,
                                        minValue: 1,
                                        maxValue: 5,
                                        onChanged: _updateRoundCount,
                                      ),
                                    ),
                                    SizedBox(height: gapHeight),
                                    _buildSettingItem(
                                      id: AppStrings.locationSelection,
                                      title: AppStrings.locationSelection,
                                      value: _selectedLocation,
                                      itemHeight: itemHeight,
                                      child: const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom Buttons
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalMargin,
                          context.padding2,
                          context.horizontalMargin,
                          context.padding3,
                        ),
                        child: Row(
                          children: [
                            GameButton(
                              text: AppStrings.backAction,
                              type: GameButtonType.secondary,
                              width: 120, // Keep fixed back button width
                              height: null, // Fluid height
                              onPressed: _onBackPressed,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GameButton(
                                text: AppStrings.playAction,
                                width:
                                    null, // Let GameButton or Expanded decide
                                height: null, // Fluid height
                                onPressed: _onPlayPressed,
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
    required double itemHeight,
    required Widget child,
  }) {
    final bool isOpen = _activeSettingId == id;

    return Column(
      children: [
        SettingsButton(
          title: title,
          value: value,
          height: itemHeight,
          onPressed: () => _onSettingPressed(id),
        ),
        // Animated Control Panel ("Window")
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOpen
              ? Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    top: itemHeight * 0.1,
                    bottom: itemHeight * 0.1,
                  ),
                  child: child,
                )
              : const SizedBox.shrink(), // Hidden
        ),
      ],
    );
  }
}
