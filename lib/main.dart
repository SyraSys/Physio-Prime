import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/api_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/skeleton_loading.dart';

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
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Supabase Auth using the discovered credentials
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    publishableKey: ApiConstants.supabaseAnonKey,
  );

  // Global Apple-grade error boundary: renders smooth shimmer skeleton UI instead of static error/loading text
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const ClinicLoadingSkeletonScreen();
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
