import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../../doctors/data/doctors_repository.dart';
import '../../doctors/domain/doctor_model.dart';
import '../../home/domain/symptom_model.dart';
import '../../home/providers/home_provider.dart';
import '../data/location_autofill_service.dart';
import '../domain/booking_request_model.dart';
import '../domain/booking_validators.dart';
import '../domain/slot_model.dart';
import '../providers/booking_provider.dart';
import 'widgets/booking_stepper.dart';
import 'widgets/symptom_card.dart';

/// 4-Step End-to-End Booking Wizard:
/// Designed in strict compliance with `DESIGN.md`:
/// - Minimalist clinical aesthetics, high-clarity Plus Jakarta Sans & Inter typography.
/// - Calming white and soft mint surfaces (`#F8FAFB`, `#FFFFFF`, `#EBF8FA`).
/// - Step 1: Condition / Symptom Selection
/// - Step 2: Consultation Mode & Doctor Selection
/// - Step 3: Date & Time Window Slot Picker
/// - Step 4: Booking Summary, Patient Details, Medical Notes & Payment
/// - Responsive mobile-first container clamped to 580px max width for desktop/web.
class BookingWizardScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final SymptomModel? initialCondition;
  final String? initialConditionName;
  final DoctorModel? initialDoctor;
  final BookingDoctorInfo? initialDoctorInfo;
  final ConsultationMode initialMode;

  const BookingWizardScreen({
    super.key,
    this.initialStep = 1,
    this.initialCondition,
    this.initialConditionName,
    this.initialDoctor,
    this.initialDoctorInfo,
    this.initialMode = ConsultationMode.home,
  });

  @override
  ConsumerState<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  late int _currentStep;

  // Step 1: Condition state
  final TextEditingController _conditionSearchController = TextEditingController();
  String _selectedCategoryTab = 'All';
  SymptomModel? _selectedCondition;

  // Step 2: Mode & Doctor state
  late ConsultationMode _selectedMode;
  DoctorModel? _selectedDoctor;
  BookingDoctorInfo? _selectedDoctorInfo;
  final Map<String, DoctorCategoryOption> _doctorSelectedSpecialties = {};

  DoctorCategoryOption? _getDoctorSpecialty(DoctorModel doc) {
    if (_doctorSelectedSpecialties.containsKey(doc.slug)) {
      return _doctorSelectedSpecialties[doc.slug];
    }
    if (doc.categoryOptions.isEmpty) return null;

    if (_selectedCondition != null) {
      final condPopular = _selectedCondition!.popularFor.map((p) => p.toLowerCase()).toList();
      for (final opt in doc.categoryOptions) {
        if (condPopular.any((p) => p.contains(opt.slug) || opt.title.toLowerCase().contains(p))) {
          _doctorSelectedSpecialties[doc.slug] = opt;
          return opt;
        }
      }
    }
    _doctorSelectedSpecialties[doc.slug] = doc.categoryOptions.first;
    return doc.categoryOptions.first;
  }

  // Step 3: Schedule state
  late final List<DateTime> _upcomingDays = IstTime.upcomingDays(14);
  late DateTime _selectedDate = _upcomingDays.first;
  SlotModel? _selectedSlotModel;
  String? _selectedSlotString;

  // Step 4: Patient Details & Payment state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _numPatientsController = TextEditingController(text: '1');
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();

  PatientRelation _relation = PatientRelation.self;
  PatientGender? _gender;
  PaymentMode _paymentMode = PaymentMode.prepay;
  bool _termsAgreed = false;
  bool _showGenderError = false;
  bool _showTermsError = false;
  bool _locatingGps = false;
  bool _navigatedToSuccess = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 4);
    _selectedCondition = widget.initialCondition;
    _selectedMode = widget.initialMode;
    _selectedDoctor = widget.initialDoctor;
    _selectedDoctorInfo = widget.initialDoctorInfo;

    if (_selectedDoctor != null && _selectedDoctorInfo == null) {
      _selectedDoctorInfo = _doctorToInfo(_selectedDoctor!);
    }

    if (_selectedCondition == null && widget.initialConditionName != null) {
      _findInitialConditionByName(widget.initialConditionName!);
    }

    _prefillAccountData();
  }

  void _findInitialConditionByName(String name) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = ref.read(symptomsProvider).value;
      if (list != null && list.isNotEmpty) {
        final match = list.where((s) =>
            s.title.toLowerCase() == name.toLowerCase() ||
            s.slug.toLowerCase() == name.toLowerCase()).firstOrNull;
        if (match != null && mounted) {
          setState(() => _selectedCondition = match);
        }
      }
    });
  }

  void _prefillAccountData() {
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      if (_relation == PatientRelation.self && (user.fullName?.isNotEmpty ?? false)) {
        _nameController.text = user.fullName!;
      }
      if (user.email.isNotEmpty) _emailController.text = user.email;
      if (user.phone?.isNotEmpty ?? false) _phoneController.text = user.phone!;
    }

    final city = ref.read(selectedCityProvider);
    final area = ref.read(selectedAreaProvider);
    if (city.isNotEmpty && _cityController.text.isEmpty) _cityController.text = city;
    if (area != null && area.isNotEmpty && _areaController.text.isEmpty) _areaController.text = area;
  }

  BookingDoctorInfo _doctorToInfo(DoctorModel doc) {
    final opt = _getDoctorSpecialty(doc);
    final fee = opt != null
        ? (_selectedMode == ConsultationMode.home ? opt.feeHome : opt.feeOnline)
        : (_selectedMode == ConsultationMode.home ? doc.fees.home : doc.fees.online);

    return BookingDoctorInfo(
      slug: doc.slug,
      name: doc.name,
      title: opt?.title ?? (doc.specialty.isNotEmpty ? doc.specialty : doc.title),
      photo: doc.photo,
      categoryId: opt?.categoryId ?? (doc.categoryOptions.isNotEmpty ? doc.categoryOptions.first.categoryId : null),
      categoryTitle: opt?.title,
      homeVisitsEnabled: doc.homeVisitsEnabled,
      feePaise: (fee * 100).toInt(),
      conditionName: _selectedCondition?.title,
      symptomSlug: _selectedCondition?.slug,
    );
  }

  @override
  void dispose() {
    _conditionSearchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _numPatientsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStepBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep -= 1);
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/bookings');
      }
    }
  }

  void _onSelectCondition(SymptomModel condition) {
    setState(() {
      _selectedCondition = condition;
      _currentStep = 2;
    });
  }

  void _onSelectDoctor(DoctorModel doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedDoctorInfo = _doctorToInfo(doctor);
      _selectedSlotModel = null;
      _selectedSlotString = null;
      _currentStep = 3;
    });
  }

  void _onSelectSlot(SlotModel slot) {
    setState(() {
      _selectedSlotModel = slot;
      _selectedSlotString = slot.slot;
      _currentStep = 4;
    });
  }

  void _setRelation(PatientRelation relation) {
    if (relation == _relation) return;
    final accountName = ref.read(authStateProvider).user?.fullName;
    setState(() {
      _relation = relation;
      if (relation == PatientRelation.family) {
        if (accountName != null && _nameController.text.trim() == accountName.trim()) {
          _nameController.clear();
        }
        _ageController.clear();
        _weightController.clear();
        _heightController.clear();
        _gender = null;
      } else {
        _prefillAccountData();
      }
    });
  }

  Future<void> _autofillFromGps() async {
    if (_locatingGps) return;
    setState(() => _locatingGps = true);
    final service = ref.read(locationAutofillServiceProvider);
    try {
      final address = await service.resolveCurrentAddress();
      if (!mounted) return;
      setState(() {
        if (address.street != null) {
          _addressController.text = [address.street, address.postalCode].whereType<String>().join(', ');
        }
        if (address.city != null) _cityController.text = address.city!;
        if (address.area != null) _areaController.text = address.area!;
      });
      showAppSnack(context, 'Location detected and filled.');
    } catch (e) {
      if (mounted) showAppSnack(context, 'Could not detect location: $e', error: true);
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  BookingRequest? _buildRequest() {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _showGenderError = _gender == null;
      _showTermsError = !_termsAgreed;
    });

    if (!formValid || _gender == null || !_termsAgreed) {
      showAppSnack(context, 'Please complete all required fields and accept terms.', error: true);
      return null;
    }

    final doctor = _selectedDoctorInfo ?? (_selectedDoctor != null ? _doctorToInfo(_selectedDoctor!) : null);
    if (doctor == null) {
      showAppSnack(context, 'Doctor information is missing. Please reselect a doctor.', error: true);
      return null;
    }

    final isHome = _selectedMode == ConsultationMode.home;
    final text = _addressController.text.trim();
    final city = _cityController.text.trim();
    final area = _areaController.text.trim();

    return BookingRequest(
      doctorSlug: doctor.slug,
      categoryId: doctor.categoryId,
      mode: _selectedMode,
      date: IstTime.apiDate(_selectedDate),
      slot: _selectedSlotString ?? _selectedSlotModel?.slot ?? 'Morning',
      symptom: _notesController.text.trim().isNotEmpty
          ? '${_selectedCondition?.title ?? "General Consultation"}: ${_notesController.text.trim()}'
          : (_selectedCondition?.title ?? 'Physiotherapy Consultation'),
      patientName: _nameController.text.trim(),
      patientPhone: BookingValidators.normalizeIndianPhone(_phoneController.text) ?? _phoneController.text.trim(),
      patientEmail: _emailController.text.trim().toLowerCase(),
      patientGender: _gender!,
      patientAge: int.tryParse(_ageController.text.trim()) ?? 30,
      patientWeight: num.tryParse(_weightController.text.trim()),
      patientHeight: num.tryParse(_heightController.text.trim()),
      patientRelation: _relation,
      address: isHome || text.isNotEmpty ? BookingAddress(text: text, city: city, area: area) : null,
      paymentMode: _paymentMode,
      numberOfPatients: (int.tryParse(_numPatientsController.text.trim()) ?? 1).clamp(1, 15),
      specialRequirements: _notesController.text.trim(),
    );
  }

  Future<void> _submitBooking() async {
    final flow = ref.read(bookingFlowProvider);
    final controller = ref.read(bookingFlowProvider.notifier);
    if (flow.isBusy) return;

    final doctor = _selectedDoctorInfo ?? (_selectedDoctor != null ? _doctorToInfo(_selectedDoctor!) : null);
    if (doctor == null) return;

    final request = _buildRequest();
    if (request == null) return;

    final selection = BookingSelection(
      doctor: doctor,
      mode: _selectedMode,
      date: IstTime.apiDate(_selectedDate),
      slot: _selectedSlotString ?? _selectedSlotModel?.slot ?? 'Morning',
      conditionName: _selectedCondition?.title ?? 'Physiotherapy',
      slotDisplayTime: _selectedSlotModel?.timeRange,
    );

    await controller.submit(selection, request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BookingFlowState>(bookingFlowProvider, (previous, next) {
      if (next.phase == BookingPhase.completed && next.confirmation != null && !_navigatedToSuccess) {
        _navigatedToSuccess = true;
        context.go('/booking-success', extra: next.confirmation);
      } else if (next.phase == BookingPhase.failed && previous?.phase != BookingPhase.failed) {
        showAppSnack(context, next.error?.message ?? 'Booking failed. Please try again.', error: true);
      }
    });

    final flow = ref.watch(bookingFlowProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Circular Back Button
                      FluidPressable(
                        onTap: _onStepBack,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080F172A),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.arrowLeft, size: 17, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStepHeaderTitle(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      if (_currentStep == 1)
                        FluidPressable(
                          onTap: () => context.go('/appointments'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF0891B2)),
                                const SizedBox(width: 4),
                                Text(
                                  'My Bookings',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0891B2),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  // Minimalist 4-step Stepper
                  BookingStepper(
                    currentStep: _currentStep,
                    onStepTapped: (step) {
                      if (step < _currentStep) {
                        setState(() => _currentStep = step);
                      }
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildCurrentStepContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (flow.isBusy)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  String _getStepHeaderTitle() {
    switch (_currentStep) {
      case 1:
        return 'Choose Condition';
      case 2:
        return 'Select Doctor & Mode';
      case 3:
        return 'Pick Date & Time';
      case 4:
        return 'Confirm Details';
      default:
        return 'Book Consultation';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Condition();
      case 2:
        return _buildStep2Doctor();
      case 3:
        return _buildStep3Schedule();
      case 4:
        return _buildStep4Confirm();
      default:
        return _buildStep1Condition();
    }
  }

  // ===========================================================================
  // STEP 1: CHOOSE CONDITION (MINIMALIST & POLISHED)
  // ===========================================================================
  Widget _buildStep1Condition() {
    final symptomsAsync = ref.watch(symptomsProvider);

    return symptomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 32, color: AppColors.error),
            const SizedBox(height: 10),
            Text('Could not load conditions catalogue', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ref.invalidate(symptomsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (conditions) {
        final query = _conditionSearchController.text.trim().toLowerCase();
        final filtered = conditions.where((item) {
          final matchesQuery = query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.symptomsList.any((s) => s.toLowerCase().contains(query));

          if (!matchesQuery) return false;

          if (_selectedCategoryTab == 'All') return true;
          return item.department?.toLowerCase().contains(_selectedCategoryTab.toLowerCase()) ?? false;
        }).toList();

        final categoryTabs = [
          'All',
          'Musculoskeletal / Orthopedic',
          'Sports Injuries',
          'Neurological Conditions',
          'Pediatric Conditions',
          'Cardio-Respiratory',
          'Women\'s Health',
          'Geriatric Care',
        ];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        children: [
                          const TextSpan(text: 'What brings you in? '),
                          TextSpan(
                            text: 'Choose condition',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0891B2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select from the 8 primary conditions we treat',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stadium Pill Search Bar (DESIGN.md 3.2)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _conditionSearchController,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Search conditions...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_conditionSearchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _conditionSearchController.clear();
                                setState(() {});
                              },
                              child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category horizontal chips
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categoryTabs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final tab = categoryTabs[idx];
                          final isSelected = tab == _selectedCategoryTab;

                          return ChoiceChip(
                            label: Text(tab),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategoryTab = tab);
                            },
                            selectedColor: const Color(0xFF0891B2),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
                              width: 1.2,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No matching conditions found.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return _buildConditionCard(item);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConditionCard(SymptomModel item) {
    return SymptomCard(
      item: item,
      onTap: () => _onSelectCondition(item),
    );
  }

  // ===========================================================================
  // STEP 2: MODE & DOCTOR SELECTION (DESIGN.MD MINIMALISM)
  // ===========================================================================
  Widget _buildStep2Doctor() {
    final doctorsRepo = ref.watch(doctorsRepositoryProvider);
    final conditionName = _selectedCondition?.title ?? 'Condition';

    return FutureBuilder<List<DoctorModel>>(
      future: doctorsRepo.getDoctors(
        symptom: _selectedCondition?.slug,
        mode: _selectedMode.apiValue,
      ),
      builder: (context, snapshot) {
        final doctors = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // SELECTED CONDITION HERO CARD (DESIGN.md 1.1 heroCardBg #EBF8FA)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDEF4F7), width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECTED CONDITION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0891B2),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conditionName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (_selectedCondition?.recoveryEstimate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Typical recovery: ${_selectedCondition!.recoveryEstimate}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CONSULTATION MODE SELECTOR (Matches doctor_detail_screen.dart)
            Text(
              'CONSULTATION MODE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    title: 'Home Visit',
                    subtitle: 'Therapist comes to you',
                    icon: LucideIcons.home,
                    isSelected: _selectedMode == ConsultationMode.home,
                    onTap: () => setState(() => _selectedMode = ConsultationMode.home),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    title: 'Online Video',
                    subtitle: 'HD 1-on-1 virtual session',
                    icon: LucideIcons.video,
                    isSelected: _selectedMode == ConsultationMode.online,
                    onTap: () => setState(() => _selectedMode = ConsultationMode.online),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // THERAPISTS FOR CONDITION
            Text(
              'THERAPISTS FOR ${conditionName.toUpperCase()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (doctors.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.userX, size: 32, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      'No therapists available for this mode right now.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ...doctors.map((doc) => _buildDoctorCard(doc)),
          ],
        );
      },
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const activeTeal = Color(0xFF0891B2);

    return FluidPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeTeal : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x180891B2),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? activeTeal : const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : activeTeal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doc) {
    final selectedOpt = _getDoctorSpecialty(doc);
    final fee = selectedOpt != null
        ? (_selectedMode == ConsultationMode.home ? selectedOpt.feeHome : selectedOpt.feeOnline)
        : (_selectedMode == ConsultationMode.home ? doc.fees.home : doc.fees.online);
    final exp = '${doc.experienceYears} yrs exp';
    final langs = doc.languages.isNotEmpty ? doc.languages.join(', ') : 'Hindi, English';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: doc.photo != null && doc.photo!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doc.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFE0F4F7),
                            child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE0F4F7),
                          child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Doctor Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doc.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        // Amber rating pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFEF3C7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2.5),
                              Text(
                                doc.rating > 0 ? doc.rating.toStringAsFixed(1) : 'New',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedOpt?.title ?? (doc.specialty.isNotEmpty ? doc.specialty : doc.title),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$exp • $langs',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Multi-speciality chips if doctor supports multiple specialties
          if (doc.categoryOptions.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: doc.categoryOptions.map((opt) {
                  final isSelected = selectedOpt?.categoryId == opt.categoryId;
                  final optFee = _selectedMode == ConsultationMode.home ? opt.feeHome : opt.feeOnline;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FluidPressable(
                      onTap: () {
                        setState(() {
                          _doctorSelectedSpecialties[doc.slug] = opt;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Text(
                          '${opt.title} (₹${optFee.toInt()})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Price & Book Now Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${fee.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0891B2),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33009AA6),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _onSelectDoctor(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: SCHEDULE DATE & TIME (DESIGN.MD MINIMALISM)
  // ===========================================================================
  Widget _buildStep3Schedule() {
    final doctor = _selectedDoctorInfo ?? (_selectedDoctor != null ? _doctorToInfo(_selectedDoctor!) : null);
    final docSlug = doctor?.slug ?? '';
    final query = SlotQuery(doctorSlug: docSlug, date: IstTime.apiDate(_selectedDate));
    final slotsAsync = ref.watch(slotAvailabilityProvider(query));

    final conditionTitle = _selectedCondition?.title ?? widget.initialConditionName ?? 'Consultation';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // STEP 3 OF 4 Banner (Matching Reference Design)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _onStepBack,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.arrowLeft, size: 18, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 3 OF 4',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0891B2),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pick Date & Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Doctor Mini Header Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: doctor?.photo != null && doctor!.photo!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doctor.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: const Color(0xFFE0F4F7)),
                        )
                      : Container(color: const Color(0xFFE0F4F7)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor?.name ?? 'Doctor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor?.title ?? 'Physiotherapy Specialist',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedMode == ConsultationMode.home ? LucideIcons.home : LucideIcons.video,
                                size: 11,
                                color: const Color(0xFF0891B2),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedMode.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0891B2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conditionTitle,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0891B2),
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
        const SizedBox(height: 20),

        // SELECT DATE SECTION
        Text(
          'Select Date',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Date Cards (Matches doctor_detail_screen.dart)
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _upcomingDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final day = _upcomingDays[i];
              final isSelected = IstTime.isSameDay(day, _selectedDate);
              final isToday = i == 0;

              return FluidPressable(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    _selectedSlotModel = null;
                    _selectedSlotString = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 62,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0891B2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x330891B2),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        IstTime.weekday(day).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        IstTime.month(day).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white24 : const Color(0xFF0891B2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TODAY',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),

        // SELECT TIME WINDOW SECTION
        Text(
          'Select Time Window',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        slotsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load slots: $e', style: GoogleFonts.inter()),
            ),
          ),
          data: (availability) {
            final windows = availability.windows.isNotEmpty
                ? availability.windows
                : [
                    const SlotModel(
                      slot: '7:00 AM - 9:00 AM',
                      label: 'Early Morning',
                      available: true,
                      maxPatients: 3,
                    ),
                    const SlotModel(
                      slot: '9:00 AM - 12:00 PM',
                      label: 'Morning',
                      available: true,
                      maxPatients: 3,
                    ),
                    const SlotModel(
                      slot: '12:00 PM - 3:00 PM',
                      label: 'Afternoon',
                      available: true,
                      maxPatients: 3,
                    ),
                    const SlotModel(
                      slot: '3:00 PM - 6:00 PM',
                      label: 'Evening',
                      available: true,
                      maxPatients: 3,
                    ),
                    const SlotModel(
                      slot: '6:00 PM - 9:00 PM',
                      label: 'Night',
                      available: true,
                      maxPatients: 3,
                    ),
                  ];

            return Column(
              children: windows.map((slot) {
                final isSelected = _selectedSlotString == slot.slot;
                final icon = _getTimeWindowIcon(slot.label ?? slot.slot);

                return FluidPressable(
                  onTap: slot.available ? () => _onSelectSlot(slot) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x140891B2),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.displayTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slot.timeRange,
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${slot.availableSpots} spots',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _getTimeWindowIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('early')) return LucideIcons.sunrise;
    if (lower.contains('morning')) return LucideIcons.sun;
    if (lower.contains('afternoon')) return LucideIcons.sunMedium;
    if (lower.contains('evening')) return LucideIcons.sunset;
    return LucideIcons.moon;
  }

  // ===========================================================================
  // STEP 4: CONFIRM & PATIENT DETAILS (MATCHING REFERENCE DESIGN EXACTLY)
  // ===========================================================================
  Widget _buildStep4Confirm() {
    final doctor = _selectedDoctorInfo ?? (_selectedDoctor != null ? _doctorToInfo(_selectedDoctor!) : null);
    final conditionName = _selectedCondition?.title ?? widget.initialConditionName ?? 'General Physiotherapy';
    final fee = _selectedMode == ConsultationMode.home
        ? (doctor?.feePaise != null ? doctor!.feePaise! ~/ 100 : 1000)
        : (doctor?.feePaise != null ? doctor!.feePaise! ~/ 100 : 800);

    final isHome = _selectedMode == ConsultationMode.home;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    final formattedTime = _selectedSlotModel?.timeRange ?? _selectedSlotString ?? 'Time Window';

    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // Back Navigation Bar
          InkWell(
            onTap: _onStepBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowLeft, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ===================================================================
          // 1. BOOKING SUMMARY CARD (Matches Reference Image 5)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOOKING SUMMARY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0891B2),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Doctor Info Row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: doctor?.photo != null && doctor!.photo!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: doctor.photo!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(color: const Color(0xFFE0F4F7)),
                              )
                            : Container(color: const Color(0xFFE0F4F7)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor?.name ?? 'Doctor',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor?.title ?? 'Physiotherapy Specialist',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Condition Detail
                Text(
                  'Condition',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 1),
                Text(
                  conditionName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Summary 2x2 Details Grid
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isHome ? LucideIcons.home : LucideIcons.video,
                            size: 14,
                            color: const Color(0xFF0891B2),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedMode.label,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0891B2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.creditCard, size: 14, color: Color(0xFF0891B2)),
                        const SizedBox(width: 5),
                        Text(
                          '₹$fee',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0891B2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===================================================================
          // 2. PATIENT DETAILS CARD (Matches Reference Image 5)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PATIENT DETAILS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0891B2),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Segmented Toggle: For myself / For someone else
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _setRelation(PatientRelation.self),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _relation == PatientRelation.self ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _relation == PatientRelation.self
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'For myself',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: _relation == PatientRelation.self ? FontWeight.w700 : FontWeight.w500,
                                color: _relation == PatientRelation.self ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _setRelation(PatientRelation.family),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _relation == PatientRelation.family ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _relation == PatientRelation.family
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'For someone else',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: _relation == PatientRelation.family ? FontWeight.w700 : FontWeight.w500,
                                color: _relation == PatientRelation.family ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name * & Email * Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hint: 'Full name',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _emailController,
                        label: 'Email *',
                        hint: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !BookingValidators.isValidEmail(v)) ? 'Valid email required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phone Number * & Gender * Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _phoneController,
                        label: 'Phone Number *',
                        hint: 'Enter 10-digit number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        validator: (v) => (v == null || BookingValidators.normalizeIndianPhone(v) == null)
                            ? '10-digit phone'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender *',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showGenderError ? AppColors.error : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<PatientGender>(
                                value: _gender,
                                hint: Text('Select', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                                isExpanded: true,
                                icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                                items: PatientGender.values.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(g.label, style: GoogleFonts.inter(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() {
                                  _gender = val;
                                  _showGenderError = false;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Age * & Number of Guests / Patients (Max 15) Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _ageController,
                        label: 'Age *',
                        hint: 'Enter age (1-100)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                        validator: (v) {
                          final a = int.tryParse(v ?? '');
                          if (a == null || a < 1 || a > 100) return 'Age 1-100';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _numPatientsController,
                        label: 'Number of Guests / Patients (Max 15)',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                        validator: (v) {
                          final count = int.tryParse(v ?? '');
                          if (count == null || count < 1 || count > 15) return 'Max 15';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Optional Weight & Height Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _weightController,
                        label: 'Weight (kg) (optional)',
                        hint: 'Enter weight in kg',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _heightController,
                        label: 'Height (cm) (optional)',
                        hint: 'Enter height in cm',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                // Home Visit Address (if home visit mode)
                if (isHome) ...[
                  const SizedBox(height: 12),
                  _buildFormField(
                    controller: _addressController,
                    label: 'Home Visit Address *',
                    hint: 'Enter home address for the therapist visit',
                    maxLines: 2,
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF94A3B8)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required for home visits' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          controller: _cityController,
                          label: 'City *',
                          hint: 'City',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          controller: _areaController,
                          label: 'Area *',
                          hint: 'Area/Locality',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FluidPressable(
                      onTap: _autofillFromGps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_locatingGps)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF0891B2)),
                              )
                            else
                              const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFF0891B2)),
                            const SizedBox(width: 5),
                            Text(
                              'Auto-detect',
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===================================================================
          // 3. SPECIAL REQUIREMENTS / NOTES CARD (Matches Reference Image 6)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Requirements / Safari Notes (Optional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Describe any medical conditions, group requirements, or notes for your booking',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Tell us about symptoms, special requirements, or group size details...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0891B2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===================================================================
          // 4. PAYMENT CARD (Matches Reference Image 6)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0891B2),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Mode Segmented Selector (Image 6)
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMode = PaymentMode.prepay),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _paymentMode == PaymentMode.prepay ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _paymentMode == PaymentMode.prepay
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pay Now Online',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: _paymentMode == PaymentMode.prepay ? FontWeight.w700 : FontWeight.w500,
                                color: _paymentMode == PaymentMode.prepay ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMode = PaymentMode.postpay),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: _paymentMode == PaymentMode.postpay ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _paymentMode == PaymentMode.postpay
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pay at Visit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: _paymentMode == PaymentMode.postpay ? FontWeight.w700 : FontWeight.w500,
                                color: _paymentMode == PaymentMode.postpay ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Razorpay Security Notice Box (Image 6)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.shieldCheck, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _paymentMode == PaymentMode.prepay
                              ? 'Pay securely with UPI, Cards or Net Banking via Razorpay. You will be taken to the payment window after confirming.'
                              : 'Pay directly to your therapist via Cash or UPI at the time of your consultation.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Total Payable Card (Image 6)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDEF4F7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '₹$fee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===================================================================
          // 5. TERMS & CONDITIONS CHECKBOX (Matches Reference Image 6)
          // ===================================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _termsAgreed,
                  activeColor: const Color(0xFF0891B2),
                  onChanged: (val) => setState(() {
                    _termsAgreed = val ?? false;
                    _showTermsError = false;
                  }),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: _showTermsError ? AppColors.error : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'I have read and agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0891B2),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(
                        text: '. I understand that once I book and pay for a physiotherapy appointment, the payment is non-refundable if I cancel the appointment. *',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Terms & Cancellation Agreement (PDF Page 6 Requirement)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'By confirming, you agree to our ',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                GestureDetector(
                  onTap: () => context.push('/terms'),
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0891B2),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' & ',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                GestureDetector(
                  onTap: () => context.push('/privacy'),
                  child: Text(
                    'Cancellation Policy',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0891B2),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 6. SUBMIT CTA BUTTON (Matches Reference Image 6)
          // ===================================================================
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33009AA6),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _paymentMode == PaymentMode.prepay ? 'Confirm & Pay ₹$fee' : 'Confirm Booking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0891B2)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
