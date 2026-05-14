// lib/utils/diminishing_credits.dart
import 'dart:math';

class EcoCalculator {
  static double calculate(double weight, int userDropCount) {
    const double baseCreditsPerKg = 10.0;
    const double decayFactor = 0.9;
    return baseCreditsPerKg * weight * pow(decayFactor, userDropCount.toDouble());
  }
}