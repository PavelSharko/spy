import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/names_data.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/app_settings.dart';
import '../utils/sound_service.dart';
import '../widgets/game_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/exit_game_button.dart';
import '../widgets/camera_overlay.dart';
import '../services/ai_generation_service.dart';
import 'game_round_screen.dart';

enum FlowStep { nameSelection, photoCapture, cardReveal, roundReady }

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
  bool _isFirstImageLoading = true; // hides once the first prefetched image arrives
  
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
      widget.session.assignRoles(); // Ensure roles for subsequent rounds
      _currentStep = FlowStep.cardReveal;
    }
    _prefetchAllLocations();
  }

  /// Kicks off a parallel fetch for each uncached location.
  /// Each completes independently and calls setState directly — no callbacks.
  void _prefetchAllLocations() {
    if (!AppSettings.instance.uniqueCardsEnabled) {
      if (mounted) setState(() => _isFirstImageLoading = false);
      return;
    }
    
    final locations = widget.session.secretLocationsQueue;
    final cache = widget.session.locationImages;

    // Deduplicate — same location may appear in multiple rounds
    final toFetch =
        locations.toSet().where((loc) => !cache.containsKey(loc)).toList();

    if (toFetch.isEmpty) {
      if (mounted) setState(() => _isFirstImageLoading = false);
      return;
    }

    // Fire one independent async task per location
    for (final loc in toFetch) {
      _fetchAndCache(loc);
    }
  }

  /// Fetches a single location image and updates state when done.
  Future<void> _fetchAndCache(String location) async {
    final roles = widget.session.getSelectedRolesForLocation(location, playerCount: widget.playerCount);
    debugPrint('[PreGameFlow] Fetching $location with roles: $roles');
    final bytes = await AiGenerationService.fetchLocationImage(location, roles: roles);
    if (bytes != null && mounted) {
      setState(() {
        widget.session.locationImages[location] = bytes;
        // Hide the spinner on the very first success
        if (_isFirstImageLoading) _isFirstImageLoading = false;
      });
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
    SoundService.instance.playClick();
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
    SoundService.instance.playClick();
    String finalName = _nameController.text.trim();
    
    if (_selectedRandomName == null) {
      if (finalName.isEmpty || finalName.length > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Имя должно быть от 1 до 20 символов!', textAlign: TextAlign.center),
            backgroundColor: AppStyles.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    } else if (finalName.isEmpty) {
      return;
    }

    widget.session.players.add(Player(name: finalName));

    // If faces enabled, go to photo capture for this player
    if (AppSettings.instance.playerFacesEnabled) {
      setState(() {
        _currentStep = FlowStep.photoCapture;
      });
      return;
    }

    _advanceAfterPhoto();
  }

  /// Called after photo is taken (or skipped) to move to the next player or to card reveal.
  void _advanceAfterPhoto() {
    if (widget.session.players.length == widget.playerCount) {
      // All names collected! Assign roles and start revealing
      widget.session.assignRoles();
      setState(() {
        _currentPlayerIndex = 0;
        _currentStep = FlowStep.cardReveal;
      });
    } else {
      // Next name entry
      setState(() {
        _currentPlayerIndex++;
        _nameController.clear();
        _selectedRandomName = null;
        _generateRandomNames();
        _currentStep = FlowStep.nameSelection;
      });
    }
  }

  void _onPhotoCaptured(Uint8List bytes) {
    // Save to the last added player
    widget.session.players.last.photoBytes = bytes;
    _advanceAfterPhoto();
  }


  void _onCardTappedToNext() {
    if (_currentPlayerIndex < widget.playerCount - 1) {
      // Next reveal
      setState(() {
        _currentPlayerIndex++;
      });
    } else {
      // All reveals done
      setState(() {
        _currentStep = FlowStep.roundReady;
      });
    }
  }

  void _onStartRound() {
    _launchEndGameCardGeneration();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoundScreen(session: widget.session),
      ),
    );
  }

  /// Launches two delayed background requests for finish-round cards
  /// (spy_is_win: true after 15s, spy_is_win: false after 25s).
  void _launchEndGameCardGeneration() {
    final session = widget.session;
    final location = session.currentSecretLocation;
    final roles = session.getSelectedRolesForLocation(location, playerCount: widget.playerCount);

    // Separate spy photo from civilian photos
    final Uint8List? spyPhoto = session.players[session.currentSpyIndex].photoBytes;
    final List<Uint8List> civilianPhotos = [];
    for (int i = 0; i < session.players.length; i++) {
      if (i != session.currentSpyIndex && session.players[i].photoBytes != null) {
        civilianPhotos.add(session.players[i].photoBytes!);
      }
    }

    AiGenerationService.fetchEndGameCards(
      location: location,
      roles: roles,
      spyPhoto: spyPhoto,
      civilianPhotos: civilianPhotos,
      roundNumber: session.currentRound,
      targetMap: session.roundFinalCards,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: Container(
              child: SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
          const ExitGameButton(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case FlowStep.nameSelection:
        return _buildNameSelection();
      case FlowStep.photoCapture:
        return _buildPhotoCapture();
      case FlowStep.cardReveal:
        return _buildCardReveal();
      case FlowStep.roundReady:
        return _buildRoundReady();
    }
  }

  Widget _buildPhotoCapture() {
    final playerName = widget.session.players.last.name;
    return CameraOverlay(
      key: ValueKey('photo_$_currentPlayerIndex'),
      playerName: playerName,
      onPhotoCaptured: _onPhotoCaptured,
    );
  }

  Widget _buildNameSelection() {
    return Stack(
      key: ValueKey('nameSelection_$_currentPlayerIndex'),
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                '${AppStrings.passPhoneTo} ${_currentPlayerIndex + 1}${AppStrings.playerSuffix}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.darkAccent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              
              // Input field
              Container(
                decoration: BoxDecoration(
                  color: AppStyles.cardBg,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.darkAccent.withValues(alpha: 0.1),
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
                        color: isSelected ? AppStyles.warning : AppStyles.cardBg,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? AppStyles.darkAccent : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppStyles.warning.withValues(alpha: 0.4),
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
                            color: isSelected ? Colors.white : AppStyles.darkAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),

              // Confirm Button
              ElevatedButton(
                onPressed: _onConfirmName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.accent,
                  foregroundColor: AppStyles.cardBg,
                  side: BorderSide(color: AppStyles.darkAccent, width: 2),
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
        ),
        // Subtle spinner — visible only while first image is loading
        if (_isFirstImageLoading)
          Positioned(
            top: 8,
            left: 8,
            child: Opacity(
              opacity: 0.5,
              child: Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardReveal() {
    bool isSpy = _currentPlayerIndex == widget.session.currentSpyIndex;
    
    return SingleChildScrollView(
      key: ValueKey('cardReveal_$_currentPlayerIndex'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.session.players[_currentPlayerIndex].name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppStyles.darkAccent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            GameCard(
              isSpy: isSpy,
              secretLocation: widget.session.currentSecretLocation,
              role: isSpy ? null : widget.session.players[_currentPlayerIndex].role,
              // Spy always sees the default card back — never the location image
              bgImageBytes: isSpy
                  ? null
                  : widget.session.locationImages[widget.session.currentSecretLocation],
              onCardTapped: _onCardTappedToNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundReady() {
    return Column(
      key: const ValueKey('roundReady'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer, size: 100, color: AppStyles.accent),
        const SizedBox(height: 20),
        Text(
          '${widget.session.gameTime}:00',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: AppStyles.darkAccent,
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
