import 'dart:io';

void main() {
  final files = [
    'lib/features/settings/presentation/settings_screen.dart',
    'lib/features/profile/presentation/profile_screen.dart',
  ];

  for (final path in files) {
    var file = File(path);
    var content = file.readAsStringSync();

    // 1. Remove hardcoded scaffold backgrounds
    content = content.replaceAll('backgroundColor: AppColors.bgPrimary,', '');

    // 2. We need 'final isDark = Theme.of(context).brightness == Brightness.dark;' in build methods and helper methods.
    // Actually, setting color to Theme.of(context).textTheme.bodyLarge?.color is safer, but wait.
    // It's easier to use a helper function or just replace specific strings if isDark is defined.
    // Let's add 'final isDark = Theme.of(context).brightness == Brightness.dark;' at the top of build.
  }
}
