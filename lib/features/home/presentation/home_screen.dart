import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../doctors/domain/doctor_model.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../domain/category_model.dart';
import '../domain/symptom_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cbNameController = TextEditingController();
  final TextEditingController _cbPhoneController = TextEditingController();
  final TextEditingController _cbMessageController = TextEditingController();
  String _cbServiceSelected = 'Caretaker';

  // Dynamic Typewriter Headline State
  static const List<String> _typewriterPhrases = [
    'Back and Neck Pain.',
    'Sciatica & Disc Issues.',
    'Knee & Joint Mobility.',
    'Sports Injury Rehab.',
    'Post-Stroke Recovery.',
    'Post-Surgery Healing.',
  ];
  int _currentPhraseIndex = 0;
  String _currentDisplayedText = '';
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _typewriterTimer;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  // 5-Step Recovery Process active step (Defaults to step 0 - Step 01)
  int _activeRecoveryStep = 0;
  final ScrollController _careStepsScrollController = ScrollController();

  void _selectCareStep(int index) {
    setState(() => _activeRecoveryStep = index);
    if (_careStepsScrollController.hasClients) {
      final maxScroll = _careStepsScrollController.position.maxScrollExtent;
      // 130px card + 26px connector = ~156px per step
      final target = (index * 156.0 - 20.0).clamp(0.0, maxScroll);
      _careStepsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _startTypewriter();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() => _cursorVisible = !_cursorVisible);
      }
    });
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;
      final fullText = _typewriterPhrases[_currentPhraseIndex];

      setState(() {
        if (!_isDeleting) {
          if (_charIndex < fullText.length) {
            _charIndex++;
            _currentDisplayedText = fullText.substring(0, _charIndex);
          } else {
            // Pause at complete phrase before deleting
            _isDeleting = true;
            _typewriterTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (mounted) _startTypewriter();
            });
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
            _currentDisplayedText = fullText.substring(0, _charIndex);
          } else {
            _isDeleting = false;
            _currentPhraseIndex = (_currentPhraseIndex + 1) % _typewriterPhrases.length;
            _typewriterTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _startTypewriter();
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();
    _careStepsScrollController.dispose();
    _searchController.dispose();
    _cbNameController.dispose();
    _cbPhoneController.dispose();
    _cbMessageController.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    final locationsAsync = ref.read(locationsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FrostedGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          backgroundColor: const Color(0xF7FFFFFF), // iOS sheet translucent
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Your City & Area', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                locationsAsync.when(
                  data: (master) {
                    final areas = ['All Areas', ...master.areas];
                    final currentArea = ref.watch(selectedAreaProvider);

                    return SizedBox(
                      height: 380,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: areas.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderSoft),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final isSelected = (area == 'All Areas' && currentArea == null) || currentArea == area;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            title: Text(
                              area,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.headingText,
                                fontSize: 15,
                              ),
                            ),
                            trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary, size: 18) : null,
                            onTap: () {
                              ref.read(selectedAreaProvider.notifier).state = area == 'All Areas' ? null : area;
                              ref.read(doctorFilterProvider.notifier).update(
                                    (s) => s.copyWith(
                                      area: area == 'All Areas' ? null : area,
                                      clearArea: area == 'All Areas',
                                    ),
                                  );
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CupertinoActivityIndicator(radius: 14)),
                  ),
                  error: (error, stack) => const Text('Could not load areas. Please try again.'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchSubmitted() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: query));
    }
    context.go('/doctors');
  }

  void _submitCallBackLead() {
    final name = _cbNameController.text.trim();
    final phone = _cbPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and phone number.')),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Call Back Requested'),
        content: Text('Thank you, $name! Our clinical care coordinator will contact you at $phone within 15 minutes regarding $_cbServiceSelected services.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(ctx);
              _cbNameController.clear();
              _cbPhoneController.clear();
              _cbMessageController.clear();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedArea = ref.watch(selectedAreaProvider);
    final selectedMode = ref.watch(selectedModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final symptomsAsync = ref.watch(symptomsProvider);
    final doctorsAsync = ref.watch(doctorsListProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: FluidPressable(
          onTap: () => _showLocationPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    selectedArea != null ? '$selectedArea, $selectedCity' : selectedCity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.headingText),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 13, color: AppColors.primary),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FluidPressable(
              onTap: () {
                if (authState.status == AuthStatus.authenticated) {
                  context.push('/profile');
                } else {
                  context.push('/login');
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(LucideIcons.user, size: 18, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open AI Triage or WhatsApp Support
          context.push('/caretaker');
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(LucideIcons.bot, color: Colors.white, size: 20),
        label: const Text(
          'AI Triage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        displacement: 90,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(symptomsProvider);
          ref.invalidate(locationsProvider);
          ref.invalidate(doctorsListProvider);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 10, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. HERO SECTION (Apple Translucent Container)
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6FFFA), Color(0xFFF0FDFA), Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x330891B2), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120891B2),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: India's #1 On-Demand Physiotherapy Platform
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: Color(0xFF047857), size: 13),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "India's #1 On-Demand Physiotherapy Platform",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Dynamic Typewriter Headline
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Book Prime\nPhysiotherapist for\n',
                            style: TextStyle(
                              color: AppColors.headingText,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.18,
                            ),
                          ),
                          TextSpan(
                            text: _currentDisplayedText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.18,
                            ),
                          ),
                          if (_cursorVisible)
                            const TextSpan(
                              text: '|',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 27,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connect with certified Prime Physiotherapists for expert care, personalized treatment, and recovery from the comfort of home.',
                      style: TextStyle(color: AppColors.bodyText, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 18),

                    // Consultation Mode Pill Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FluidPressable(
                              onTap: () {
                                ref.read(selectedModeProvider.notifier).state = 'home';
                                ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'home'));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'home' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.home, size: 14, color: selectedMode == 'home' ? Colors.white : AppColors.bodyText),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'Home Visit Physio',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: selectedMode == 'home' ? Colors.white : AppColors.bodyText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: FluidPressable(
                              onTap: () {
                                ref.read(selectedModeProvider.notifier).state = 'online';
                                ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'online'));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'online' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.video, size: 14, color: selectedMode == 'online' ? Colors.white : AppColors.bodyText),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'Online Video Consult',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: selectedMode == 'online' ? Colors.white : AppColors.bodyText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dual Call-to-Action Buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 280;
                        final button1 = FluidPressable(
                          onTap: () => context.go('/doctors'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Color(0x260891B2), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.sparkles, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'See Physiotherapists',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(LucideIcons.arrowRight, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        );

                        final button2 = FluidPressable(
                          onTap: () => context.go('/doctors'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Color(0x26F59E0B), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.calendar, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Check Available Slots',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(LucideIcons.arrowRight, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              button1,
                              const SizedBox(height: 8),
                              button2,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: button1),
                            const SizedBox(width: 8),
                            Expanded(child: button2),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Integrated Universal Search & Geolocation Filter Bar
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _onSearchSubmitted(),
                            decoration: const InputDecoration(
                              hintText: 'Search symptoms (Back pain, Knee rehab), doctors...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                              prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.primary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.borderSoft),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: FluidPressable(
                                  onTap: () => _showLocationPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            selectedArea != null ? '$selectedArea, $selectedCity' : selectedCity,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingText),
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronDown, size: 13, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              FluidPressable(
                                onTap: _onSearchSubmitted,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Search',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // 2. SOCIAL PROOF & METRICS COUNTER BAR
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft, width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _MetricItem(count: '10K+', label: 'Happy Patients', icon: LucideIcons.smile)),
                    Container(height: 28, width: 1, color: AppColors.borderSoft),
                    Expanded(child: _MetricItem(count: '100+', label: 'Verified Doctors', icon: LucideIcons.checkCheck)),
                    Container(height: 28, width: 1, color: AppColors.borderSoft),
                    Expanded(child: _MetricItem(count: '10+', label: 'Active Cities', icon: LucideIcons.mapPin)),
                    Container(height: 28, width: 1, color: AppColors.borderSoft),
                    Expanded(child: _MetricItem(count: '5K+', label: 'Recovery Stories', icon: LucideIcons.star)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ==============================================================
              // 3. TARGETED CLINICAL TREATMENTS: "Find Specialist By Symptoms"
              // ==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x330891B2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.activity, size: 11, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Targeted Clinical Treatments', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Find Specialist By ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                            TextSpan(text: 'Symptoms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FluidPressable(
                    onTap: () => context.go('/doctors'),
                    child: const Row(
                      children: [
                        Text('Explore All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 2),
                        Icon(LucideIcons.arrowUpRight, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your condition for tailored rehabilitation plans designed by senior certified physiotherapists.',
                style: TextStyle(fontSize: 12, color: AppColors.bodyText),
              ),
              const SizedBox(height: 14),
              symptomsAsync.when(
                data: (symptoms) {
                  return SizedBox(
                    height: 260,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: symptoms.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final sym = symptoms[index];
                        return _AnatomicalConditionCard(
                          symptom: sym,
                          onTap: () {
                            ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(symptom: sym.title));
                            context.go('/doctors');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                error: (error, stack) => Text('Error loading symptoms: $error'),
              ),
              const SizedBox(height: 28),

              // ==============================================================
              // 4. CLINICAL SPECIALTIES: "Specialized Therapy Categories"
              // ==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x330891B2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.stethoscope, size: 11, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Clinical Specialties', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Specialized Therapy ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                            TextSpan(text: 'Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FluidPressable(
                    onTap: () => context.go('/doctors'),
                    child: const Row(
                      children: [
                        Text('Find Therapists', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 2),
                        Icon(LucideIcons.arrowUpRight, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse our clinical divisions to find doctors tailored to your exact physical rehabilitation requirements.',
                style: TextStyle(fontSize: 12, color: AppColors.bodyText),
              ),
              const SizedBox(height: 14),
              categoriesAsync.when(
                data: (categories) {
                  return SizedBox(
                    height: 275,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return _TherapyCategoryCard(
                          category: cat,
                          onTap: () {
                            ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: cat.slug));
                            context.go('/doctors');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                error: (error, stack) => Text('Error loading categories: $error'),
              ),
              const SizedBox(height: 32),

              // ==============================================================
              // 5. CARE JOURNEY: "How Your Recovery Process Works" (5 Steps)
              // ==============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('Seamless Care Journey', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'How Your ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                            TextSpan(text: 'Recovery Process', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            TextSpan(text: '\nWorks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'From your first click to pain-free mobility in 5 easy, transparent steps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 5 Step Horizontal Pipeline with Auto-Scroll & Drag Sync
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification && _careStepsScrollController.hasClients) {
                          final offset = _careStepsScrollController.offset;
                          final estIndex = (offset / 140.0).round().clamp(0, 4);
                          if (estIndex != _activeRecoveryStep) {
                            setState(() => _activeRecoveryStep = estIndex);
                          }
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _careStepsScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _CareStepPill(
                              stepNum: '01',
                              title: 'Search & Describe',
                              subtitle: 'Identify pain area',
                              icon: LucideIcons.search,
                              iconColor: const Color(0xFF2563EB),
                              isActive: _activeRecoveryStep == 0,
                              onTap: () => _selectCareStep(0),
                            ),
                            _CareStepConnector(),
                            _CareStepPill(
                              stepNum: '02',
                              title: 'Choose Specialist',
                              subtitle: 'Review credentials',
                              icon: LucideIcons.userCheck,
                              iconColor: const Color(0xFF0891B2),
                              isActive: _activeRecoveryStep == 1,
                              onTap: () => _selectCareStep(1),
                            ),
                            _CareStepConnector(),
                            _CareStepPill(
                              stepNum: '03',
                              title: 'Book Preferred Slot',
                              subtitle: 'Instant confirmation',
                              icon: LucideIcons.calendar,
                              iconColor: const Color(0xFF16A34A),
                              isActive: _activeRecoveryStep == 2,
                              onTap: () => _selectCareStep(2),
                            ),
                            _CareStepConnector(),
                            _CareStepPill(
                              stepNum: '04',
                              title: 'Home Visit / HD',
                              subtitle: 'Hands-on therapy',
                              icon: LucideIcons.home,
                              iconColor: const Color(0xFF9333EA),
                              isActive: _activeRecoveryStep == 3,
                              onTap: () => _selectCareStep(3),
                            ),
                            _CareStepConnector(),
                            _CareStepPill(
                              stepNum: '05',
                              title: 'Track Recovery',
                              subtitle: 'Prescriptions & exercises',
                              icon: LucideIcons.heartPulse,
                              iconColor: const Color(0xFFEA580C),
                              isActive: _activeRecoveryStep == 4,
                              onTap: () => _selectCareStep(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Sliding Dot Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isSel = index == _activeRecoveryStep;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectCareStep(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: isSel ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Active Step Detail Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x330891B2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STEP DETAILS (0${_activeRecoveryStep + 1} OF 05)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStepTitle(_activeRecoveryStep),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStepDescription(_activeRecoveryStep),
                            style: const TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          FluidPressable(
                            onTap: () => context.go('/doctors'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Start Booking Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  SizedBox(width: 6),
                                  Icon(LucideIcons.arrowRight, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ==============================================================
              // 6. TOP PRIME PHYSIOTHERAPISTS (Doctors Carousel)
              // ==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x330891B2)),
                        ),
                        child: const Text('Certified Healthcare Specialists', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Top Prime ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                            TextSpan(text: 'Physiotherapists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  FluidPressable(
                    onTap: () => context.go('/doctors'),
                    child: const Row(
                      children: [
                        Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(LucideIcons.arrowRight, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Hand-picked certified physical therapists available for home visits and HD video consultations today.',
                style: TextStyle(fontSize: 12, color: AppColors.bodyText),
              ),
              const SizedBox(height: 14),
              doctorsAsync.when(
                data: (doctors) {
                  return SizedBox(
                    height: 350,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: doctors.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final doc = doctors[index];
                        return _PrimeDoctorHomeCard(doctor: doc);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())),
                error: (error, stack) => Text('Error loading therapists: $error'),
              ),
              const SizedBox(height: 32),

              // ==============================================================
              // 7. REAL PEOPLE, REAL RECOVERY STORIES (Pain Scale Comparison)
              // ==============================================================
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.star, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text('5,000+ Verified Patient Success Stories', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Real People, Real ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                      TextSpan(text: 'Recovery\nStories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Read inspiring transformations from patients who regained mobility and returned to living pain-free.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _RecoveryStoryCard(
                      initialPain: '8/10',
                      recoveredPain: '1/10',
                      duration: '4 weeks therapy',
                      quote: 'I was unable to walk without crutches after my knee surgery. Dr. Tarannum arrived at my home every day with specialized mobilization equipment. Within 1 month, I was walking pain-free!',
                      patientName: 'Devshree K.',
                      treatmentAttribution: 'Post Knee Surgery Rehab • treated by Dr. Tarannum Sayyed',
                    ),
                    SizedBox(width: 14),
                    _RecoveryStoryCard(
                      initialPain: '9/10',
                      recoveredPain: '0/10',
                      duration: '3 weeks therapy',
                      quote: 'I had shooting leg pain from sitting at my IT job 10 hours a day. The dry needling and core alignment sessions from PhysioPrime cured my pain without any surgery.',
                      patientName: 'Rajesh V. Sharma',
                      treatmentAttribution: 'Severe Sciatica & Lumbar Strain • treated by Dr. Pritam Rathod',
                    ),
                    SizedBox(width: 14),
                    _RecoveryStoryCard(
                      initialPain: '7/10',
                      recoveredPain: '1/10',
                      duration: '5 weeks care',
                      quote: 'As a new mother, traveling to a clinic was impossible. PhysioPrime allowed me to get gentle postpartum pelvic therapy at home. Friendly, professional, and life-saving care!',
                      patientName: 'Priya N. Deshmukh',
                      treatmentAttribution: 'Postpartum Pelvic Care • treated by Dr. Jayashree Ingole',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ==============================================================
              // 8. THE PHYSIOPRIME ADVANTAGE: "Why Patients & Doctors Trust Us"
              // ==============================================================
              const _WhyTrustUsSection(),
              const SizedBox(height: 32),

              // ==============================================================
              // 9. GROW WITH US: Therapist Careers Section
              // ==============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('💼 Career Opportunities', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'Grow ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                          TextSpan(text: 'With Us', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Take the next step in your physiotherapy career and grow with a team that values expertise, compassion, and continuous learning.',
                      style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    FluidPressable(
                      onTap: () => context.push('/careers'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Career Opportunities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(LucideIcons.arrowRight, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: const [
                        _CareerTag(icon: LucideIcons.smile, text: '100+ Happy Employees'),
                        _CareerTag(icon: LucideIcons.award, text: 'Top Workplace'),
                        _CareerTag(icon: LucideIcons.clock, text: 'Flexible Hours'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CareerPillarCard(icon: LucideIcons.users, title: 'Expert Team', subtitle: 'Work with top physios', color: Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CareerPillarCard(icon: LucideIcons.graduationCap, title: 'Continuous Learning', subtitle: 'CME workshops', color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CareerPillarCard(icon: LucideIcons.trendingUp, title: 'Career Growth', subtitle: 'Path to senior roles', color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CareerPillarCard(icon: LucideIcons.heart, title: 'Patient Impact', subtitle: 'Make real difference', color: Colors.pink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ==============================================================
              // 10. COMPASSIONATE CARE AT HOME: Caretaker Form & Hotline
              // ==============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('🤝 Need a Caretaker?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'Compassionate Care ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.headingText)),
                          TextSpan(text: 'At Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Looking for a trained caretaker for yourself or a loved one? Share your details and our team will contact you to arrange personalized care at home.',
                      style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: const [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.phone, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('+91 96232 04165', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headingText)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mail, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('care@physio-prime.in', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // "Get a Call Back" Lead Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSoft),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Get a Call Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cbNameController,
                            decoration: InputDecoration(
                              labelText: 'Your Name *',
                              labelStyle: const TextStyle(fontSize: 12),
                              hintText: 'e.g. Rahul Sharma',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _cbServiceSelected,
                            decoration: InputDecoration(
                              labelText: 'Service You Need *',
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Caretaker', child: Text('Caretaker / Attendant')),
                              DropdownMenuItem(value: 'Elderly Support', child: Text('Elderly Mobility Support')),
                              DropdownMenuItem(value: 'Stroke Recovery', child: Text('Post-Stroke Bedside Care')),
                              DropdownMenuItem(value: 'Post-Surgery Attendant', child: Text('Post-Surgery Caregiver')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _cbServiceSelected = val);
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _cbPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              labelStyle: const TextStyle(fontSize: 12),
                              hintText: '10-digit mobile number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _cbMessageController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Message (optional)',
                              labelStyle: const TextStyle(fontSize: 12),
                              hintText: 'Tell us briefly about the care you need',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FluidPressable(
                              onTap: _submitCallBackLead,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.send, color: Colors.white, size: 14),
                                    SizedBox(width: 8),
                                    Text('Request Call Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ==============================================================
              // 11. SITE FOOTER
              // ==============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PhysioPrime',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Optimizing motion. Improving lives.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PhysioPrime connects patients with trusted physiotherapists for professional clinic and home-based physiotherapy care.',
                      style: TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    FluidPressable(
                      onTap: () => context.go('/doctors'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Book a Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(LucideIcons.arrowRight, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 14),
                    const Text('Platform & Patient Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.headingText)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _FooterLink(text: 'Find Therapists', onTap: () => context.go('/doctors')),
                        _FooterLink(text: 'Categories', onTap: () => context.go('/doctors')),
                        _FooterLink(text: 'Conditions', onTap: () => context.go('/doctors')),
                        _FooterLink(text: 'Care Careers', onTap: () => context.push('/careers')),
                        _FooterLink(text: 'Home Caretakers', onTap: () => context.push('/caretaker')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('© 2026 PhysioPrime Healthcare. All rights reserved.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Search & Describe Symptoms';
      case 1:
        return 'Choose Certified Specialist';
      case 2:
        return 'Book Preferred Time Slot';
      case 3:
        return 'Home Visit / HD Consultation';
      case 4:
        return 'Track Full Recovery';
      default:
        return '';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Identify your pain area or condition using our clinical symptom catalog or smart search to locate appropriate therapy divisions.';
      case 1:
        return 'Review verified council registrations, patient satisfaction ratings, years of clinical experience, and upfront per-session rates.';
      case 2:
        return 'Select morning, afternoon, or evening appointment slots with instant automated calendar booking and zero waiting queues.';
      case 3:
        return 'Receive specialized hands-on physical rehabilitation in your home with portable clinical electrotherapy equipment or 1-on-1 HD video consult.';
      case 4:
        return 'Receive digital prescriptions, daily posture exercises, and continuous follow-up support until complete pain-free mobility.';
      default:
        return '';
    }
  }
}

// =========================================================================
// SUB-WIDGETS & DESIGN COMPONENTS
// =========================================================================

class _MetricItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;

  const _MetricItem({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.headingText, letterSpacing: -0.4)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.bodyText),
        ),
      ],
    );
  }
}

class _AnatomicalConditionCard extends StatelessWidget {
  final SymptomModel symptom;
  final VoidCallback onTap;

  const _AnatomicalConditionCard({required this.symptom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anatomical Visual with Recovery Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: symptom.image != null
                    ? CachedNetworkImage(
                        imageUrl: symptom.image!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFF0F172A)),
                        errorWidget: (context, url, error) => Container(color: const Color(0xFF0F172A), child: const Center(child: Icon(LucideIcons.activity, color: AppColors.primary))),
                      )
                    : Container(
                        height: 110,
                        color: const Color(0xFF0F172A),
                        child: const Center(child: Icon(LucideIcons.activity, color: AppColors.primary)),
                      ),
              ),
              if (symptom.recoveryEstimate != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000), // Glass dark pill
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 10, color: AppColors.brightCyan),
                        const SizedBox(width: 4),
                        Text(
                          symptom.recoveryEstimate!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText),
                ),
                const SizedBox(height: 3),
                Text(
                  symptom.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Common in: ${symptom.department ?? 'Orthopedic'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                FluidPressable(
                  onTap: onTap,
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Verified Specialists',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      SizedBox(width: 2),
                      Icon(LucideIcons.arrowUpRight, size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapyCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _TherapyCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: category.image != null
                    ? CachedNetworkImage(
                        imageUrl: category.image!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.surfaceSoft),
                        errorWidget: (context, url, error) => Container(color: AppColors.surfaceSoft),
                      )
                    : Container(height: 100, color: AppColors.surfaceSoft),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.stethoscope, size: 10, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${category.doctorCount} Doctors',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText),
                ),
                const SizedBox(height: 3),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.3),
                ),
                const SizedBox(height: 8),
                if (category.conditions.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: category.conditions.take(2).map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 10),
                FluidPressable(
                  onTap: onTap,
                  child: const Row(
                    children: [
                      Text(
                        'Verified Specialists',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      SizedBox(width: 3),
                      Icon(LucideIcons.arrowUpRight, size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareStepPill extends StatelessWidget {
  final String stepNum;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isActive;
  final VoidCallback onTap;

  const _CareStepPill({
    required this.stepNum,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderSoft,
            width: isActive ? 1.8 : 0.8,
          ),
          boxShadow: isActive
              ? [const BoxShadow(color: Color(0x1F0891B2), blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text('STEP $stepNum', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headingText),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 9, color: AppColors.bodyText),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareStepConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PrimeDoctorHomeCard extends StatelessWidget {
  final DoctorModel doctor;

  const _PrimeDoctorHomeCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header badges: Rating & Verified Doctor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, size: 11, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        '${doctor.rating} (${doctor.reviewCount})',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (doctor.verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCheck, size: 11, color: Color(0xFF059669)),
                      SizedBox(width: 3),
                      Text('Verified doctor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Circular Doctor Avatar with PRIME Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2EFEA), width: 3),
                ),
                child: ClipOval(
                  child: doctor.photo != null
                      ? CachedNetworkImage(
                          imageUrl: doctor.photo!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.surfaceSoft,
                            child: const Icon(LucideIcons.user, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: AppColors.surfaceSoft,
                          child: const Icon(LucideIcons.user, color: AppColors.primary),
                        ),
                ),
              ),
              Positioned(
                right: -42,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 10, color: Colors.white),
                      SizedBox(width: 3),
                      Text('PRIME', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Doctor Name & Specialty
          Text(
            doctor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText),
          ),
          const SizedBox(height: 2),
          Text(
            doctor.specialty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.mapPin, size: 10, color: Colors.grey),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  doctor.location.displayString,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Experience & Consultation Fee
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Experience', style: TextStyle(fontSize: 9, color: Colors.grey)),
                    Text('${doctor.experienceYears} years', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headingText)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Consultation fee', style: TextStyle(fontSize: 9, color: Colors.grey)),
                    Text(
                      doctor.consultationFeeDisplay,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Next Available Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x330891B2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.clock, size: 11, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  'Next available: ${doctor.nextAvailableDisplay}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FluidPressable(
                  onTap: () => context.push('/doctor/${doctor.slug}', extra: doctor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: const Center(
                      child: Text('View profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.headingText)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FluidPressable(
                  onTap: () => context.push('/doctor/${doctor.slug}', extra: doctor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Book now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecoveryStoryCard extends StatelessWidget {
  final String initialPain;
  final String recoveredPain;
  final String duration;
  final String quote;
  final String patientName;
  final String treatmentAttribution;

  const _RecoveryStoryCard({
    required this.initialPain,
    required this.recoveredPain,
    required this.duration,
    required this.quote,
    required this.patientName,
    required this.treatmentAttribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 285,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INITIAL PAIN', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(initialPain, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowRight, size: 12, color: Colors.grey),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AFTER RECOVERY', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(recoveredPain, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(duration, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(LucideIcons.star, size: 11, color: Colors.amber),
              Icon(LucideIcons.star, size: 11, color: Colors.amber),
              Icon(LucideIcons.star, size: 11, color: Colors.amber),
              Icon(LucideIcons.star, size: 11, color: Colors.amber),
              Icon(LucideIcons.star, size: 11, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              '"$quote"',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.35),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.headingText)),
              const SizedBox(width: 3),
              const Icon(LucideIcons.checkCircle2, size: 12, color: AppColors.primary),
            ],
          ),
          Text(treatmentAttribution, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}

enum AdvantageAudience { all, patient, doctor }

class _AdvantageItem {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradientColors;
  final Color themeColor;
  final Color softBgColor;
  final AdvantageAudience audience;
  final List<String> tags;
  final String detailedAudit;
  final List<String> checklist;

  const _AdvantageItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradientColors,
    required this.themeColor,
    required this.softBgColor,
    required this.audience,
    required this.tags,
    required this.detailedAudit,
    required this.checklist,
  });
}

class _WhyTrustUsSection extends StatefulWidget {
  const _WhyTrustUsSection();

  @override
  State<_WhyTrustUsSection> createState() => _WhyTrustUsSectionState();
}

class _WhyTrustUsSectionState extends State<_WhyTrustUsSection> {
  int _selectedAudienceIndex = 0; // 0: All, 1: Patients, 2: Doctors

  static const List<_AdvantageItem> _allAdvantages = [
    _AdvantageItem(
      id: 'certified_doctors',
      title: 'Certified Expert Doctors',
      subtitle: 'Every therapist undergoes a rigorous 5-stage medical credential verification, council registration check, and audit.',
      badge: '100% Verified',
      icon: LucideIcons.shieldCheck,
      themeColor: Color(0xFF2563EB),
      gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      softBgColor: Color(0xFFEFF6FF),
      audience: AdvantageAudience.patient,
      tags: ['5-Stage Council Audit', 'Police Verified'],
      detailedAudit:
          'Every physiotherapist on PhysioPrime undergoes a strict 5-stage clinical onboarding process including MUHS/State Council registration verification, criminal background check, clinical manual therapy evaluation, and bedside etiquette training.',
      checklist: [
        'OT/PT State Council registration check',
        'Criminal background and identity verification',
        'Hands-on clinical skill evaluation by medical panel',
        'Mandatory annual clinical re-audit & patient ratings check',
      ],
    ),
    _AdvantageItem(
      id: 'home_visits',
      title: 'On-Demand Home Visits',
      subtitle: 'Receive specialized rehabilitation in the comfort of your home equipped with portable electrotherapy & manual gear.',
      badge: 'Doorstep Care',
      icon: LucideIcons.home,
      themeColor: Color(0xFF059669),
      gradientColors: [Color(0xFF10B981), Color(0xFF047857)],
      softBgColor: Color(0xFFECFDF5),
      audience: AdvantageAudience.patient,
      tags: ['Portable Modalities', 'Zero Travel Stress'],
      detailedAudit:
          'Eliminate the pain and stress of traveling to crowded hospitals while injured. Certified physiotherapists arrive at your doorstep equipped with portable ultrasound, TENS units, mobilization belts, and sterile rehab gear.',
      checklist: [
        'Hospital-grade portable electrotherapy units provided',
        'Personalized home ergonomics and posture review',
        'Zero commute stress for post-operative recovery',
        'Flexible morning, afternoon & evening visit slots',
      ],
    ),
    _AdvantageItem(
      id: 'video_consult',
      title: 'HD Video Consultation',
      subtitle: 'Connect with senior specialists anywhere for instant posture analysis, exercise guidance, and progress tracking.',
      badge: 'Instant Access',
      icon: LucideIcons.video,
      themeColor: Color(0xFF0891B2),
      gradientColors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
      softBgColor: Color(0xFFECFEFF),
      audience: AdvantageAudience.patient,
      tags: ['Encrypted Telehealth', 'Posture AI Overlay'],
      detailedAudit:
          'Hop into an encrypted high-definition video call from anywhere in India. Senior therapists evaluate dynamic range of motion, demonstrate corrective posture drills, and prescribe tailored exercises in real time.',
      checklist: [
        'End-to-end encrypted telehealth room',
        'Real-time biomechanical movement analysis',
        'Direct tele-rehab for remote & working professionals',
        'Immediate digital post-session exercise summary',
      ],
    ),
    _AdvantageItem(
      id: 'digital_ehr',
      title: 'Digital Prescriptions & EHR',
      subtitle: 'Access your therapy history, custom exercise videos, and digital doctor notes directly in your account dashboard.',
      badge: 'Cloud Sync',
      icon: LucideIcons.fileCheck2,
      themeColor: Color(0xFF7C3AED),
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      softBgColor: Color(0xFFF5F3FF),
      audience: AdvantageAudience.doctor,
      tags: ['HIPAA / FHIR Ready', 'Exercise Library'],
      detailedAudit:
          'Never lose another paper prescription or recovery exercise note. All clinical diagnosis notes, range-of-motion assessments, and customized exercise video prescriptions sync directly to your patient portal.',
      checklist: [
        'Instant PDF prescription export & share',
        'Custom video exercise libraries with rep counters',
        'Pain score improvement tracking graphs',
        'Secure cloud backup with bank-level encryption',
      ],
    ),
    _AdvantageItem(
      id: 'fast_booking',
      title: 'Fast 1-Click Booking',
      subtitle: 'Select preferred dates and morning, afternoon, or evening slots in under 30 seconds with no complex queues.',
      badge: '< 30 Seconds',
      icon: LucideIcons.zap,
      themeColor: Color(0xFFD97706),
      gradientColors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      softBgColor: Color(0xFFFFFBEB),
      audience: AdvantageAudience.doctor,
      tags: ['Live Slots', 'Instant WhatsApp Sync'],
      detailedAudit:
          'Say goodbye to reception lines and long telephone waits. Real-time doctor calendars allow you to reserve home or video slots in under 30 seconds with instant automated appointment confirmations.',
      checklist: [
        'Live therapist calendar availability',
        'One-tap date & time slot selection',
        'Instant SMS & WhatsApp calendar sync',
        'Free rescheduling up to 4 hours before',
      ],
    ),
    _AdvantageItem(
      id: 'transparent_fees',
      title: 'Affordable Transparent Fees',
      subtitle: 'Clear upfront session rates with zero hidden charges. Flexible pay-per-session or discounted recovery packages.',
      badge: 'Best Value',
      icon: LucideIcons.award,
      themeColor: Color(0xFFDB2777),
      gradientColors: [Color(0xFFEC4899), Color(0xFFBE185D)],
      softBgColor: Color(0xFFFDF2F8),
      audience: AdvantageAudience.patient,
      tags: ['Zero Hidden Fees', 'Razorpay Secure'],
      detailedAudit:
          'We believe clinical healthcare should be transparent and honest. Every fee is stated upfront before confirmation with no surprise equipment or travel add-ons. Choose pay-per-session or discounted packages.',
      checklist: [
        'Upfront clear session pricing with zero hidden surcharges',
        'Online video consultations starting at ₹1',
        'Discounted 5 & 10 session recovery packages',
        'Secure 256-bit encrypted payments via UPI/Cards',
      ],
    ),
  ];

  List<_AdvantageItem> get _filteredAdvantages {
    if (_selectedAudienceIndex == 1) {
      return _allAdvantages.where((a) => a.audience == AdvantageAudience.patient).toList();
    } else if (_selectedAudienceIndex == 2) {
      return _allAdvantages.where((a) => a.audience == AdvantageAudience.doctor).toList();
    }
    return _allAdvantages;
  }

  void _showAdvantageDetailModal(BuildContext context, _AdvantageItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FrostedGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          backgroundColor: const Color(0xF7FFFFFF),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: item.themeColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(item.icon, size: 26, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.softBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: item.themeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.headingText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.detailedAudit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.bodyText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Clinical Quality Standards:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headingText,
                  ),
                ),
                const SizedBox(height: 10),
                ...item.checklist.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 16,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.headingText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FluidPressable(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/doctors');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: item.gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: item.themeColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Book With This Guarantee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAdvantages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x330891B2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkles, size: 11, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'The PhysioPrime Advantage',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section Title
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Why Patients & Doctors ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.headingText),
              ),
              TextSpan(
                text: 'Trust Us',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'We bridge the gap between hospital-grade clinical precision and convenient home-based healing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.bodyText),
          ),
        ),
        const SizedBox(height: 16),

        // iOS Perspective Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PerspectiveFilterPill(
                label: 'All Advantages (6)',
                isSelected: _selectedAudienceIndex == 0,
                onTap: () => setState(() => _selectedAudienceIndex = 0),
              ),
              const SizedBox(width: 8),
              _PerspectiveFilterPill(
                label: 'For Patients (4)',
                isSelected: _selectedAudienceIndex == 1,
                onTap: () => setState(() => _selectedAudienceIndex = 1),
              ),
              const SizedBox(width: 8),
              _PerspectiveFilterPill(
                label: 'For Doctors (2)',
                isSelected: _selectedAudienceIndex == 2,
                onTap: () => setState(() => _selectedAudienceIndex = 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid of Cards with fluid animation and compact sizing (no empty spaces)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            final childAspectRatio = (cardWidth / 144).clamp(1.02, 1.45);

            return GridView.builder(
              key: ValueKey('advantages_grid_$_selectedAudienceIndex'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _AdvantageCard(
                  item: item,
                  index: index,
                  onTap: () => _showAdvantageDetailModal(context, item),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PerspectiveFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PerspectiveFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSoft,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.bodyText,
          ),
        ),
      ),
    );
  }
}

class _AdvantageCard extends StatelessWidget {
  final _AdvantageItem item;
  final int index;
  final VoidCallback onTap;

  const _AdvantageCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft, width: 0.85),
          boxShadow: [
            BoxShadow(
              color: item.themeColor.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Super-ellipse gradient icon container
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: item.themeColor.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(item.icon, size: 16, color: Colors.white),
                  ),
                ),
                // Badge pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: item.softBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.themeColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    item.badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: item.themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: AppColors.headingText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.bodyText,
                height: 1.28,
              ),
            ),
            const Spacer(),
            // Bottom micro-guarantee link
            Row(
              children: [
                Text(
                  'Learn more',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: item.themeColor,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  LucideIcons.chevronRight,
                  size: 10,
                  color: item.themeColor,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: (index * 60).ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad);
  }
}

class _CareerTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CareerTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.bodyText)),
      ],
    );
  }
}

class _CareerPillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CareerPillarCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.headingText)),
                Text(subtitle, maxLines: 1, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}
