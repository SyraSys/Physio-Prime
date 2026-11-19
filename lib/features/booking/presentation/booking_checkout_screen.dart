import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../payment/domain/payment_result.dart';
import '../data/location_autofill_service.dart';
import '../domain/booking_request_model.dart';
import '../domain/booking_validators.dart';
import '../providers/booking_provider.dart';
import 'widgets/slot_picker_widgets.dart';

/// Step 2 of booking: patient details, address (GPS auto-fill), payment mode,
/// then appointment creation and (for prepay) Razorpay + backend verification.
class BookingCheckoutScreen extends ConsumerStatefulWidget {
  final BookingSelection selection;

  const BookingCheckoutScreen({super.key, required this.selection});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _symptom = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();

  PatientRelation _relation = PatientRelation.self;
  PatientGender? _gender;
  PaymentMode _paymentMode = PaymentMode.prepay;
  bool _locating = false;
  bool _showGenderError = false;
  bool _navigatedToSuccess = false;

  bool get _isHomeVisit => widget.selection.mode == ConsultationMode.home;

  @override
  void initState() {
    super.initState();
    _prefillFromAccount();
    final city = ref.read(selectedCityProvider);
    final area = ref.read(selectedAreaProvider);
    if (city.isNotEmpty) _city.text = city;
    if (area != null && area.isNotEmpty) _area.text = area;
  }

