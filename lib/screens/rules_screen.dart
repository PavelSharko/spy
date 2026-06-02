import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../widgets/common/game_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/context_extensions.dart';
import '../data/rules_data.dart';
import '../utils/sound_service.dart';

/// Rules screen — dynamically loads rules and detailed philosophy notes.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Container(
        color: AppStyles.bgColor,
        child: Container(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    SizedBox(height: context.topPadding5),

                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ПРАВИЛА ИГРЫ',
                        style: GoogleFonts.russoOne(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.accent,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: context.padding2),

                    // Scrollable content
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalMargin,
                          vertical: context.padding1,
                        ),
                        itemCount: RulesData.sections.length,
                        itemBuilder: (context, index) {
                          final section = RulesData.sections[index];
                          return _buildRuleCard(context, section);
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
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, RuleSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppStyles.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppStyles.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppStyles.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                section.text,
                style: TextStyle(
                  fontSize: 15,
                  color: AppStyles.accent.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
