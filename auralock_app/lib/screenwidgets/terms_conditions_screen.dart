import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
        title: Text('Terms & Conditions', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last Updated: May 2026", style: TextStyle(color: maroonAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 24),
            
            _buildSection("1. Acceptance of Terms", "By accessing and using the AuraLock Authenticator App, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by these terms, please do not use this application.", textColor, subTextColor),
            _buildSection("2. Offline Vault & Security", "AuraLock is designed as an offline-first security application. Your TOTP secret keys are encrypted and stored locally on your device. You acknowledge that if you lose access to your device and do not have a backup, AuraLock cannot recover your lost authenticator codes.", textColor, subTextColor),
            _buildSection("3. User Responsibilities", "You are responsible for maintaining the confidentiality of your master password and biometric data. AuraLock is not liable for any unauthorized access to your linked third-party accounts resulting from physical device compromise.", textColor, subTextColor),
            _buildSection("4. Threat Detection", "AuraLock utilizes local telemetry (such as emulator detection and environment checks) to warn you of potential threats. This is a supplementary security feature and does not guarantee absolute protection against targeted malware.", textColor, subTextColor),
            _buildSection("5. Modifications", "We reserve the right to modify these terms at any time. Your continued use of the app following any changes signifies your acceptance of the new terms.", textColor, subTextColor),
            
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