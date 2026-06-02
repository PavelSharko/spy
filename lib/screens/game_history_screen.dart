import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_history_entry.dart';
import '../services/game_history_service.dart';
import '../utils/app_styles.dart';
import '../utils/context_extensions.dart';
import '../utils/sound_service.dart';
import '../widgets/common/game_button.dart';
import '../widgets/photo_carousel_dialog.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  List<GameHistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await GameHistoryService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.cardBg,
        title: const Text('Очистить историю', style: TextStyle(color: Colors.white)),
        content: const Text('Вы уверены, что хотите удалить всю историю игр?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await GameHistoryService.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Container(
        color: AppStyles.bgColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  SizedBox(height: context.topPadding5),

                  // Header with Title and Clear button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.horizontalMargin),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ИСТОРИЯ ИГР',
                              style: GoogleFonts.russoOne(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppStyles.accent,
                                letterSpacing: 3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (!_isLoading && _history.isNotEmpty)
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                              onPressed: _clearHistory,
                              tooltip: 'Очистить историю',
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.padding4),

                  // Scrollable Content
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppStyles.accent,
                            ),
                          )
                        : _history.isEmpty
                            ? const Center(
                                child: Text(
                                  'История пуста',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.horizontalMargin,
                                  vertical: context.padding1,
                                ),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final game = _history[index];
                                  final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(game.date);
                                  
                                  final sortedScores = game.finalScores.entries.toList()
                                    ..sort((a, b) => b.value.compareTo(a.value));
                                  final winner = sortedScores.isNotEmpty ? sortedScores.first.key : 'Нет победителя';

                                  return Card(
                                    color: AppStyles.cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(color: AppStyles.accent.withValues(alpha: 0.3)),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () {
                                        if (game.rounds.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => PhotoCarouselDialog(rounds: game.rounds),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Раундов: ${game.totalRounds}',
                                                  style: TextStyle(
                                                    color: AppStyles.accent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Победитель: $winner',
                                              style: TextStyle(
                                                color: AppStyles.accent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Игроки: ${game.playerNames.join(", ")}',
                                              style: TextStyle(
                                                color: AppStyles.accent.withValues(alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Back button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalMargin * 1.5,
                      0,
                      context.horizontalMargin * 1.5,
                      context.padding4,
                    ),
                    child: GameButton(
                      text: '← НАЗАД',
                      type: GameButtonType.secondary,
                      onPressed: () {
                        SoundService.instance.playClick();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
