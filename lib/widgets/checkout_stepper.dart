import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class CheckoutStepper extends StatelessWidget {
  final int activeStep; // 0: Cart, 1: Checkout, 2: Payment

  const CheckoutStepper({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color activeColor = const Color(0xFF2E7D32);
    final Color inactiveColor = Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStepNode(
            index: 0,
            icon: CupertinoIcons.cart_fill,
            label: l10n.stepCart,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildConnectorLine(0, activeColor, inactiveColor),
          _buildStepNode(
            index: 1,
            icon: CupertinoIcons.location_solid,
            label: l10n.stepCheckout,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildConnectorLine(1, activeColor, inactiveColor),
          _buildStepNode(
            index: 2,
            icon: CupertinoIcons.lock_shield_fill,
            label: l10n.stepPayment,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isCompleted = index < activeStep;
    final bool isActive = index == activeStep;

    Color circleBg;
    Color iconColor;
    Border? border;

    if (isCompleted) {
      circleBg = activeColor;
      iconColor = Colors.white;
    } else if (isActive) {
      circleBg = Colors.white;
      iconColor = activeColor;
      border = Border.all(color: activeColor, width: 2.0);
    } else {
      circleBg = Colors.grey.shade50;
      iconColor = Colors.grey.shade400;
      border = Border.all(color: Colors.grey.shade200, width: 1.2);
    }

    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: border,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      color: Colors.white,
                      size: 14,
                      fontWeight: FontWeight.bold,
                    )
                  : Icon(icon, color: iconColor, size: index == 2 ? 14 : 12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive || isCompleted
                  ? FontWeight.w900
                  : FontWeight.w600,
              color: isActive
                  ? activeColor
                  : (isCompleted ? Colors.black87 : Colors.grey.shade500),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectorLine(
    int fromIndex,
    Color activeColor,
    Color inactiveColor,
  ) {
    final bool isPassed = fromIndex < activeStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14), // offset the label height
        child: Container(
          height: 2.0,
          decoration: BoxDecoration(
            color: isPassed ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
