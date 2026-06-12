import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class TwoFactorService {
  static const _storage = FlutterSecureStorage();
  static const _key = '2fa_enabled';
  static final _auth = LocalAuthentication();

  // ── Read / Write preference ──────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final value = await _storage.read(key: _key);
    return value == 'true';
  }

  static Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _key, value: enabled ? 'true' : 'false');
  }

  // ── Check if device supports biometrics ─────────────────────────────────

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  // ── Prompt the biometric dialog ──────────────────────────────────────────
  // Returns true = passed, false = failed/cancelled

  static Future<bool> authenticate({String reason = 'Verify your identity to continue'}) async {
    try {
      final available = await isAvailable();
      if (!available) return true; // graceful fallback — don't block if unsupported

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allows PIN fallback if biometrics fail
          stickyAuth: true,     // keeps dialog open if user switches apps
        ),
      );
    } catch (_) {
      return false;
    }
  }
}