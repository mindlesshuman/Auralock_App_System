import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auralock_app/widgets/aura_toast.dart'; // Adjust path if needed
// import 'threat_resolution_screen.dart'; // Uncomment when ready to link!

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Password Generator State
  double _passwordLength = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generatedPassword = "";

  // Mock Health State
  final double _healthScore = 0.85;

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _generatePassword(); // Generate an initial password on load
  }

  // 🔥 OFFLINE PASSWORD GENERATOR LOGIC
  void _generatePassword() {
    if (!_useUppercase && !_useLowercase && !_useNumbers && !_useSymbols) {
      setState(() => _generatedPassword = "Select at least one option");
      return;
    }

    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    String chars = '';
    if (_useUppercase) chars += upper;
    if (_useLowercase) chars += lower;
    if (_useNumbers) chars += numbers;
    if (_useSymbols) chars += symbols;

    final Random rnd = Random.secure();
    String newPassword = String.fromCharCodes(
      Iterable.generate(_passwordLength.toInt(), (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    setState(() {
      _generatedPassword = newPassword;
    });
  }

  void _copyPassword() {
    if (_generatedPassword == "Select at least one option") return;
    
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    AuraToast.show(
      context: context,
      title: 'Password Copied',
      message: 'Secure password saved to clipboard.',
      icon: Icons.copy,
      color: const Color(0xFF0D9488), 
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
    final Color safeAccent = const Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Security Center", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text("Monitor and harden your vault defense.", style: TextStyle(color: subTextColor, fontSize: 14)),
              const SizedBox(height: 32),

              // 1. ACTIVE THREAT MONITOR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: safeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: safeAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: safeAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.security, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("System Secure", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text("ML Telemetry active. No threats detected.", style: TextStyle(color: subTextColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: safeAccent, size: 16),
                      onPressed: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const ThreatResolutionScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. VAULT HEALTH SCORE
              Text("Vault Health", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _healthScore,
                            strokeWidth: 8,
                            backgroundColor: borderColor,
                            color: Colors.amber, // 85% is good, but not perfect
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Text(
                              "${(_healthScore * 100).toInt()}%",
                              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthCheck(Icons.fingerprint, "Biometrics Enabled", true, safeAccent, subTextColor),
                          const SizedBox(height: 12),
                          _buildHealthCheck(Icons.password, "Strong Master Key", true, safeAccent, subTextColor),
                          const SizedBox(height: 12),
                          _buildHealthCheck(Icons.cloud_off, "Offline Backup", false, maroonAccent, subTextColor), // Example of a missing item
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. OFFLINE PASSWORD GENERATOR
              Text("Password Generator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Password Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generatedPassword,
                              style: TextStyle(
                                color: maroonAccent, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                fontFamily: 'Courier',
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _copyPassword,
                            child: Icon(Icons.copy, color: subTextColor),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: _generatePassword,
                            child: Icon(Icons.refresh, color: safeAccent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Length Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Length", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        Text("${_passwordLength.toInt()} characters", style: TextStyle(color: safeAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _passwordLength,
                      min: 8,
                      max: 64,
                      activeColor: safeAccent,
                      inactiveColor: borderColor,
                      onChanged: (value) {
                        setState(() {
                          _passwordLength = value;
                          _generatePassword();
                        });
                      },
                    ),

                    // Toggles
                    _buildGeneratorToggle("Uppercase (A-Z)", _useUppercase, (val) => setState(() { _useUppercase = val; _generatePassword(); }), textColor, safeAccent),
                    _buildGeneratorToggle("Lowercase (a-z)", _useLowercase, (val) => setState(() { _useLowercase = val; _generatePassword(); }), textColor, safeAccent),
                    _buildGeneratorToggle("Numbers (0-9)", _useNumbers, (val) => setState(() { _useNumbers = val; _generatePassword(); }), textColor, safeAccent),
                    _buildGeneratorToggle("Symbols (!@#)", _useSymbols, (val) => setState(() { _useSymbols = val; _generatePassword(); }), textColor, safeAccent),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Vault Health Checks
  Widget _buildHealthCheck(IconData icon, String text, bool isSecure, Color safeColor, Color subTextColor) {
    return Row(
      children: [
        Icon(isSecure ? Icons.check_circle : Icons.error, color: isSecure ? safeColor : const Color(0xFF9E1A1A), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              color: isSecure ? subTextColor : const Color(0xFF9E1A1A), 
              fontSize: 13, 
              fontWeight: isSecure ? FontWeight.normal : FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Password Generator Toggles
  Widget _buildGeneratorToggle(String title, bool value, Function(bool) onChanged, Color textColor, Color activeColor) {
    return Transform.scale(
      scale: 0.9, // Slightly smaller switches to fit nicely
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: textColor, fontSize: 14)),
        value: value,
        activeColor: activeColor,
        contentPadding: EdgeInsets.zero,
        onChanged: onChanged,
      ),
    );
  }
}