  void _prefillFromAccount() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    if (_relation == PatientRelation.self && (user.fullName?.isNotEmpty ?? false) && _name.text.isEmpty) {
      _name.text = user.fullName!;
    }
    if ((user.phone?.isNotEmpty ?? false) && _phone.text.isEmpty) _phone.text = user.phone!;
    if (user.email.isNotEmpty && _email.text.isEmpty) _email.text = user.email;
  }

  void _setRelation(PatientRelation relation) {
    if (relation == _relation) return;
    final accountName = ref.read(authStateProvider).user?.fullName;
    setState(() {
      _relation = relation;
      if (relation == PatientRelation.family) {
        // Patient details belong to the family member; contact stays with the account holder.
        if (accountName != null && _name.text.trim() == accountName.trim()) _name.clear();
        _age.clear();
        _weight.clear();
        _height.clear();
        _gender = null;
      } else {
        _prefillFromAccount();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _age, _weight, _height, _symptom, _address, _city, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _required(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _validateName(String? v) {
    final r = _required(v, 'Name');
    if (r != null) return r;
    return BookingValidators.isValidName(v!) ? null : 'Enter a valid name (letters only)';
  }

  String? _validatePhone(String? v) {
    final r = _required(v, 'Phone number');
    if (r != null) return r;
    return BookingValidators.normalizeIndianPhone(v!) == null ? 'Enter a valid 10-digit Indian mobile number' : null;
  }

  String? _validateEmail(String? v) {
    final r = _required(v, 'Email');
    if (r != null) return r;
    return BookingValidators.isValidEmail(v!) ? null : 'Enter a valid email address';
  }

  String? Function(String?) _numberValidator(String label, num min, num max, {bool integer = false}) {
    return (v) {
      final r = _required(v, label);
      if (r != null) return r;
      final parsed = integer ? int.tryParse(v!.trim()) : num.tryParse(v!.trim());
      if (parsed == null) return 'Enter a valid number';
      if (parsed < min || parsed > max) return '$label must be $min–$max';
      return null;
    };
  }

  String? _validateSymptom(String? v) {
    final r = _required(v, 'Health concern');
    if (r != null) return r;
    if (v!.trim().length < 5) return 'Please describe the concern in a few words';
    return null;
  }

  String? _validateAddressField(String? v, String label) {
    if (!_isHomeVisit) return null;
    return _required(v, label);
  }

  // ---------------------------------------------------------------------------
  // GPS auto-fill
  // ---------------------------------------------------------------------------

  Future<void> _autofillFromGps() async {
    if (_locating) return;
    setState(() => _locating = true);
    final service = ref.read(locationAutofillServiceProvider);
    try {
      final address = await service.resolveCurrentAddress();
      if (!mounted) return;
      setState(() {
        if (address.street != null) {
          _address.text = [address.street, address.postalCode].whereType<String>().join(', ');
        }
        if (address.city != null) _city.text = address.city!;
        if (address.area != null) _area.text = address.area!;
      });
      showAppSnack(context, 'Address filled from your location. Please add your flat / house number.');
    } on LocationAutofillException catch (e) {
      if (!mounted) return;
      if (e.canOpenSettings) {
        final open = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Location access needed'),
            content: Text(e.message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Open Settings')),
            ],
          ),
        );
        if (open == true) await service.openSettings(e.reason);
      } else {
        showAppSnack(context, e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  BookingRequest? _buildRequest() {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showGenderError = _gender == null);
    if (!formValid || _gender == null) {
      showAppSnack(context, 'Please fix the highlighted fields.', error: true);
      return null;
    }

    final text = _address.text.trim();
    final city = _city.text.trim();
    final area = _area.text.trim();
    final hasAddress = text.isNotEmpty || city.isNotEmpty || area.isNotEmpty;

    return BookingRequest(
      doctorSlug: widget.selection.doctor.slug,
      categoryId: widget.selection.doctor.categoryId,
      mode: widget.selection.mode,
      date: widget.selection.date,
      slot: widget.selection.slot,
      symptom: _symptom.text.trim(),
      patientName: _name.text.trim(),
      patientPhone: BookingValidators.normalizeIndianPhone(_phone.text)!,
      patientEmail: _email.text.trim().toLowerCase(),
      patientGender: _gender!,
      patientAge: int.parse(_age.text.trim()),
      patientWeight: num.parse(_weight.text.trim()),
      patientHeight: num.parse(_height.text.trim()),
      patientRelation: _relation,
      address: (_isHomeVisit || hasAddress) ? BookingAddress(text: text, city: city, area: area) : null,
      paymentMode: _paymentMode,
    );
  }

  Future<void> _onPrimaryPressed() async {
    final flow = ref.read(bookingFlowProvider);
    final controller = ref.read(bookingFlowProvider.notifier);
    if (flow.isBusy) return;
    FocusScope.of(context).unfocus();

    if (flow.phase == BookingPhase.verificationFailed) {
      await controller.retryVerification();
      return;
    }
    if (flow.appointmentCreated) {
      await controller.retryPayment();
      return;
    }
    if (flow.phase == BookingPhase.failed) controller.resetAfterFailure();

    final request = _buildRequest();
    if (request == null) return;
    await controller.submit(widget.selection, request);
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave checkout?'),
        content: const Text(
          'Your appointment has been created but payment is not complete. '
          'You can find it under My Appointments.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Leave')),
        ],
      ),
    );
    return result ?? false;
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
    final selection = widget.selection;
    final knownFeePaise = flow.created?.appointment.feePaise ?? selection.doctor.feePaise;
    final locked = flow.appointmentCreated || flow.isBusy;
    final interceptBack = flow.isBusy || (flow.appointmentCreated && flow.phase != BookingPhase.completed);

    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || flow.isBusy) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) context.go('/appointments');
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: FrostedGlassAppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: flow.isBusy ? null : () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Checkout'),
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + kToolbarHeight + 12, 16, 150),
                children: [
                  _SummaryCard(selection: selection, feePaise: knownFeePaise),
                  if (flow.appointmentCreated || flow.phase == BookingPhase.failed) ...[
                    const SizedBox(height: 14),
                    _FlowStatusPanel(flow: flow),
                  ],
                  const SizedBox(height: 18),
                  AbsorbPointer(
                    absorbing: locked,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: flow.appointmentCreated ? 0.55 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPatientSection(),
                          const SizedBox(height: 16),
                          _buildConcernSection(),
                          const SizedBox(height: 16),
                          _buildAddressSection(),
                          const SizedBox(height: 16),
                          _buildPaymentSection(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SecureNote(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CheckoutBottomBar(
                flow: flow,
                paymentMode: flow.request?.paymentMode ?? _paymentMode,
                feePaise: flow.created?.razorpayOrder?.amount ?? knownFeePaise,
                onPressed: _onPrimaryPressed,
              ),
            ),
            if (flow.isBusy) _BusyOverlay(phase: flow.phase),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildPatientSection() {
    return InfoCard(
      title: 'Patient details',
      icon: LucideIcons.user,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SegmentedToggle<PatientRelation>(
            values: PatientRelation.values,
            selected: _relation,
            labelOf: (r) => r.label,
            iconOf: (r) => r == PatientRelation.self ? LucideIcons.user : LucideIcons.users,
            onChanged: _setRelation,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _name,
            label: _relation == PatientRelation.self ? 'Full name' : "Family member's full name",
            icon: LucideIcons.user,
            textCapitalization: TextCapitalization.words,
            validator: _validateName,
            autofillHints: _relation == PatientRelation.self ? const [AutofillHints.name] : null,
          ),
          _Field(
            controller: _phone,
            label: _relation == PatientRelation.self ? 'Mobile number' : 'Contact mobile number',
            hint: '10-digit mobile number',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              LengthLimitingTextInputFormatter(16),
            ],
            validator: _validatePhone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          _Field(
            controller: _email,
            label: 'Email',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gender',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final g in PatientGender.values)
                ChoiceChip(
                  label: Text(g.label),
                  selected: _gender == g,
                  onSelected: (_) => setState(() {
                    _gender = g;
                    _showGenderError = false;
                  }),
                  selectedColor: AppColors.surfaceSoft,
                  side: BorderSide(color: _gender == g ? AppColors.primary : AppColors.borderSoft),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _gender == g ? AppColors.primary : AppColors.headingText,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          if (_showGenderError)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text('Please select a gender', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  controller: _age,
                  label: 'Age',
                  suffix: 'yrs',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  validator: _numberValidator('Age', 1, 120, integer: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: _weight,
                  label: 'Weight',
                  suffix: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?'))],
                  validator: _numberValidator('Weight', 2, 300),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: _height,
                  label: 'Height',
                  suffix: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?'))],
                  validator: _numberValidator('Height', 40, 250),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConcernSection() {
    return InfoCard(
      title: 'Symptoms / health concern',
      icon: LucideIcons.activity,
      child: _Field(
        controller: _symptom,
        label: 'Describe the problem',
        hint: 'e.g. Lower back pain radiating down the left leg for 2 weeks',
        maxLines: 4,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        validator: _validateSymptom,
      ),
    );
  }

  Widget _buildAddressSection() {
    return InfoCard(
      title: _isHomeVisit ? 'Home visit address' : 'Your address (optional)',
      icon: LucideIcons.mapPin,
      trailing: TextButton.icon(
        onPressed: _locating ? null : _autofillFromGps,
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, visualDensity: VisualDensity.compact),
        icon: _locating
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.locate, size: 15),
        label: Text(
          _locating ? 'Locating…' : 'Use GPS',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
      ),
      child: Column(
        children: [
          if (!_isHomeVisit)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InfoBanner(
                icon: LucideIcons.video,
                message: 'This is a video consultation — the address is only used for your records.',
              ),
            ),
          _Field(
            controller: _address,
            label: 'House / flat, building, street',
            icon: LucideIcons.home,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
            validator: (v) => _validateAddressField(v, 'Address'),
            autofillHints: const [AutofillHints.fullStreetAddress],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  controller: _area,
                  label: 'Area / locality',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _validateAddressField(v, 'Area'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: _city,
                  label: 'City',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _validateAddressField(v, 'City'),
                  autofillHints: const [AutofillHints.addressCity],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return InfoCard(
      title: 'Payment',
      icon: LucideIcons.wallet,
      child: Column(
        children: [
          for (final mode in PaymentMode.values) ...[
            _PaymentOption(
              mode: mode,
              selected: _paymentMode == mode,
              onTap: () => setState(() => _paymentMode = mode),
            ),
            if (mode != PaymentMode.values.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Private widgets
// -----------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final BookingSelection selection;
  final int? feePaise;
  const _SummaryCard({required this.selection, required this.feePaise});

  @override
  Widget build(BuildContext context) {
    final date = IstTime.parseDate(selection.date);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorAvatar(name: selection.doctor.name, photoUrl: selection.doctor.photo, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selection.doctor.name,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.headingText),
                    ),
                    if (selection.doctor.title != null)
                      Text(selection.doctor.title!, style: const TextStyle(fontSize: 12, color: AppColors.bodyText)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderSoft),
          _SummaryLine(icon: LucideIcons.calendar, text: date == null ? selection.date : IstTime.longDate(date)),
          _SummaryLine(icon: LucideIcons.clock, text: '${selection.slot} (IST)'),
          _SummaryLine(
            icon: selection.mode == ConsultationMode.home ? LucideIcons.home : LucideIcons.video,
            text: selection.mode.label,
          ),
          const Divider(height: 24, color: AppColors.borderSoft),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Consultation fee',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.bodyText),
                ),
              ),
              Text(
                feePaise == null ? 'Confirmed on booking' : Money.fromPaise(feePaise!),
                style: TextStyle(
                  fontSize: feePaise == null ? 12.5 : 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingText),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(fontSize: 14, color: AppColors.headingText, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
          prefixIcon: icon == null ? null : Icon(icon, size: 17, color: AppColors.bodyText),
          suffixText: suffix,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FBFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _SegmentedToggle<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final IconData Function(T) iconOf;
  final ValueChanged<T> onChanged;

  const _SegmentedToggle({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.iconOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == selected,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: v == selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: v == selected
                          ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconOf(v), size: 15, color: v == selected ? AppColors.primary : AppColors.bodyText),
                        const SizedBox(width: 6),
                        Text(
                          labelOf(v),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: v == selected ? AppColors.headingText : AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: FluidPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.borderSoft, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(
                mode == PaymentMode.prepay ? LucideIcons.creditCard : LucideIcons.wallet,
                color: selected ? AppColors.primary : AppColors.bodyText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 2),
                    Text(mode.description, style: const TextStyle(fontSize: 11.5, color: AppColors.bodyText)),
                  ],
                ),
              ),
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.checkCircle,
                color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowStatusPanel extends StatelessWidget {
  final BookingFlowState flow;
  const _FlowStatusPanel({required this.flow});

  @override
  Widget build(BuildContext context) {
    final appointmentId = flow.created?.appointment.id;
    switch (flow.phase) {
      case BookingPhase.failed:
        return InfoBanner(
          icon: LucideIcons.alertCircle,
          color: AppColors.error,
          message: '${flow.error?.message ?? 'Booking failed.'} No appointment was created — you can try again.',
        );
      case BookingPhase.paymentIncomplete:
        final cancelled = flow.lastPayment?.outcome == PaymentOutcome.cancelled;
        return InfoBanner(
          icon: cancelled ? LucideIcons.info : LucideIcons.alertTriangle,
          color: cancelled ? AppColors.primary : const Color(0xFFD97706),
          message:
              '${flow.error?.message ?? 'Payment not completed.'}\n'
              'Appointment $appointmentId is saved with payment pending. Retry payment below, or find it in My Appointments.',
        );
      case BookingPhase.verificationFailed:
        return InfoBanner(
          icon: LucideIcons.alertTriangle,
          color: const Color(0xFFD97706),
          message:
              '${flow.error?.message ?? 'Payment verification failed.'}\n'
              'Appointment $appointmentId — tap "Retry verification" to check again. Do not pay twice.',
        );
      case BookingPhase.idle:
      case BookingPhase.creating:
      case BookingPhase.awaitingPayment:
      case BookingPhase.verifying:
      case BookingPhase.completed:
        return InfoBanner(
          icon: LucideIcons.checkCircle,
          message: 'Appointment $appointmentId created. Patient details are locked for this booking.',
        );
    }
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final BookingFlowState flow;
  final PaymentMode paymentMode;
  final int? feePaise;
  final VoidCallback onPressed;

  const _CheckoutBottomBar({
    required this.flow,
    required this.paymentMode,
    required this.feePaise,
    required this.onPressed,
  });

  String get _label {
    switch (flow.phase) {
      case BookingPhase.creating:
        return 'Creating booking…';
      case BookingPhase.awaitingPayment:
        return 'Waiting for payment…';
      case BookingPhase.verifying:
        return 'Verifying payment…';
      case BookingPhase.paymentIncomplete:
        return flow.created?.razorpayOrder != null ? 'Retry payment' : 'Payment unavailable';
      case BookingPhase.verificationFailed:
        return 'Retry verification';
      case BookingPhase.completed:
        return 'Booking confirmed';
      case BookingPhase.idle:
      case BookingPhase.failed:
        if (paymentMode == PaymentMode.postpay) return 'Confirm booking';
        return feePaise == null ? 'Proceed to pay' : 'Pay ${Money.fromPaise(feePaise!)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled =
        flow.isBusy ||
        flow.phase == BookingPhase.completed ||
        (flow.phase == BookingPhase.paymentIncomplete && flow.created?.razorpayOrder == null);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Color(0xE6FFFFFF),
            border: Border(top: BorderSide(color: Color(0x14000000), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'By confirming, you agree to our ',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/terms'),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' & ',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/privacy'),
                        child: const Text(
                          'Cancellation Policy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PrimaryActionButton(
                  label: _label,
                  icon: paymentMode == PaymentMode.prepay ? LucideIcons.lock : LucideIcons.calendarCheck,
                  loading: flow.isBusy,
                  onPressed: disabled ? null : onPressed,
                ),
                if (flow.phase == BookingPhase.paymentIncomplete || flow.phase == BookingPhase.verificationFailed)
                  TextButton(
                    onPressed: () => context.go('/appointments'),
                    child: const Text(
                      'Go to My Appointments',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  final BookingPhase phase;
  const _BusyOverlay({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (phase) {
      BookingPhase.creating => ('Reserving your slot', 'Creating your appointment…'),
      BookingPhase.awaitingPayment => ('Complete your payment', 'Finish the payment in the Razorpay window.'),
      BookingPhase.verifying => (
        'Confirming payment',
        'Verifying your payment securely with PhysioPrime. Please don’t close the app.',
      ),
      _ => ('Please wait', ''),
    };
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: const Color(0x660F172A),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingText),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.accentTeal),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Payments are processed securely by Razorpay and confirmed by PhysioPrime.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.bodyText),
          ),
        ),
      ],
    );
  }
}
