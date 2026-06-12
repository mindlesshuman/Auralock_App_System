import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricsEnabled = true;
  bool _hideCodesOnLaunch = false;
  bool _screenshotProtection = true;
  String _autoLockTimer = '1 Minute';

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

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
        title: Text('Security Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vault Access", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: maroonAccent)),
            const SizedBox(height: 12),
            _buildSettingsCard(
              cardColor, borderColor,
              Column(
                children: [
                  _buildToggle(Icons.fingerprint, "Biometric Unlock", "Use FaceID or TouchID to open vault", _biometricsEnabled, (val) => setState(() => _biometricsEnabled = val), textColor, subTextColor, maroonAccent),
                  _buildDivider(borderColor),
                  ListTile(
                    leading: Icon(Icons.timer_outlined, color: textColor),
                    title: Text("Auto-Lock Timer", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text("Lock vault after inactivity", style: TextStyle(color: subTextColor, fontSize: 13)),
                    trailing: DropdownButton<String>(
                      value: _autoLockTimer,
                      dropdownColor: cardColor,
                      style: TextStyle(color: maroonAccent, fontWeight: FontWeight.bold),
                      underline: const SizedBox(),
                      items: ['Immediate', '1 Minute', '5 Minutes', 'Never'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setState(() => _autoLockTimer = val!),
                    ),
                  ),
                  _buildDivider(borderColor),
                  ListTile(
                    leading: Icon(Icons.password, color: textColor),
                    title: Text("Change Master Password", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      // Navigate to change password screen
                    },
                  ),
                ],
              )
            ),

            const SizedBox(height: 32),
            Text("Display & Privacy", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: maroonAccent)),
            const SizedBox(height: 12),
            _buildSettingsCard(
              cardColor, borderColor,
              Column(
                children: [
                  _buildToggle(Icons.visibility_off_outlined, "Hide Codes on Launch", "Tap to reveal 6-digit codes", _hideCodesOnLaunch, (val) => setState(() => _hideCodesOnLaunch = val), textColor, subTextColor, maroonAccent),
                  _buildDivider(borderColor),
                  _buildToggle(Icons.screen_share_outlined, "Prevent Screenshots", "Block capturing codes on this device", _screenshotProtection, (val) => setState(() => _screenshotProtection = val), textColor, subTextColor, maroonAccent),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Color cardColor, Color borderColor, Widget child) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: child,
    );
  }

  Widget _buildToggle(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged, Color textColor, Color subTextColor, Color activeColor) {
    return SwitchListTile(
      secondary: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 13)),
      value: value,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(color: borderColor, height: 1, indent: 56);
  }
}