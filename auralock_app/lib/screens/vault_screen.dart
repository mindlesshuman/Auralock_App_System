import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:auralock_app/widgets/aura_toast.dart'; // Adjust path if needed
import 'package:auralock_app/services/vault_service.dart'; // Adjust path if needed

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // 🔥 1. Replaced the fake data with empty lists that will hold your real data
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  
  late Timer _totpTimer;
  int _secondsRemaining = 30;
  bool _obscureCodes = false;

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    // 🔥 2. Call the function to load your offline vault data when the screen opens
    _loadVaultData(); 
    _calculateTimeRemaining();
    
    // Ticks every second to update the circular progress bars
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _calculateTimeRemaining();
    });
  }

  // 🔥 3. The new function that grabs data from your VaultService
  void _loadVaultData() {
    // Read everything saved in the local Hive box
    final boxData = VaultService.box.values.toList();
    
    setState(() {
      // Convert it into the exact format the UI expects
      _allApps = boxData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _filteredApps = List.from(_allApps);
    });
  }
  
  void _calculateTimeRemaining() {
    final int currentSecond = DateTime.now().second;
    setState(() {
      // TOTP codes refresh exactly on the 0 and 30 second marks
      _secondsRemaining = 30 - (currentSecond % 30); 
    });
  }

  void _filterApps(String query) {
    if (query.isEmpty) {
      setState(() => _filteredApps = List.from(_allApps));
      return;
    }
    setState(() {
      _filteredApps = _allApps.where((app) => 
        app['appName'].toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Generate the live 6-digit code using the secret key
  String _generateCode(String secret) {
    try {
      final code = OTP.generateTOTPCodeString(
        secret, 
        DateTime.now().millisecondsSinceEpoch, 
        algorithm: Algorithm.SHA1, 
        isGoogle: true
      );
      // Format it as "123 456" for readability
      return "${code.substring(0, 3)} ${code.substring(3, 6)}";
    } catch (e) {
      return "--- ---"; // Fallback if secret is invalid
    }
  }

  void _copyToClipboard(String appName, String secret) {
    final code = _generateCode(secret).replaceAll(' ', ''); // Remove space for copying
    Clipboard.setData(ClipboardData(text: code));
    
    AuraToast.show(
      context: context,
      title: 'Code Copied',
      message: '$appName 2FA code copied to clipboard.',
      icon: Icons.copy,
      color: const Color(0xFF0D9488), // Safe Accent Green
    );
  }

  @override
  void dispose() {
    _totpTimer.cancel();
    _searchController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            // 1. VAULT HEADER & SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text("${_filteredApps.length} Secured Apps", style: TextStyle(color: subTextColor, fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_obscureCodes ? Icons.visibility_off : Icons.visibility, color: subTextColor),
                    onPressed: () => setState(() => _obscureCodes = !_obscureCodes),
                  ),
                ],
              ),
            ),
            
            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterApps,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search applications...',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: subTextColor),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                ),
              ),
            ),

            // 3. THE LIVE TOTP LIST
            Expanded(
              child: _filteredApps.isEmpty
                  ? Center(child: Text("No apps found.", style: TextStyle(color: subTextColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final String code = _generateCode(app['secretKey']);
                        final double progress = _secondsRemaining / 30.0;
                        
                        // Change color to red when less than 5 seconds remain
                        final Color timerColor = _secondsRemaining <= 5 ? maroonAccent : safeAccent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              // App Logo Placeholder (First Letter)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Center(
                                  child: Text(
                                    app['appName'][0].toUpperCase(),
                                    style: TextStyle(color: maroonAccent, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // App Details & Code
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(app['appName'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text(app['username'] ?? 'No username', style: TextStyle(color: subTextColor, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _obscureCodes ? "••• •••" : code,
                                      style: TextStyle(
                                        color: timerColor, 
                                        fontSize: 24, 
                                        fontWeight: FontWeight.w900, 
                                        letterSpacing: 2,
                                        fontFamily: 'Courier', // Gives it that monospace technical look
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Timer Ring & Copy Button
                              Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 3,
                                      backgroundColor: borderColor,
                                      color: timerColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () => _copyToClipboard(app['appName'], app['secretKey']),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: safeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.copy, color: safeAccent, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // Add some padding at the bottom so the floating QR button doesn't cover the last item
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }
}