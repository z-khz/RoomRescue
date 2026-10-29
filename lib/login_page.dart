import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isCreatingAccount = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submitAuth() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Enter your email and password to continue.');
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isCreatingAccount) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      showMessage(error.message ?? 'We could not sign you in.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'asset/room.png',
                  height: 140,
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'RoomRescue',
                style: GoogleFonts.bebasNeue(
                  fontSize: 48,
                  color: const Color(0xFF123C69),
                ),
              ),
              const Text(
                'Report it. Fix it. Done.',
                style: TextStyle(fontSize: 18, color: Color(0xFF52708A)),
              ),
              const SizedBox(height: 38),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : submitAuth,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    isLoading
                        ? (isCreatingAccount
                              ? 'Creating account...'
                              : 'Signing in...')
                        : (isCreatingAccount ? 'Create account' : 'Sign in'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => setState(
                        () => isCreatingAccount = !isCreatingAccount,
                      ),
                child: Text(
                  isCreatingAccount
                      ? 'Already have an account? Sign in'
                      : 'New to RoomRescue? Create an account',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your space, cared for.',
                style: TextStyle(color: Color(0xFF52708A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
