import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  // 🔥 LAUNCH EMAIL APP
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@auralock.com',
      query: 'subject=AuraLock Security Support Request', // Pre-fills the subject!
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email client installed on this device.'), backgroundColor: Color(0xFF9E1A1A)),
        );
      }
    }
  }

  // 🔥 LAUNCH WEB BROWSER
  Future<void> _launchWebsite(BuildContext context) async {
    final Uri webUri = Uri.parse('https://www.auralock.com/support');

    try {
      if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch website');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the web browser.'), backgroundColor: Color(0xFF9E1A1A)),
        );
      }
    }
  }

  // 🔥 SIMULATE LIVE CHAT
  void _openLiveChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live Chat is currently offline. Please use Email Support.'), 
        backgroundColor: Color(0xFF9E1A1A)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Contact Support', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.support_agent_rounded, size: 80, color: maroonAccent.withOpacity(0.8)),
            const SizedBox(height: 24),
            Text("We're here to help", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text(
              "If you're experiencing issues with your vault, reach out to our security team.", 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 15, color: subTextColor, height: 1.5)
            ),
            const SizedBox(height: 40),

            _buildContactCard(
              icon: Icons.email_outlined, 
              title: "Email Support", 
              subtitle: "support@auralock.com", 
              cardColor: cardColor, 
              borderColor: borderColor, 
              textColor: textColor, 
              subTextColor: subTextColor, 
              accentColor: maroonAccent,
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.chat_bubble_outline, 
              title: "Live Chat", 
              subtitle: "Available 9AM - 5PM EST", 
              cardColor: cardColor, 
              borderColor: borderColor, 
              textColor: textColor, 
              subTextColor: subTextColor, 
              accentColor: maroonAccent,
              onTap: () => _openLiveChat(context),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.language, 
              title: "Website", 
              subtitle: "www.auralock.com/support", 
              cardColor: cardColor, 
              borderColor: borderColor, 
              textColor: textColor, 
              subTextColor: subTextColor, 
              accentColor: maroonAccent,
              onTap: () => _launchWebsite(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color cardColor, 
    required Color borderColor, 
    required Color textColor, 
    required Color subTextColor, 
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
          ],
        ),
      ),
    );
  }
}