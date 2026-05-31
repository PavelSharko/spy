import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_history_entry.dart';
import '../utils/app_styles.dart';
import '../data/locations_data.dart';
import '../utils/sound_service.dart';

class PhotoCarouselDialog extends StatefulWidget {
  final List<RoundHistory> rounds;

  const PhotoCarouselDialog({super.key, required this.rounds});

  @override
  State<PhotoCarouselDialog> createState() => _PhotoCarouselDialogState();
}

class _PhotoCarouselDialogState extends State<PhotoCarouselDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedRoundIndex = 0;
  String? _historyDirPath;

  @override
  void initState() {
    super.initState();
    _initDirPath();
  }

  Future<void> _initDirPath() async {
    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        setState(() {
          _historyDirPath = '${appDir.path}/spy_game_history';
        });
      } catch (e) {
        debugPrint('Error getting history dir: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImageSlide(String? relativePath, Uint8List? imageBytes, String fallbackAssetPath) {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (relativePath != null && _historyDirPath != null && !kIsWeb) {
      final file = File('$_historyDirPath/$relativePath');
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return Image.asset(
      fallbackAssetPath,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildScoreSlide(RoundHistory roundHistory) {
    final sortedScores = roundHistory.playerScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppStyles.bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Очки за раунд ${roundHistory.roundNumber}',
            style: TextStyle(
              color: AppStyles.accent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: sortedScores.length,
              itemBuilder: (context, index) {
                final entry = sortedScores[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppStyles.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppStyles.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.value > 0 ? '+' : ''}${entry.value % 1 == 0 ? entry.value.toInt() : entry.value.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: entry.value > 0 ? Colors.green : Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: widget.rounds.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedRoundIndex == index;
            return GestureDetector(
              onTap: () {
                SoundService.instance.playClick();
                setState(() {
                  _selectedRoundIndex = index;
                  _pageController.jumpToPage(0);
                  _currentPage = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppStyles.accent : AppStyles.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppStyles.darkAccent
                        : AppStyles.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'РАУНД ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppStyles.bgColor : AppStyles.accent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) {
      return Dialog(
        backgroundColor: AppStyles.bgColor,
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('История раундов пуста', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final currentRound = widget.rounds[_selectedRoundIndex];

    // Build the 3 slides for the selected round
    final List<Widget> roundSlides = [
      // 1. Результаты раунда
      _buildScoreSlide(currentRound),
      
      // 2. Карточка рубашка локации
      _buildImageSlide(
        currentRound.locationImagePath,
        currentRound.locationImageBytes,
        currentRound.locationName != null
            ? LocationsData.getDefaultLocationAsset(currentRound.locationName!)
            : 'assets/images/card_reveal_bg_not_spy.jpeg',
      ),
      
      // 3. Результат игры
      _buildImageSlide(
        currentRound.resultImagePath,
        currentRound.resultImageBytes,
        currentRound.spyWon
            ? 'assets/images/card_after_round_defolt_spy_win.jpeg'
            : 'assets/images/card_after_round_defolt_spy_lose.jpeg',
      ),
    ];

    final List<String> slideSubtitles = [
      'Результаты раунда',
      'Локация была: ${currentRound.locationName ?? "Секретная"}',
      'Результат игры (шпион ${currentRound.spyWon ? "выиграл" : "проиграл"})',
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppStyles.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppStyles.accent.withValues(alpha: 0.8), width: 2),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Раунд ${currentRound.roundNumber}: ${slideSubtitles[_currentPage]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        SoundService.instance.playClick();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // Horizontal tab selector for rounds
              _buildRoundTabs(),

              // Page Carousel
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: roundSlides,
                  ),
                ),
              ),

              // 3 dots indicators for the active round's slides
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 10 : 6,
                      height: _currentPage == index ? 10 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppStyles.accent : Colors.white30,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
