import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart'; // <--- IMPORT TRANSLATIONS

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/locale_provider.dart'; // <--- IMPORT LOCALE PROVIDER
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _localIsDark;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, Locale currentLocale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex', 
                color: Theme.of(context).textTheme.bodyLarge?.color, 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 24),
            _buildLangOption(context, ref, 'English', 'en', currentLocale.languageCode == 'en'),
            const SizedBox(height: 12),
            _buildLangOption(context, ref, 'සිංහල', 'si', currentLocale.languageCode == 'si'),
            const SizedBox(height: 12),
            _buildLangOption(context, ref, 'தமிழ்', 'ta', currentLocale.languageCode == 'ta'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(BuildContext context, WidgetRef ref, String title, String code, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).state = Locale(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withOpacity(0.2) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0A84FF) : (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: isSelected 
                    ? (isDark ? Colors.white : Colors.black) 
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) const Icon(CupertinoIcons.check_mark_circled_solid, color: Color(0xFF0A84FF)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    
    // Load the translations for the current context
    // (If this shows a red error, run `flutter pub get` in your terminal)
    final l10n = AppLocalizations.of(context);

    String getLanguageName(String code) {
      switch (code) {
        case 'si': return 'සිංහල';
        case 'ta': return 'தமிழ்';
        default: return 'English';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.settings ?? 'Settings', // <--- TRANSLATED
          style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // === APPEARANCE ===
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              l10n?.appearance ?? 'APPEARANCE', // <--- TRANSLATED
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // 1. DARK MODE TOGGLE (Restored!)
                ListTile(
                  leading: Icon(CupertinoIcons.moon_stars_fill, color: textColor),
                  title: Text(l10n?.darkMode ?? 'Dark Mode', style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor)), // <--- TRANSLATED
                  trailing: CupertinoSwitch(
                    activeColor: AppColors.accentGreen,
                    value: _localIsDark ?? (themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark)),
                    onChanged: (value) {
                      setState(() {
                        _localIsDark = value;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                          _localIsDark = null; // Clear local override
                        }
                      });
                    },
                  ),
                ),
                Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), height: 1),
                
                // 2. LANGUAGE PICKER
                ListTile(
                  leading: Icon(CupertinoIcons.globe, color: textColor),
                  title: Text(l10n?.language ?? 'Language', style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor)), // <--- TRANSLATED
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getLanguageName(currentLocale.languageCode), 
                        style: TextStyle(fontFamily: 'GoogleSansFlex', color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))
                      ),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_right, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), size: 16),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context, ref, currentLocale),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // === SUPPORT & EMERGENCY ===
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'SUPPORT & EMERGENCY',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.phone_fill, color: AppColors.accentRed),
                  title: Text('Council Emergency Line', style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor)),
                  subtitle: Text('119', style: TextStyle(fontFamily: 'GoogleSansFlex', color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
                  trailing: const Icon(CupertinoIcons.arrow_up_right_square, color: AppColors.accentRed, size: 18),
                  onTap: () => _makePhoneCall('119'),
                ),
                Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.bolt_fill, color: AppColors.accentAmber),
                  title: Text('Electricity Board (CEB)', style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor)),
                  subtitle: Text('1987', style: TextStyle(fontFamily: 'GoogleSansFlex', color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
                  trailing: const Icon(CupertinoIcons.arrow_up_right_square, color: AppColors.accentAmber, size: 18),
                  onTap: () => _makePhoneCall('1987'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // === ABOUT ===
          Center(
            child: Column(
              children: [
                Image.asset('assets/icons/light_icon.png', width: 48, height: 48, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'Lumina Lanka',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version 1.0.0 (Maharagama Pilot)',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}