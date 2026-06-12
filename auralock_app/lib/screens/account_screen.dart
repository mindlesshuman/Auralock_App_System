import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:auralock_app/services/two_factor_services.dart';
import 'package:auralock_app/widgets/aura_toast.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _is2FAEnabled = false;         // ✅ Default false — read from TwoFactorService
  bool _biometricsAvailable = false;  // ✅ Whether device supports biometrics
  bool _biometricsEnabled = false;    // ✅ User's biometric unlock preference

  String _username = "Administrator";
  String _email = "Admin Access Level";

  final Color maroonAccent = const Color(0xFF9E1A1A);
  final Color safeAccent = const Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _fetchSecuritySettings();
  }

  Future<void> _fetchSecuritySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _username = user.displayName ?? 'AuraAdmin';
      _email = user.email ?? 'Unknown Email';
    }

    // ✅ Load from TwoFactorService instead of raw storage key
    final bool twoFaEnabled = await TwoFactorService.isEnabled();
    final bool biometricsAvailable = await TwoFactorService.isAvailable();

    // Biometric unlock preference (separate from 2FA)
    final String? savedBio = await _storage.read(key: 'pref_bio');

    setState(() {
      _is2FAEnabled = twoFaEnabled;
      _biometricsAvailable = biometricsAvailable;
      _biometricsEnabled = savedBio == 'true';
      _isLoading = false;
    });
  }

  // ✅ Now requires biometric confirmation before toggling 2FA
  Future<void> _toggle2FA(bool newValue) async {
    if (!_biometricsAvailable) {
      AuraToast.show(
        context: context,
        title: 'Unavailable',
        message: 'Biometrics are not supported on this device.',
        icon: Icons.warning_amber_rounded,
        color: maroonAccent,
      );
      return;
    }

    final bool confirmed = await TwoFactorService.authenticate(
      reason: newValue
          ? 'Confirm your identity to enable 2FA'
          : 'Confirm your identity to disable 2FA',
    );

    if (!confirmed) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Verification Failed',
          message: 'Could not verify your identity.',
          icon: Icons.fingerprint,
          color: maroonAccent,
        );
      }
      return;
    }

    await TwoFactorService.setEnabled(newValue);

    if (mounted) {
      setState(() => _is2FAEnabled = newValue);
      AuraToast.show(
        context: context,
        title: newValue ? '2FA Enabled' : '2FA Disabled',
        message: newValue
            ? 'Biometric verification will be required at login.'
            : '2FA has been turned off.',
        icon: newValue
            ? Icons.verified_user_outlined
            : Icons.shield_outlined,
        color: newValue ? safeAccent : maroonAccent,
      );
    }
  }

  Future<void> _toggleBiometrics(bool newValue) async {
  if (newValue) {
    // Require biometric confirmation before enabling
    final bool confirmed = await TwoFactorService.authenticate(
      reason: 'Verify your identity to enable Biometric Unlock',
    );
    if (!confirmed) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Verification Failed',
          message: 'Could not verify your identity.',
          icon: Icons.fingerprint,
          color: maroonAccent,
        );
      }
      return;
    }
  }

  await _storage.write(key: 'pref_bio', value: newValue.toString());
  if (mounted) {
    setState(() => _biometricsEnabled = newValue);
    AuraToast.show(
      context: context,
      title: newValue ? 'Biometric Unlock Enabled' : 'Biometric Unlock Disabled',
      message: newValue
          ? 'You can now unlock with Face ID or Fingerprint.'
          : 'Biometric unlock has been turned off.',
      icon: newValue ? Icons.fingerprint : Icons.fingerprint_outlined,
      color: newValue ? safeAccent : maroonAccent,
    );
  }
}

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: maroonAccent)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Account & Security',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ───────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: maroonAccent.withOpacity(0.2),
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: maroonAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_username,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text(_email,
                      style: TextStyle(
                          fontSize: 14,
                          color: safeAccent,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Security Preferences ─────────────────────────────────
            Text('Security Preferences',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subTextColor)),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // ── 2FA Toggle ───────────────────────────────────
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: maroonAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.security, color: maroonAccent, size: 20),
                    ),
                    title: Text('Two-Factor Authentication',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text(
                      _biometricsAvailable
                          ? 'Require biometrics after login'
                          : 'Biometrics not available on this device',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                    value: _is2FAEnabled,
                    // ✅ Disabled entirely if device has no biometrics
                    onChanged: _biometricsAvailable ? _toggle2FA : null,
                    activeColor: safeAccent,
                  ),

                  Divider(color: borderColor, height: 1, indent: 60),

                  // ── Biometric Unlock Toggle ───────────────────────
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: subTextColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fingerprint, color: subTextColor, size: 20),
                    ),
                    title: Text('Biometric Unlock',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text('Use Face ID or Fingerprint to unlock',
                        style: TextStyle(fontSize: 12, color: subTextColor)),
                    value: _biometricsEnabled,
                    onChanged: _biometricsAvailable ? _toggleBiometrics : null,
                    activeColor: safeAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── System ───────────────────────────────────────────────
            Text('System',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subTextColor)),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                leading: Icon(Icons.history, color: subTextColor),
                title: Text('Export Audit Logs',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right, color: subTextColor),
                onTap: () {
                  AuraToast.show(
                    context: context,
                    title: 'Exporting',
                    message: 'Exporting logs to CSV...',
                    icon: Icons.download_outlined,
                    color: safeAccent,
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // ── Logout Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent.withOpacity(0.1),
                  foregroundColor: maroonAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: maroonAccent.withOpacity(0.5)),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Secure Logout',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _logout(context),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}