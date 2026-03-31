import 'package:flutter/material.dart';
import '../utils/app_settings.dart';
import '../utils/app_styles.dart';
import '../utils/dev_config.dart';
import '../utils/sound_service.dart';
import '../widgets/animated_pattern_background.dart';
import '../widgets/menu_button.dart';

/// System settings screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _uniqueCardsEnabled;
  late String _cardStyle;
  late bool _playerFacesEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = AppSettings.instance.soundEnabled;
    _uniqueCardsEnabled = AppSettings.instance.uniqueCardsEnabled;
    _cardStyle = AppSettings.instance.cardStyle;
    _playerFacesEnabled = AppSettings.instance.playerFacesEnabled;
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
      AppSettings.instance.soundEnabled = value;
    });
    if (value) SoundService.instance.playClick();
  }

  void _toggleUniqueCards(bool value) {
    setState(() {
      _uniqueCardsEnabled = value;
      AppSettings.instance.uniqueCardsEnabled = value;
    });
    if (_soundEnabled) SoundService.instance.playClick();
  }

  void _togglePlayerFaces(bool value) {
    setState(() {
      _playerFacesEnabled = value;
      AppSettings.instance.playerFacesEnabled = value;
    });
    if (_soundEnabled) SoundService.instance.playClick();
  }

  void _chooseCardStyle() {
    if (_soundEnabled) SoundService.instance.playClick();
    
    final List<String> styles = [
      "не выбрано", "реальное фото", "мультяшный", "пиксели", "живопись", 
      "фэнтези", "черно белое", "детское", "18+", "комиксы", 
      "аниме", "киберпанк", "неон", "ретро плакаты ссср", 
      "ретро плакаты сша"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.10,
            vertical: MediaQuery.of(context).size.height * 0.15,
          ),
          backgroundColor: AppStyles.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Стиль карточек',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.darkAccent,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: styles.length,
                  itemBuilder: (context, index) {
                    final style = styles[index];
                    final isSelected = style == _cardStyle;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _cardStyle = style;
                          AppSettings.instance.cardStyle = style;
                        });
                        Navigator.of(context).pop();
                        if (_soundEnabled) SoundService.instance.playClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        color: isSelected ? AppStyles.accent.withValues(alpha: 0.1) : Colors.transparent,
                        child: Text(
                          style,
                          style: TextStyle(
                            fontSize: 18,
                            color: isSelected ? AppStyles.accent : AppStyles.darkAccent,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppStyles.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppStyles.accent.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkAccent,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppStyles.accent,
      inactiveThumbColor: AppStyles.textSecondary,
      inactiveTrackColor: AppStyles.accent.withValues(alpha: 0.12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppStyles.bgColor,
        child: AnimatedPatternBackground(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Title
                const Text(
                  'НАСТРОЙКИ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.darkAccent,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 30),

                // Scrollable Settings List
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // Sound toggle card
                      _buildSettingsCard(
                        icon: _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        iconColor: _soundEnabled ? AppStyles.warning : AppStyles.textSecondary,
                        title: 'Звук',
                        subtitle: _soundEnabled ? 'Включён' : 'Выключен',
                        trailing: _buildToggle(
                          value: _soundEnabled,
                          onChanged: _toggleSound,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Developer features toggle card
                      if (DevConfig.developerFeaturesEnabled) ...[
                        _buildSettingsCard(
                          icon: Icons.bug_report_rounded,
                          iconColor: AppStyles.textSecondary,
                          title: 'Секретные функции',
                          subtitle: 'Включены (только чтение)',
                          trailing: _buildToggle(
                            value: true,
                            onChanged: null,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Unique Cards Toggle
                      _buildSettingsCard(
                        icon: Icons.style_rounded,
                        iconColor: _uniqueCardsEnabled ? AppStyles.accent : AppStyles.textSecondary,
                        title: 'Уникальные карточки',
                        subtitle: _uniqueCardsEnabled ? 'Включены' : 'Выключены',
                        trailing: _buildToggle(
                          value: _uniqueCardsEnabled,
                          onChanged: _toggleUniqueCards,
                        ),
                      ),

                      // Conditional child settings
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _uniqueCardsEnabled
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Column(
                                  children: [
                                    // Card Style Button
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30), // Indent sub-settings
                                      child: _buildSettingsCard(
                                        icon: Icons.color_lens_rounded,
                                        iconColor: AppStyles.accent,
                                        title: 'Стиль карточек',
                                        subtitle: _cardStyle,
                                        onTap: _chooseCardStyle,
                                        trailing: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppStyles.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Player Faces Toggle
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30),
                                      child: _buildSettingsCard(
                                        icon: Icons.face_retouching_natural_rounded,
                                        iconColor: _playerFacesEnabled ? AppStyles.accent : AppStyles.textSecondary,
                                        title: 'Лица игроков',
                                        subtitle: _playerFacesEnabled ? 'На карточках' : 'Без лиц',
                                        trailing: _buildToggle(
                                          value: _playerFacesEnabled,
                                          onChanged: _togglePlayerFaces,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Back button
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: MenuButton(
                    text: '← НАЗАД',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: false,
                    width: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
