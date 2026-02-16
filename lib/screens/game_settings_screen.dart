import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/game_provider.dart';
import '../models/game_settings.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  // Local state for settings form
  int _playerCount = 3;
  int _roundTime = 480; // seconds
  int _roundCount = 1;
  int _turnTime = 20; // seconds
  bool _isLocationRandom = true;
  bool _isNamesRandom = true;

  void _handleStartGame(BuildContext context) async {
    // 1. Save Settings
    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.updateSettings(GameSettings(
      playerCount: _playerCount,
      roundTimeSeconds: _roundTime,
      roundCount: _roundCount,
      turnTimeSeconds: _turnTime,
      isLocationRandom: _isLocationRandom,
      isNamesRandom: _isNamesRandom,
    ));

    // 2. Notify User ("Игра пошла")
    // Using a Dialog or SnackBar as requested.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ИГРА ПОШЛА! (Звук сирены)',
          style: TextStyle(fontSize: 20),
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );

    // 3. Play Siren (Simulation)
    // await AudioPlayer().play(...) 
    await Future.delayed(const Duration(seconds: 3));

    // 4. Reset & Go to Main Menu
    if (mounted) {
      provider.resetGame();
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки игры')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2.1 Players
            _buildSectionTitle('Количество игроков'),
            _buildCounterRow(
              value: _playerCount,
              min: 3,
              max: 10,
              onChanged: (val) => setState(() => _playerCount = val),
            ),
            
            const Divider(),

            // 2.2 Game Time
            _buildSectionTitle('Время игры (мин)'),
            Slider(
              value: _roundTime.toDouble(),
              min: 60,
              max: 900,
              divisions: 14,
              label: '${(_roundTime / 60).round()} мин',
              onChanged: (value) => setState(() => _roundTime = value.toInt()),
            ),
            Center(child: Text('${(_roundTime / 60).round()} минут')),

            const Divider(),

            // 2.2.1 Round Count (NEW)
            _buildSectionTitle('Количество раундов'),
            _buildCounterRow(
              value: _roundCount,
              min: 1,
              max: 10,
              onChanged: (val) => setState(() => _roundCount = val),
            ),

            const Divider(),

            // 2.3 Turn Time (NEW)
            _buildSectionTitle('Время на вопрос (сек)'),
            Slider(
              value: _turnTime.toDouble(),
              min: 20,
              max: 120,
              divisions: 5,
              label: '$_turnTime сек',
              onChanged: (value) => setState(() => _turnTime = value.toInt()),
            ),
            Center(child: Text('$_turnTime секунд')), // Button "Next" implied in logic later

            const Divider(),

            // 2.4 Locations (NEW)
            _buildSectionTitle('Выбор локаций'),
            SwitchListTile(
              title: const Text('Случайные группы'),
              subtitle: const Text('Система выберет сама'),
              value: _isLocationRandom,
              onChanged: (val) => setState(() => _isLocationRandom = val),
            ),
            if (!_isLocationRandom)
               const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 16),
                 child: Text('Выбор из списка (Заглушка)', style: TextStyle(color: Colors.grey)),
               ),

            const Divider(),

            // 2.5 Naming (NEW)
            _buildSectionTitle('Имена игроков'),
            SwitchListTile(
              title: const Text('Рандомные смешные имена'),
              subtitle: const Text('Панда, Осел, Принцесса...'),
              value: _isNamesRandom,
              onChanged: (val) => setState(() => _isNamesRandom = val),
            ),

            const SizedBox(height: 30),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleStartGame(context),
                child: const Text('НАЧАТЬ ИГРУ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCounterRow({required int value, required int min, required int max, required Function(int) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
