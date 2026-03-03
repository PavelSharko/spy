import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/locations_data.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/game_rules.dart';
import '../utils/sound_service.dart';
import '../widgets/exit_game_button.dart';
import 'round_score_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Running-border painter (same technique as in LocationSelectionScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _RunningBorderPainter extends CustomPainter {
  final double progress; // 0..1, drives where the glow is
  final double borderRadius;

  _RunningBorderPainter({required this.progress, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final perimeter = 2 * (size.width + size.height);
    final distance = progress * perimeter;

    double x, y;
    if (distance < size.width) {
      x = distance;
      y = 0;
    } else if (distance < size.width + size.height) {
      x = size.width;
      y = distance - size.width;
    } else if (distance < 2 * size.width + size.height) {
      x = size.width - (distance - size.width - size.height);
      y = size.height;
    } else {
      x = 0;
      y = size.height - (distance - 2 * size.width - size.height);
    }

    final paint = Paint()
      ..color = Colors.amberAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rrect, Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final spotPaint = Paint()
      ..color = Colors.amberAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y), Offset(x, y), spotPaint);

    // Also paint a small arc segment around the point
    final path = Path();
    final arcLen = perimeter * 0.15;
    final start = (distance - arcLen / 2).clamp(0.0, perimeter);
    final end = (distance + arcLen / 2).clamp(0.0, perimeter);

    void addPoint(double d) {
      double px, py;
      if (d < size.width) {
        px = d; py = 0;
      } else if (d < size.width + size.height) {
        px = size.width; py = d - size.width;
      } else if (d < 2 * size.width + size.height) {
        px = size.width - (d - size.width - size.height); py = size.height;
      } else {
        px = 0; py = size.height - (d - 2 * size.width - size.height);
      }
      path.lineTo(px, py);
    }

    path.moveTo(x, y);
    for (double d = start; d <= end; d += arcLen / 10) addPoint(d);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RunningBorderPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Guess Screen
// ─────────────────────────────────────────────────────────────────────────────
class RoleGuessScreen extends StatefulWidget {
  final GameSession session;

  const RoleGuessScreen({super.key, required this.session});

  @override
  State<RoleGuessScreen> createState() => _RoleGuessScreenState();
}

