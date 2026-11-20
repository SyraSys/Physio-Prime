import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/api_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full-screen edge-to-edge transparent system overlay for modern iOS & Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Supabase Auth using the discovered credentials
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    publishableKey: ApiConstants.supabaseAnonKey,
  );

  // Global Apple-grade error boundary: completely prevents red screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF8FAFB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 30,
                  color: Color(0xFF0891B2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PhysioPrime',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Loading clinic details... please swipe down to refresh.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: PhysioPrimeApp(),
    ),
  );
}

class PhysioPrimeApp extends StatefulWidget {
  const PhysioPrimeApp({super.key});

  @override
  State<PhysioPrimeApp> createState() => _PhysioPrimeAppState();
}

class _PhysioPrimeAppState extends State<PhysioPrimeApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-warm & decode top-of-fold brand assets into GPU memory to eliminate initial frame jank
    precacheImage(const AssetImage('assets/images/pp_monogram.png'), context);
    precacheImage(const AssetImage('assets/images/hero_doctor.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhysioPrime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
