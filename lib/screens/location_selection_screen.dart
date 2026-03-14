import 'dart:math';
import 'package:flutter/material.dart';
import '../data/locations_data.dart';
import '../services/storage_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import '../widgets/exit_game_button.dart';

// ── Animated running-border painter ─────────────────────────────────────────

class _RunningBorderPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0 (rotation around perimeter)
  final Color color;
  final double radius;
  final double strokeWidth;

  _RunningBorderPainter({
    required this.progress,
    required this.color,
    this.radius = 15,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Total perimeter
    final w = size.width;
    final h = size.height;
    final double perimeter = 2 * (w + h) - 8 * radius + 2 * pi * radius;
    final double segmentLength = perimeter * 0.30; // 30% of perimeter glows

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = _buildRoundedRectPath(size);

    // Use PathMetric to draw a segment at progress offset
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final total = metric.length;
    final start = (progress * total) % total;
    final end = start + segmentLength;

    if (end <= total) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    } else {
      // Wrap around
      canvas.drawPath(metric.extractPath(start, total), paint);
      canvas.drawPath(metric.extractPath(0, end - total), paint);
    }
  }

  Path _buildRoundedRectPath(Size size) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));
  }

  @override
  bool shouldRepaint(_RunningBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class LocationSelectionScreen extends StatefulWidget {
  /// How many groups/locations to select (equals roundCount).
  final int roundCount;

  const LocationSelectionScreen({super.key, required this.roundCount});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen>
    with TickerProviderStateMixin {
  // Selected group indexes (max = roundCount, each used once)
  final Set<int> _selectedIndexes = {};
  bool _isRandomAll = false;

  // Running-border animations per button (-1 = random button)
  final Map<int, AnimationController> _borderControllers = {};
  final Map<int, Animation<double>> _borderAnimations = {};

  // Shake animation for progress hint label
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showRedHint = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Pre-create controllers for random button and all groups
    _initBorderController(-1);
    for (int i = 0; i < LocationsData.groups.length; i++) {
      _initBorderController(i);
    }
  }

  void _initBorderController(int key) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _borderControllers[key] = ctrl;
    _borderAnimations[key] = Tween<double>(begin: 0, end: 1).animate(ctrl);
  }

  void _startBorder(int key) {
    _borderControllers[key]?.repeat();
  }

  void _stopBorder(int key) {
    _borderControllers[key]?.stop();
    _borderControllers[key]?.reset();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final c in _borderControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Selection logic ────────────────────────────────────────────────

  void _onRandomPressed() {
    SoundService.instance.playClick();
    if (_isRandomAll) {
      // Deselect
      setState(() => _isRandomAll = false);
      _stopBorder(-1);
    } else {
      // Select random — clear manual picks
      for (final idx in _selectedIndexes) {
        _stopBorder(idx);
      }
      setState(() {
        _isRandomAll = true;
        _selectedIndexes.clear();
      });
      _startBorder(-1);
    }
  }

  void _onGroupPressed(int index) {
    if (_isRandomAll) return; // random mode locks groups
    SoundService.instance.playClick();

    if (_selectedIndexes.contains(index)) {
      // Deselect
      setState(() => _selectedIndexes.remove(index));
      _stopBorder(index);
    } else {
      if (_selectedIndexes.length >= widget.roundCount) {
        // Already full — shake hint
        _triggerShakeHint();
        return;
      }
      setState(() => _selectedIndexes.add(index));
      _startBorder(index);
    }
  }

  void _triggerShakeHint() {
    setState(() => _showRedHint = true);
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reverse().then((_) {
        if (mounted) setState(() => _showRedHint = false);
      });
    });
  }

  // ── Confirm ────────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    final int needed = widget.roundCount;

    final bool valid = _isRandomAll || _selectedIndexes.length == needed;
    if (!valid) {
      _triggerShakeHint();
      return;
    }
    SoundService.instance.playClick();

    // Build location pool depending on selection mode
    List<String> pool;
    String displayName;

    if (_isRandomAll) {
      pool = _allLocations();
      displayName = AppStrings.randomGroupDisplay;
    } else {
      pool = [];
      final names = <String>[];
      for (final idx in _selectedIndexes) {
        final group = LocationsData.groups[idx];
        names.add(group['groupName'] as String);
        final locs = group['locations'] as List<dynamic>;
        pool.addAll(locs.map((e) => e as String));
      }
      displayName = names.join(', ');
    }

    // Smart pick using StorageService
    final List<String> queue =
        await storageService.pickSmartLocations(pool, needed);

    if (!mounted) return;
    Navigator.pop(context, {
      'displayGroupName': displayName,
      'secretLocationsQueue': queue,
    });
  }

  List<String> _allLocations() {
    final List<String> all = [];
    for (final group in LocationsData.groups) {
      final locs = group['locations'] as List<dynamic>;
      all.addAll(locs.map((e) => e as String));
    }
    return all;
  }

  // ── Progress hint text ─────────────────────────────────────────────

  String _progressText() {
    final int selected = _isRandomAll ? widget.roundCount : _selectedIndexes.length;
    return AppStrings.locationProgressHint
        .replaceAll('{r}', '${widget.roundCount}')
        .replaceAll('{n}', '$selected');
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppStyles.bgColor,
            child: AnimatedPatternBackground(
              child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Random button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGroupButton(
                      key: -1,
                      title: AppStrings.randomSelection,
                      isSelected: _isRandomAll,
                      onTap: _onRandomPressed,
                      isRandom: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scrollable group list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: LocationsData.groups.length,
                      itemBuilder: (context, index) {
                        final isDisabled = _isRandomAll;
                        final isSelected = _selectedIndexes.contains(index);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGroupButton(
                            key: index,
                            title: LocationsData.groups[index]['groupName'] as String,
                            isSelected: isSelected,
                            isDisabled: isDisabled,
                            onTap: () => _onGroupPressed(index),
                          ),
                        );
                      },
                    ),
                  ),

                  // Progress hint + Confirm button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      children: [
                        // Shake + colour hint
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (_, child) {
                            final double offset = _shakeController.isAnimating
                                ? sin(_shakeAnimation.value * pi * 6) * 8
                                : 0;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 13,
                              color: _showRedHint
                                  ? Colors.red.shade300
                                  : AppStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _progressText(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        // Confirm button
                        ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.accent,
                            foregroundColor: AppStyles.cardBg,
                            side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            AppStrings.confirmAction,
                            style: TextStyle(fontSize: 20, letterSpacing: 1.5),
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
    );
  }

  // ── Button widget ──────────────────────────────────────────────────

  Widget _buildGroupButton({
    required int key,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isRandom = false,
    bool isDisabled = false,
  }) {
    final Color bgColor = isSelected
        ? (isRandom ? AppStyles.warning : AppStyles.accent)
        : AppStyles.cardBg.withValues(alpha: isDisabled ? 0.5 : 1.0);
    final Color textColor = isSelected
        ? Colors.white
        : AppStyles.darkAccent.withValues(alpha: isDisabled ? 0.4 : 1.0);

    final border = Border.all(
      color: isSelected ? Colors.transparent : Colors.transparent,
      width: 0,
    );

    final Widget button = GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: border,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: bgColor.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(isDisabled ? 0.05 : 0.1),
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
              fontSize: isRandom ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: isRandom ? 1.2 : 0,
            ),
          ),
        ),
      ),
    );

    // Wrap with running-border animation if selected
    if (!isSelected) return button;

    return AnimatedBuilder(
      animation: _borderAnimations[key]!,
      builder: (_, child) => CustomPaint(
        foregroundPainter: _RunningBorderPainter(
          progress: _borderAnimations[key]!.value,
          color: isRandom ? Colors.white : Colors.amberAccent,
          radius: 15,
          strokeWidth: 3,
        ),
        child: child,
      ),
      child: button,
    );
  }
}
