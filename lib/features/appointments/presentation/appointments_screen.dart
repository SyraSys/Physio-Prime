import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Appointments & Telehealth', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Assigned to Developer 2\nEndpoints: GET /appointments, POST /appointments/:id/reschedule, POST /appointments/:id/cancel, GET /appointments/:id/video-token',
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
