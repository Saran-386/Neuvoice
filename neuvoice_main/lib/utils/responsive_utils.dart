import 'package:flutter/material.dart';
import 'constants.dart';

class ResponsiveUtils {
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.maxPhoneWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.maxPhoneWidth &&
      MediaQuery.of(context).size.width < AppConstants.maxTabletWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.maxTabletWidth;

  static double getButtonSize(BuildContext context) =>
      isPhone(context) ? 80.0 : 100.0;

  static double getIconSize(BuildContext context) =>
      isPhone(context) ? 32.0 : 40.0;

  static double getPadding(BuildContext context) =>
      isPhone(context) ? 16.0 : 24.0;

  static double getFontSize(BuildContext context, {double base = 14.0}) =>
      isPhone(context) ? base : base + 2.0;

  static EdgeInsets getScreenPadding(BuildContext context) =>
      EdgeInsets.all(getPadding(context));

  static double getMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.6; // 60% on desktop
    }
    return screenWidth; // Full width on mobile/tablet
  }
}