class _RoleGuessScreenState extends State<RoleGuessScreen>
    with TickerProviderStateMixin {
  // ── Queue ──────────────────────────────────────────────────────────────────
  late final List<Player> _nonSpyPlayers;
  late int _startIndex;
  int _stepIndex = 0; // 0..n-1 — how many pairs we've done

  // ── Selection ──────────────────────────────────────────────────────────────
  String? _selectedRole;

  // ── Phase: guess | reveal ─────────────────────────────────────────────────
  bool _isRevealPhase = false;
  int _countdown = 3;
  bool _showResult = false;
  Timer? _countdownTimer;
  bool? _wasCorrect;

  // ── Running border animation ──────────────────────────────────────────────
  late AnimationController _borderController;

  // ── Roles for current location ─────────────────────────────────────────────
  late final List<String> _locationRoles;

  @override
  void initState() {
    super.initState();
    // Build non-spy list in session order
    _nonSpyPlayers = [
      for (int i = 0; i < widget.session.players.length; i++)
        if (i != widget.session.currentSpyIndex) widget.session.players[i]
    ];
    _startIndex = Random().nextInt(_nonSpyPlayers.length);

    _locationRoles = List<String>.from(
      LocationsData.roles[widget.session.currentSecretLocation] ?? [],
    );

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _borderController.dispose();
    super.dispose();
  }

  // ── Queue helpers ──────────────────────────────────────────────────────────
  int get _n => _nonSpyPlayers.length;

  /// Current guesser index in _nonSpyPlayers
  int get _guesserIdx => (_startIndex + _stepIndex) % _n;

  /// Current target index in _nonSpyPlayers (next after guesser)
  int get _targetIdx => (_startIndex + _stepIndex + 1) % _n;

  Player get _guesser => _nonSpyPlayers[_guesserIdx];
  Player get _target => _nonSpyPlayers[_targetIdx];

  bool get _isLastStep => _stepIndex == _n - 1;

  // ── Confirm guess ──────────────────────────────────────────────────────────
  void _onConfirm() {
    if (_selectedRole == null) return;
    SoundService.instance.playClick();
    setState(() {
      _isRevealPhase = true;
      _countdown = 3;
      _showResult = false;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        _revealResult();
      }
    });
  }

  void _revealResult() {
    final correct = _selectedRole == _target.role;
    if (correct) {
      _guesser.addScore(GameRules.roleGuessCorrectGuesser);
      _target.addScore(GameRules.roleGuessCorrectGuessed);
    }
    setState(() {
      _wasCorrect = correct;
      _showResult = true;
    });
  }

  // ── Next pair or finish ────────────────────────────────────────────────────
  void _onNext() {
    SoundService.instance.playClick();
    if (_isLastStep) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoundScoreScreen(session: widget.session)),
      );
      return;
    }
    setState(() {
      _stepIndex++;
      _selectedRole = null;
      _isRevealPhase = false;
      _showResult = false;
      _wasCorrect = null;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: AppStyles.mainBackgroundDecoration,
            child: SafeArea(
              child: _isRevealPhase ? _buildRevealPhase() : _buildGuessPhase(),
            ),
          ),
          const ExitGameButton(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GUESS PHASE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGuessPhase() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Title
        const Text(
          AppStrings.whoIsWho,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 16),

        // Guesser → Target
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _playerChip(_guesser.name, Colors.blue.shade200),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white60),
                ),
                _playerChip(_target.name, Colors.amberAccent),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Hint
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppStrings.guessRoleHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ),

        const SizedBox(height: 16),

        // Keyboard 2 × N
        Expanded(
          child: _buildRoleGrid(),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ElevatedButton(
            onPressed: _selectedRole != null ? _onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: Colors.white24,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: const Text(
              AppStrings.confirmAction,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0, // square
      ),
      itemCount: _locationRoles.length,
      itemBuilder: (_, i) => _buildRoleTile(_locationRoles[i]),
    );
  }

  Widget _buildRoleTile(String role) {
    final bool selected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        SoundService.instance.playClick();
        setState(() => _selectedRole = role);
      },
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (_, __) => CustomPaint(
          painter: selected
              ? _RunningBorderPainter(
                  progress: _borderController.value, borderRadius: 14)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.amberAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.amberAccent.withValues(alpha: 0.6) : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.amberAccent : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVEAL PHASE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRevealPhase() {
    if (!_showResult) {
      // Countdown
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              AppStrings.revealingIn,
              style: TextStyle(
                  fontSize: 24, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text(
              '$_countdown',
              style: const TextStyle(
                  fontSize: 100,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    // Result
    final bool correct = _wasCorrect!;
    final Color roleColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Column(
      children: [
        const SizedBox(height: 30),

        // "TARGET был РОЛЬ"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: '${_target.name}\n',
                  style: const TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: '${AppStrings.wasRole} ',
                  style: const TextStyle(color: Colors.white60, fontSize: 20),
                ),
                TextSpan(
                  text: _target.role ?? '—',
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: roleColor.withValues(alpha: 0.6), blurRadius: 12)],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Verdict
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (correct ? Colors.green : Colors.red).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: correct ? Colors.greenAccent : Colors.redAccent, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                '${_guesser.name.toUpperCase()} — '
                '${correct ? AppStrings.guessedCorrectly : AppStrings.guessedWrong}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: correct ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_guesser.name} и ${_target.name} '
                '${correct ? AppStrings.bothGetPoints : AppStrings.bothGetNothing}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Next / Results button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade900,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _isLastStep ? AppStrings.finalReveal : AppStrings.nextReveal,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _playerChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
