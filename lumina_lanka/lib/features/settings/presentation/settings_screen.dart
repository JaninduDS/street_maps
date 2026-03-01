import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart'; // <--- IMPORT TRANSLATIONS

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/locale_provider.dart'; // <--- IMPORT LOCALE PROVIDER
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
            const Text(
              'Select Language',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).state = Locale(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0A84FF) : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: isSelected ? Colors.white : Colors.white70,
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.settings ?? 'Settings', // <--- TRANSLATED
          style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600),
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
              style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // 1. DARK MODE TOGGLE (Restored!)
                ListTile(
                  leading: const Icon(CupertinoIcons.moon_stars_fill, color: Colors.white),
                  title: Text(l10n?.darkMode ?? 'Dark Mode', style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)), // <--- TRANSLATED
                  trailing: CupertinoSwitch(
                    activeColor: AppColors.accentGreen,
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                
                // 2. LANGUAGE PICKER
                ListTile(
                  leading: const Icon(CupertinoIcons.globe, color: Colors.white),
                  title: Text(l10n?.language ?? 'Language', style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)), // <--- TRANSLATED
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getLanguageName(currentLocale.languageCode), 
                        style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5))
                      ),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 16),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context, ref, currentLocale),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // === SUPPORT & EMERGENCY ===
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'SUPPORT & EMERGENCY',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.phone_fill, color: AppColors.accentRed),
                  title: const Text('Council Emergency Line', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)),
                  subtitle: Text('119', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5))),
                  trailing: const Icon(CupertinoIcons.arrow_up_right_square, color: AppColors.accentRed, size: 18),
                  onTap: () => _makePhoneCall('119'),
                ),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.bolt_fill, color: AppColors.accentAmber),
                  title: const Text('Electricity Board (CEB)', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)),
                  subtitle: Text('1987', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5))),
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
                Image.asset('assets/icons/light_icon.png', width: 48, height: 48, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                const Text(
                  'Lumina Lanka',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version 1.0.0 (Maharagama Pilot)',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}