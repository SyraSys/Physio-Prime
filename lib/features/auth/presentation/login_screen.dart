import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Supabase Authentication', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Assigned to Developer 1\nSupabase signInWithPassword, signUp, Google OAuth, and /auth/me sync',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.bodyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
