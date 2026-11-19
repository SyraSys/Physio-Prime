import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist 4-Step progress stepper matching PhysioPrime clinical design tokens:
/// 1. CONDITION -> 2. DOCTOR -> 3. SCHEDULE -> 4. CONFIRM
class BookingStepper extends StatelessWidget {
  /// 1-based step index (1, 2, 3, 4).
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  const BookingStepper({
    super.key,
    required this.currentStep,
    this.onStepTapped,
  });

  static const _steps = [
    'CONDITION',
    'DOCTOR',
    'SCHEDULE',
    'CONFIRM',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              for (int i = 0; i < _steps.length; i++) ...[
                _buildStepItem(i + 1, _steps[i]),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 18),
                      decoration: BoxDecoration(
                        color: (i + 1) < currentStep
                            ? const Color(0xFF0891B2)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;

    const activeColor = Color(0xFF0891B2);

    return InkWell(
      onTap: (isCompleted && onStepTapped != null)
          ? () => onStepTapped!(stepIndex)
          : null,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? activeColor
                  : (isCurrent ? activeColor : const Color(0xFFF1F5F9)),
              boxShadow: isCurrent
                  ? const [
                      BoxShadow(
                        color: Color(0x330891B2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$stepIndex',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              color: isCurrent
                  ? activeColor
                  : (isCompleted ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
