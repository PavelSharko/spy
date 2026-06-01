import 'package:flutter/material.dart';
import '../utils/app_settings.dart';
import '../utils/app_styles.dart';
import '../config/app_environment.dart';
import '../utils/sound_service.dart';
import '../widgets/common/game_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/context_extensions.dart';

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
    if (value && !AppSettings.instance.hasPlus) {
      _showSubscriptionDialog(SubscriptionLevel.plus);
      return;
    }
    setState(() {
      _uniqueCardsEnabled = value;
      AppSettings.instance.uniqueCardsEnabled = value;
      // If uniquely disabled, make sure faces is also disabled
      if (!value) {
        _playerFacesEnabled = false;
        AppSettings.instance.playerFacesEnabled = false;
      }
    });
    if (_soundEnabled) SoundService.instance.playClick();
  }

  void _togglePlayerFaces(bool value) {
    if (value && !AppSettings.instance.hasUltra) {
      _showSubscriptionDialog(SubscriptionLevel.ultra);
      return;
    }
    setState(() {
      _playerFacesEnabled = value;
      AppSettings.instance.playerFacesEnabled = value;
    });
    if (_soundEnabled) SoundService.instance.playClick();
  }

  Widget _buildSubscriptionStatusCard() {
    String levelName = 'БАЗОВЫЙ';
    IconData levelIcon = Icons.lock_outline_rounded;
    Color levelColor = AppStyles.textSecondary;

    if (AppSettings.instance.hasUltra) {
      levelName = 'ULTRA';
      levelIcon = Icons.workspace_premium_rounded;
      levelColor = Colors.purpleAccent;
    } else if (AppSettings.instance.hasPlus) {
      levelName = 'PLUS';
      levelIcon = Icons.star_rounded;
      levelColor = AppStyles.accent;
    }

    return _buildSettingsCard(
      icon: levelIcon,
      iconColor: levelColor,
      title: 'Ваш тариф',
      subtitle: levelName,
      trailing: Icon(
        Icons.edit_rounded,
        color: AppStyles.accent.withValues(alpha: 0.8),
        size: 24,
      ),
      onTap: _showSubscriptionSelectionDialog,
    );
  }

  void _showSubscriptionSelectionDialog() {
    if (_soundEnabled) SoundService.instance.playClick();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: context.horizontalMargin),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppStyles.bgColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppStyles.accent.withValues(alpha: 0.8), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ТАРИФНЫЕ ПЛАНЫ',
                  style: GoogleFonts.russoOne(
                    fontSize: 24,
                    color: AppStyles.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Base Tariff Option
                _buildSubscriptionOptionTile(
                  title: 'БАЗОВЫЙ (БЕСПЛАТНО)',
                  description: 'Стандартные локации и правила игры.',
                  icon: Icons.lock_outline_rounded,
                  color: AppStyles.textSecondary,
                  onTap: () {
                    AppSettings.instance.subscriptionLevel = SubscriptionLevel.none;
                    AppSettings.instance.uniqueCardsEnabled = false;
                    AppSettings.instance.playerFacesEnabled = false;
                    Navigator.of(context).pop();
                    setState(() {
                      _uniqueCardsEnabled = false;
                      _playerFacesEnabled = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Plus Option
                _buildSubscriptionOptionTile(
                  title: 'ТАРИФ PLUS',
                  description: 'Генерация уникальных карточек локаций.',
                  icon: Icons.star_rounded,
                  color: AppStyles.accent,
                  onTap: () {
                    AppSettings.instance.subscriptionLevel = SubscriptionLevel.plus;
                    AppSettings.instance.playerFacesEnabled = false;
                    Navigator.of(context).pop();
                    setState(() {
                      _playerFacesEnabled = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Ultra Option
                _buildSubscriptionOptionTile(
                  title: 'ТАРИФ ULTRA',
                  description: 'Уникальные карточки + вживление ваших лиц!',
                  icon: Icons.workspace_premium_rounded,
                  color: Colors.purpleAccent,
                  onTap: () {
                    AppSettings.instance.subscriptionLevel = SubscriptionLevel.ultra;
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                
                TextButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.of(context).pop();
                  },
                  child: const Text('ЗАКРЫТЬ', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionOptionTile({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        SoundService.instance.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppStyles.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String text, {
    Color color = Colors.greenAccent,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color == Colors.white38 ? Colors.white38 : Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppStyles.accent).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (badgeColor ?? AppStyles.accent).withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor ?? AppStyles.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSubscriptionDialog(SubscriptionLevel requiredLevel) {
    if (_soundEnabled) SoundService.instance.playClick();

    final currentLevel = AppSettings.instance.subscriptionLevel;
    final isUltra = requiredLevel == SubscriptionLevel.ultra;
    final showBothOptions = requiredLevel == SubscriptionLevel.plus && currentLevel == SubscriptionLevel.none;

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        // If height is small, apply tighter padding and font sizes
        final isCompact = screenHeight < 750;

        final dialogPadding = isCompact ? 16.0 : 24.0;
        final iconSize = isCompact ? 44.0 : 54.0;
        final iconPadding = isCompact ? 10.0 : 16.0;
        final titleFontSize = isCompact ? 20.0 : 26.0;
        final descFontSize = isCompact ? 13.0 : 15.0;
        final sectionSpacing = isCompact ? 12.0 : 20.0;
        final featurePadding = isCompact ? 12.0 : 16.0;
        final buttonSpacing = isCompact ? 8.0 : 12.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: context.horizontalMargin,
            vertical: isCompact ? 16.0 : 24.0,
          ),
          child: Container(
            padding: EdgeInsets.all(dialogPadding),
            decoration: BoxDecoration(
              color: AppStyles.bgColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isUltra ? Colors.purpleAccent : AppStyles.accent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isUltra ? Colors.purpleAccent : AppStyles.accent).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: (isUltra ? Colors.purpleAccent : AppStyles.accent).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUltra ? Icons.workspace_premium_rounded : Icons.star_rounded,
                      color: isUltra ? Colors.purpleAccent : AppStyles.accent,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 16),
                  Text(
                    showBothOptions ? 'ВЫБЕРИТЕ ТАРИФ' : 'ТАРИФ ${isUltra ? 'ULTRA' : 'PLUS'}',
                    style: GoogleFonts.russoOne(
                      fontSize: titleFontSize,
                      color: isUltra ? Colors.purpleAccent : AppStyles.accent,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    showBothOptions
                        ? 'Премиум функции доступны в тарифах PLUS и ULTRA. Выберите лучший для вас!'
                        : (isUltra
                            ? 'Вам необходим тариф ULTRA для персонализирования карточек с лицами игроков!'
                            : 'Вам необходим тариф PLUS для генерации умных ИИ локаций!'),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: descFontSize,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sectionSpacing),
                  Container(
                    padding: EdgeInsets.all(featurePadding),
                    decoration: BoxDecoration(
                      color: AppStyles.cardBg,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureRow(
                        Icons.check_circle_outline,
                        'Умный ИИ художник локаций',
                        badgeText: 'PLUS',
                        badgeColor: AppStyles.accent,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      _buildFeatureRow(
                        isUltra || showBothOptions ? Icons.check_circle_outline : Icons.lock_outline,
                        'Персонализирование карточки с лицами игроков в реальных локациях',
                        badgeText: 'ULTRA',
                        badgeColor: Colors.purpleAccent,
                        color: isUltra || showBothOptions ? Colors.greenAccent : Colors.white38,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompact ? 16 : 24),
                if (showBothOptions) ...[
                  GameButton(
                    text: 'КУПИТЬ ТАРИФ PLUS (199 ₽)',
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.of(context).pop();
                      _simulateAppStoreRedirect('PLUS', enableUnique: true);
                    },
                  ),
                  SizedBox(height: buttonSpacing),
                  GameButton(
                    text: 'КУПИТЬ ТАРИФ ULTRA (399 ₽) — ХИТ!',
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.of(context).pop();
                      _simulateAppStoreRedirect('ULTRA', enableUnique: true);
                    },
                  ),
                  SizedBox(height: buttonSpacing),
                  GameButton(
                    text: 'ТЕСТОВАЯ ULTRA (БЕСПЛАТНО)',
                    type: GameButtonType.secondary,
                    onPressed: () {
                      SoundService.instance.playClick();
                      AppSettings.instance.subscriptionLevel = SubscriptionLevel.ultra;
                      AppSettings.instance.uniqueCardsEnabled = true;
                      Navigator.of(context).pop();
                      setState(() {
                        _uniqueCardsEnabled = true;
                      });
                      _showSnackBar('Успешно активирован тариф ULTRA!');
                    },
                  ),
                ] else ...[
                  GameButton(
                    text: 'КУПИТЬ ТАРИФ ${isUltra ? 'ULTRA' : 'PLUS'} (${isUltra ? '399' : '199'} ₽)',
                    onPressed: () {
                      SoundService.instance.playClick();
                      Navigator.of(context).pop();
                      _simulateAppStoreRedirect(isUltra ? 'ULTRA' : 'PLUS',
                          enableUnique: requiredLevel == SubscriptionLevel.plus,
                          enableFaces: requiredLevel == SubscriptionLevel.ultra);
                    },
                  ),
                  SizedBox(height: buttonSpacing),
                  GameButton(
                    text: 'ТЕСТОВАЯ ПОКУПКА (БЕСПЛАТНО)',
                    type: GameButtonType.secondary,
                    onPressed: () {
                      SoundService.instance.playClick();
                      AppSettings.instance.subscriptionLevel = requiredLevel;
                      Navigator.of(context).pop();
                      setState(() {
                        if (requiredLevel == SubscriptionLevel.plus) {
                          _uniqueCardsEnabled = true;
                          AppSettings.instance.uniqueCardsEnabled = true;
                        } else if (requiredLevel == SubscriptionLevel.ultra) {
                          _playerFacesEnabled = true;
                          AppSettings.instance.playerFacesEnabled = true;
                        }
                      });
                      _showSnackBar('Успешно активирован тариф ${isUltra ? 'ULTRA' : 'PLUS'}!');
                    },
                  ),
                ],
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'ОТМЕНА',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _simulateAppStoreRedirect(String levelName,
      {bool enableUnique = false, bool enableFaces = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Переход в Магазин Приложений...',
                  style: GoogleFonts.russoOne(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Симуляция подключения к App Store / Google Play',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final isPlus = levelName == 'PLUS';
          final price = isPlus ? '199 ₽' : '399 ₽';
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF23232A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              color: Colors.greenAccent,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Шпион: Premium',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Тариф $levelName',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    const Text(
                      'Подтвердите встроенную покупку через аккаунт Google Play или App Store.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    GameButton(
                      text: 'ПОДТВЕРДИТЬ И ОПЛАТИТЬ',
                      onPressed: () {
                        SoundService.instance.playClick();
                        final newLevel = levelName == 'PLUS'
                            ? SubscriptionLevel.plus
                            : SubscriptionLevel.ultra;
                        AppSettings.instance.subscriptionLevel = newLevel;

                        // Automatically activate the requested toggles upon successful mock purchase
                        if (enableUnique || newLevel == SubscriptionLevel.plus || newLevel == SubscriptionLevel.ultra) {
                          AppSettings.instance.uniqueCardsEnabled = true;
                        }
                        if (enableFaces && newLevel == SubscriptionLevel.ultra) {
                          AppSettings.instance.playerFacesEnabled = true;
                        }

                        Navigator.of(context).pop();

                        setState(() {
                          _uniqueCardsEnabled = AppSettings.instance.uniqueCardsEnabled;
                          _playerFacesEnabled = AppSettings.instance.playerFacesEnabled;
                        });

                        _showSnackBar('Покупка успешна! Тариф $levelName активирован.');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        SoundService.instance.playClick();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'ОТМЕНА',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _chooseCardStyle() {
    if (_soundEnabled) SoundService.instance.playClick();

    final List<String> styles = [
      "не выбрано",
      "реальное фото",
      "мультяшный",
      "пиксели",
      "живопись",
      "фэнтези",
      "черно белое",
      "детское",
      "18+",
      "комиксы",
      "аниме",
      "киберпанк",
      "неон",
      "ретро плакаты ссср",
      "ретро плакаты сша",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: context.horizontalMargin,
            vertical: context.topPadding5 * 2,
          ),
          backgroundColor: AppStyles.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Padding(
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        color: isSelected
                            ? AppStyles.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        child: Text(
                          style,
                          style: TextStyle(
                            fontSize: 18,
                            color: isSelected
                                ? AppStyles.accent
                                : AppStyles.darkAccent,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
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
      padding: EdgeInsets.symmetric(horizontal: context.horizontalMargin),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.padding4,
            vertical: context.padding3,
          ),
          decoration: BoxDecoration(
            color: AppStyles.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppStyles.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkAccent,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
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
                        'НАСТРОЙКИ',
                        style: GoogleFonts.russoOne(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.accent,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    SizedBox(height: context.padding4),

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          // Subscription status card
                          _buildSubscriptionStatusCard(),

                          SizedBox(height: 16),

                          // Sound toggle card
                          _buildSettingsCard(
                            icon: _soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            iconColor: _soundEnabled
                                ? AppStyles.warning
                                : AppStyles.textSecondary,
                            title: 'Звук',
                            subtitle: _soundEnabled ? 'Включён' : 'Выключен',
                            trailing: _buildToggle(
                              value: _soundEnabled,
                              onChanged: _toggleSound,
                            ),
                          ),

                          SizedBox(height: 16),

                          // Unique Cards Toggle
                          _buildSettingsCard(
                            icon: Icons.style_rounded,
                            iconColor: _uniqueCardsEnabled
                                ? AppStyles.accent
                                : AppStyles.textSecondary,
                            title: 'Уникальные карточки',
                            subtitle: _uniqueCardsEnabled
                                ? 'Включены'
                                : 'Выключены',
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
                                    padding: EdgeInsets.only(
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    child: Column(
                                      children: [
                                        // Card Style Button
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: 30,
                                          ), // Indent sub-settings
                                          child: _buildSettingsCard(
                                            icon: Icons.color_lens_rounded,
                                            iconColor: AppStyles.accent,
                                            title: 'Стиль карточек',
                                            subtitle: _cardStyle,
                                            onTap: _chooseCardStyle,
                                            trailing: Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppStyles.textSecondary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),

                                        // Player Faces Toggle
                                        Padding(
                                          padding: EdgeInsets.only(left: 30),
                                          child: _buildSettingsCard(
                                            icon: Icons
                                                .face_retouching_natural_rounded,
                                            iconColor: _playerFacesEnabled
                                                ? AppStyles.accent
                                                : AppStyles.textSecondary,
                                            title: 'Лица игроков',
                                            subtitle: _playerFacesEnabled
                                                ? 'На карточках'
                                                : 'Без лиц',
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

                          SizedBox(height: 30),
                        ],
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
                        onPressed: () => Navigator.of(context).pop(),
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
}
