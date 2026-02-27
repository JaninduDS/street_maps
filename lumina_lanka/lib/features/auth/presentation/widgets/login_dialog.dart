import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: GlassmorphicContainer(
          width: 350,
          height: 400,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
          borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)]),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF0A84FF), size: 48),
              const SizedBox(height: 16),
              const Text("Staff Portal", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField("Email", _emailController, false),
              const SizedBox(height: 16),
              _buildTextField("Password", _passwordController, true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: const Color(0xFF0A84FF),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading ? const CupertinoActivityIndicator() : const Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool obscure) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38), border: InputBorder.none),
      ),
    );
  }
}
