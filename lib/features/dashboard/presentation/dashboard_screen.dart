import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Prescriptions & Records', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Assigned to Developer 2\nEndpoints: GET /me/prescriptions, GET /me/notifications',
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
