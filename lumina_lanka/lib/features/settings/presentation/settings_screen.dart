import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // === APPEARANCE ===
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'APPEARANCE',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.moon_stars_fill, color: Colors.white),
                  title: const Text('Dark Mode', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)),
                  trailing: CupertinoSwitch(
                    activeColor: AppColors.accentGreen,
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.globe, color: Colors.white),
                  title: const Text('Language', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5))),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 16),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinhala & Tamil coming soon!')));
                  },
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