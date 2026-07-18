import 'package:budget/struct/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Controls Android FLAG_SECURE: when enabled the app cannot be screenshotted
// or screen-recorded, and its thumbnail in the recents/app-switcher screen is
// blanked. This closes the gap where privacy obfuscation (hide balances) can
// be bypassed simply by screenshotting or viewing the app switcher.
const MethodChannel _secureScreenChannel =
    MethodChannel("com.budget.tracker_app/secure_screen");

Future<void> setSecureScreen(bool enabled) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _secureScreenChannel
        .invokeMethod("setSecureScreen", {"enabled": enabled});
  } catch (e) {
    print("Error setting secure screen: $e");
  }
}

Future<void> applySecureScreenSetting() async {
  await setSecureScreen(appStateSettings["secureScreen"] == true);
}
