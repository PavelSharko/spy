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

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.amberAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

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
        px = d;
        py = 0;
      } else if (d < size.width + size.height) {
        px = size.width;
        py = d - size.width;
      } else if (d < 2 * size.width + size.height) {
        px = size.width - (d - size.width - size.height);
        py = size.height;
      } else {
        px = 0;
        py = size.height - (d - 2 * size.width - size.height);
      }
      path.lineTo(px, py);
    }

    path.moveTo(x, y);
    for (double d = start; d <= end; d += arcLen / 10) {
      addPoint(d);
    }

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
        if (i != widget.session.currentSpyIndex) widget.session.players[i],
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
      if (!mounted) {
        t.cancel();
        return;
      }
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
        MaterialPageRoute(
          builder: (_) => RoundScoreScreen(session: widget.session),
        ),
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
      backgroundColor: AppStyles.bgColor,
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: Container(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _isRevealPhase
                        ? _buildRevealPhase()
                        : _buildGuessPhase(),
                  ),
                ),
              ),
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
        SizedBox(height: 16),

        // Title
        Text(
          AppStrings.whoIsWho,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppStyles.accent,
            letterSpacing: 3,
          ),
        ),

        SizedBox(height: 16),

        // Guesser → Target
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            decoration: BoxDecoration(
              color: AppStyles.cardBg.withOpacity(0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppStyles.darkAccent.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _playerChip(
                    _guesser.name,
                    AppStyles.textBright.withOpacity(0.8),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppStyles.textSecondary,
                  ),
                ),
                Expanded(
                  child: _playerChip(
                    _target.name,
                    AppStyles.textBright.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 10),

        // Hint
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppStrings.guessRoleHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppStyles.textSecondary),
          ),
        ),

        SizedBox(height: 16),

        // Keyboard 2 × N
        Expanded(child: _buildRoleGrid()),

        // Confirm button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ElevatedButton(
            onPressed: _selectedRole != null ? _onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppStyles.cardBg.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.transparent, width: 2),
              ),
              elevation: 4,
            ),
            child: Text(
              AppStrings.confirmAction,
              style: TextStyle(
                fontSize: 18,
                color: _selectedRole != null
                    ? AppStyles.bgColor
                    : AppStyles.textSecondary2,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double itemWidth =
            (width - 32 - 10) / 2; // padding 16*2, spacing 10
        final double itemHeight = (itemWidth / 2.2).clamp(50.0, 70.0);
        final double aspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _locationRoles.length,
          itemBuilder: (_, i) => _buildRoleTile(_locationRoles[i]),
        );
      },
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
                  progress: _borderController.value,
                  borderRadius: 14,
                )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected
                  ? AppStyles.accent.withOpacity(0.3)
                  : AppStyles.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppStyles.accent
                    : AppStyles.accent.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    role,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, // Task 13: Reduce font size
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppStyles.darkAccent
                          : AppStyles.textSecondary,
                      letterSpacing: 1,
                    ),
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
            Text(
              AppStrings.revealingIn,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '$_countdown',
              style: TextStyle(
                fontSize: 100,
                color: AppStyles.darkAccent,
                fontWeight: FontWeight.w900,
              ),
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
        SizedBox(height: 30),

        // "TARGET был РОЛЬ"
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: '${_target.name}\n',
                  style: TextStyle(
                    color: AppStyles.accent,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'был\n',
                  style: TextStyle(
                    color: AppStyles.textSecondary,
                    fontSize: 24,
                  ),
                ),
                TextSpan(
                  text: (_target.role ?? '—').toUpperCase(),
                  style: TextStyle(
                    color:
                        (_target.role == 'Шпионить' || _target.role == 'Шпион')
                        ? AppStyles.danger
                        : AppStyles.accent,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Verdict
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (correct ? Colors.green : Colors.red).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: correct ? Colors.greenAccent : Colors.redAccent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${_guesser.name.toUpperCase()} — \n'
                '${correct ? AppStrings.guessedCorrectly : AppStrings.guessedWrong}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: correct ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${_guesser.name} и ${_target.name} '
                '${correct ? AppStrings.bothGetPoints : AppStrings.bothGetNothing}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Next / Results button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.transparent, width: 2),
              ),
            ),
            child: Text(
              _isLastStep ? AppStrings.finalReveal : AppStrings.nextReveal,
              style: TextStyle(
                fontSize: 18,
                color: AppStyles.bgColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _playerChip(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 30),
      decoration: BoxDecoration(
        color: AppStyles.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppStyles.accent.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
