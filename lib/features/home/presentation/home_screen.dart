import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Nagpur, MH',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Icon(LucideIcons.chevronDown, size: 16),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Certified Physiotherapy\nat Your Home or Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Orthopedic, neuro, sports & post-op rehab by verified specialists.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () {},
                    child: const Text('Book Consultation'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Clinical Specialties', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Dev 1 Module: Categories carousel (/categories)'),
            const SizedBox(height: 24),
            Text('Common Conditions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Dev 1 Module: Symptoms & Conditions list (/symptoms)'),
          ],
        ),
      ),
    );
  }
}
