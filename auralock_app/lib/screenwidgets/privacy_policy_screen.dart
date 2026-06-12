import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Privacy Policy', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last Updated: May 2026", style: TextStyle(color: maroonAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 24),
            
            _buildSection("1. Data Collection", "AuraLock is built on a privacy-first architecture. We do not track, collect, or transmit your 2FA secret keys to any external servers. All authentication codes are generated strictly on your local device hardware.", textColor, subTextColor),
            _buildSection("2. Firebase Authentication", "We use Firebase Authentication strictly for verifying your initial identity (Email/Password or OAuth). The identifiers associated with your account are securely managed by Google Firebase and are only used to establish your master session.", textColor, subTextColor),
            _buildSection("3. Biometric Data", "AuraLock integrates with your device's native biometric hardware (FaceID/TouchID). AuraLock does not collect, store, or have direct access to your fingerprint or facial recognition data. This process is handled entirely by your mobile operating system.", textColor, subTextColor),
            _buildSection("4. Diagnostic Data", "To improve security, AuraLock may locally evaluate device environment states (e.g., checking if the app is running on an emulator) to trigger Threat Detection warnings. This data remains on your device.", textColor, subTextColor),
            _buildSection("5. Contact Us", "If you have any questions about this Privacy Policy, please contact our security team at privacy@auralock.com.", textColor, subTextColor),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: subTextColor, height: 1.6)),
        ],
      ),
    );
  }
}