import 'dart:math';
import 'package:flutter/material.dart';
import '../data/locations_data.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../widgets/exit_game_button.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  // -1 means Random is selected
  // 0 to N means a specific group from LocationsData.groups is selected
  // null means nothing is selected yet
  int? _selectedIndex;

  void _onRandomSelected() {
    setState(() {
      _selectedIndex = -1;
    });
  }

  void _onGroupSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onConfirm() {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.pleaseSelectWarning,
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Logic to select secret location
    final random = Random();
    String secretLocation;
    String displayGroupName;

    if (_selectedIndex == -1) {
      // Random from all
      displayGroupName = AppStrings.randomGroupDisplay;
      
      // Flatten all locations into one list
      final List<String> allLocations = [];
      for (var group in LocationsData.groups) {
        final locs = group['locations'] as List<dynamic>;
        allLocations.addAll(locs.map((e) => e as String));
      }
      
      secretLocation = allLocations[random.nextInt(allLocations.length)];
    } else {
      // Specific group
      final group = LocationsData.groups[_selectedIndex!];
      displayGroupName = group['groupName'] as String;
      
      final locs = group['locations'] as List<dynamic>;
      final List<String> locations = locs.map((e) => e as String).toList();
      secretLocation = locations[random.nextInt(locations.length)];
    }

    // Return the result
    Navigator.pop(context, {
      'displayGroupName': displayGroupName,
      'secretLocation': secretLocation,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: AppStyles.mainGradientDecoration,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
              
              // Top Random Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLocationButton(
                  title: AppStrings.randomSelection,
                  isSelected: _selectedIndex == -1,
                  onTap: _onRandomSelected,
                  isRandomButton: true,
                ),
              ),

              const SizedBox(height: 20),

              // Scrollable list of groups
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: LocationsData.groups.length,
                  itemBuilder: (context, index) {
                    final groupName = LocationsData.groups[index]['groupName'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLocationButton(
                        title: groupName,
                        isSelected: _selectedIndex == index,
                        onTap: () => _onGroupSelected(index),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Confirm Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _onConfirm,
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
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const ExitGameButton(), // Add exit button here
    ],
  ),
);
}


  Widget _buildLocationButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isRandomButton = false,
  }) {
    // Styling differentiation between selected and unselected
    final Color bgColor = isSelected 
        ? (isRandomButton ? Colors.amber.shade400 : Colors.blue.shade400)
        : Colors.white.withOpacity(0.9);
        
    final Color textColor = isSelected ? Colors.white : Colors.blue.shade900;
    
    final Border border = isSelected
        ? Border.all(color: Colors.white, width: 2)
        : Border.all(color: Colors.transparent, width: 2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: border,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: bgColor.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isRandomButton ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: isRandomButton ? 1.2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
