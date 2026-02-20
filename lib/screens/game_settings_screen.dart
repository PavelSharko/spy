import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../widgets/menu_button.dart';
import '../widgets/settings_button.dart';
import '../widgets/player_count_selector.dart';

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
  String? _selectedLocation;
  
  // Track which setting is currently open (expanded)
  String? _activeSettingId;

  void _onSettingPressed(String settingName) {
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
    });
  }

  // _confirmPlayerCount removed as it's no longer needed

  void _onPlayPressed() {
    debugPrint('Pressed Play!');
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
        body: Container(
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
                            child: PlayerCountSelector(
                              initialValue: _playerCountValue, 
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
                            child: const SizedBox(height: 50, child: Center(child: Text("Заглушка"))), // Placeholder
                          ),

                          const SizedBox(height: 20),

                          // 2.3 Location
                          _buildSettingItem(
                            id: AppStrings.locationSelection,
                            title: AppStrings.locationSelection,
                            value: _selectedLocation,
                            buttonSize: buttonSize,
                            child: const SizedBox(height: 50, child: Center(child: Text("Заглушка"))), // Placeholder
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
