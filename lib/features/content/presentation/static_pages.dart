import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About PhysioPrime'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our Mission', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            const Text(
              'PhysioPrime was founded to make high-standard, accredited physiotherapy care accessible directly at patients\' doorsteps and via secure, low-latency teleconsultations.',
              style: TextStyle(fontSize: 14, color: AppColors.bodyText, height: 1.55),
            ),
            const SizedBox(height: 20),
            Text('Clinical Quality Standards', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'Every clinician on the PhysioPrime network is verified against their State Council of Occupational & Physiotherapy (OTPT) registration. We follow evidence-based recovery protocols and use sanitized, portable electrotherapy and mobility equipment.',
              style: TextStyle(fontSize: 14, color: AppColors.bodyText, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How It Works'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _StepTile(step: '1', title: 'Choose Mode & Specialist', desc: 'Select between Home Visit or HD Video Consult. Filter doctors by orthopedic, neuro, or sports specializations.'),
          _StepTile(step: '2', title: 'Select Date & Capacity Slot', desc: 'Pick your preferred date and 1-hour slot window. All times are synchronized with doctor availability.'),
          _StepTile(step: '3', title: 'Consultation & Assessment', desc: 'The physiotherapist visits your home with clinical equipment or connects over video to perform musculoskeletal assessment.'),
          _StepTile(step: '4', title: 'Digital Prescription & Exercises', desc: 'Receive personalized exercise regimens and precautions directly in your Patient Dashboard.'),
        ],
      ),
    );
  }
}

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing & Plans'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home Visit Session', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('₹799 - ₹1,200 / session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 10),
                    const Text('• 45-60 minute personalized 1-on-1 session\n• Portable electrotherapy, IFT/TENS & manual therapy included\n• Zero travel hassle for elderly or post-op patients'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HD Video Teleconsultation', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('₹499 - ₹699 / session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
                    const SizedBox(height: 10),
                    const Text('• 30-40 minute live video assessment\n• Postural correction & guided home exercises\n• Digital prescription delivered to app'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _StepTile({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.bodyText, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
