import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Physiotherapists')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Doctor Catalog & Filters', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Assigned to Developer 1\nEndpoints: GET /doctors, GET /doctors/:id, GET /doctors/:id/reviews',
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
