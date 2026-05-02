import 'package:flutter/services.dart';

class HapticUtil {
  /// Subtle feedback for checkboxes, tab switches, and small interactions.
  static void light() {
    HapticFeedback.selectionClick();
  }

  /// Firm feedback for primary button presses.
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Strong feedback for successful events (e.g., OTP verified, account created).
  /// Falls back to vibrate if medium impact isn't prominent enough.
  static void success() {
    HapticFeedback.vibrate();
  }

  /// Distinct feedback for errors or validation failures.
  static void error() {
    HapticFeedback.heavyImpact();
    // Alternatively, call vibrate twice or use a specific pattern if needed
  }
}
