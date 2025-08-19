import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformService {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => !kIsWeb && !isMobile;

  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Desktop';
  }
}
