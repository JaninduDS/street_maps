import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_notifications.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _isStep2 = false; // false = email step, true = password step

  static const _blue = Color(0xFF0A84FF);
  static const _bgColor = Color(0xFF1C1C1E);
  static const _fieldBg = Color(0xFF2C2C2E);
  static const _borderColor = Color(0xFF3A3A3C);

  Future<void> _handleLogin() async {
    if (_passwordController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Login Failed: ${e.toString()}',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleContinue() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppNotifications.show(
        context: context,
        message: 'Please enter a valid email address',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        iconColor: Colors.redAccent,
      );
      return;
    }
    setState(() => _isStep2 = true);
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  void _goBack() {
    setState(() => _isStep2 = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 800,
          height: 560,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Close button
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildCloseButton(),
                ),
                // Content with animated crossfade
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isStep2
                      ? _buildStep2(key: const ValueKey('step2'))
                      : _buildStep1(key: const ValueKey('step1')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          color: Colors.white54,
          size: 16,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Email Entry
  // ─────────────────────────────────────────────
  Widget _buildStep1({Key? key}) {
    return SizedBox(
      key: key,
      width: 800,
      height: 560,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // App icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: _blue,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Continue with Email Address',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600, // Reduced from bold
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              'You can sign in if you already have an account,\nor contact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white.withOpacity(0.45),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Email field
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _emailFocus.hasFocus ? _blue : _borderColor,
                  width: _emailFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                cursorColor: _blue,
                style: const TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.white,
                  fontSize: 16,
                ),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  hintStyle: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _handleContinue(),
              ),
            ),
            const SizedBox(height: 24),
            // Role info section
            _buildRoleInfoSection(),
            const SizedBox(height: 28),
            // Continue button (360x60)
            SizedBox(
              width: 360,
              height: 60,
              child: CupertinoButton(
                color: _blue,
                borderRadius: BorderRadius.circular(14),
                padding: EdgeInsets.zero,
                onPressed: _handleContinue,
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 18,
                    fontWeight: FontWeight.w500, // Reduced from w600
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleInfoSection() {
    return Column(
      children: [
        // Role icon
        Icon(
          CupertinoIcons.person_2_fill,
          color: _blue.withOpacity(0.7),
          size: 28,
        ),
        const SizedBox(height: 10),
        Text(
          'Your Lumina Lanka account determines your access level. '
          'Staff accounts are assigned one of the following roles: '
          'Council members receive full dashboard and administrative access. '
          'Electricians can manage repair tasks and field assignments. '
          'Markers can survey and record streetlight data.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white.withOpacity(0.4),
            fontSize: 12.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Learn more about staff roles...',
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: _blue,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: Password Entry
  // ─────────────────────────────────────────────
  Widget _buildStep2({Key? key}) {
    return SizedBox(
      key: key,
      width: 800,
      height: 560,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 140),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // App icon (grey for step 2, like Apple)
            Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: Colors.white.withOpacity(0.35),
              size: 52,
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Sign in to Lumina Lanka',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600, // Reduced from bold
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              'You will be signed in to the Street Light\nManagement System.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white.withOpacity(0.45),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Combined email + password card
            Container(
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _passwordFocus.hasFocus ? _blue : _borderColor,
                  width: _passwordFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  // Email row (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _borderColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'GoogleSansFlex',
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emailController.text.trim(),
                                style: const TextStyle(
                                  fontFamily: 'GoogleSansFlex',
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Password row
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            autofocus: true,
                            cursorColor: _blue,
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                        ),
                        // Submit arrow
                        GestureDetector(
                          onTap: _isLoading ? null : _handleLogin,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const CupertinoActivityIndicator(
                                    radius: 8,
                                  )
                                : const Icon(
                                    CupertinoIcons.arrow_right,
                                    color: _blue,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Back / change email link
            GestureDetector(
              onTap: _goBack,
              child: const Text(
                'Use a Different Email  ›',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: _blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Forgot password
            GestureDetector(
              onTap: () {
                // TODO: implement forgot password
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: _blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
