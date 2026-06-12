import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui';
import '../services/vault_service.dart'; 

class AddApplicationSheet extends StatefulWidget {
  final VoidCallback onSaved; // Tells the Home Screen to refresh data

  const AddApplicationSheet({super.key, required this.onSaved});

  @override
  State<AddApplicationSheet> createState() => _AddApplicationSheetState();
}

class _AddApplicationSheetState extends State<AddApplicationSheet> {
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  final Color maroonAccent = const Color(0xFF9E1A1A);
  
  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  // 🛡️ Pop-up Notification System (No Bottom Snackbars)
  void _showPopUp(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _isSystemDark(context) ? const Color(0xFF131D3B) : Colors.white,
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _isSystemDark(context) ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: maroonAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPremiumScanner() async {
    final String? scannedCode = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, 
        pageBuilder: (context, _, __) => const PremiumScannerOverlay(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (scannedCode != null && mounted) {
      setState(() {
        _secretController.text = scannedCode;
      });
      _showPopUp('Scan Successful', 'Secret key automatically extracted and populated.', Icons.check_circle_outline, const Color(0xFF0D9488));
    }
  }

  Future<void> _saveApplication() async {
    if (_appNameController.text.trim().isEmpty || _secretController.text.trim().isEmpty) {
      _showPopUp('Missing Fields', 'Please provide an application name and security key.', Icons.warning_amber_rounded, Colors.orange);
      return;
    }

    final secretKey = _secretController.text.trim().replaceAll(' ', '').toUpperCase();

    try {
      await VaultService.box.put(_appNameController.text.trim(), {
        'appName': _appNameController.text.trim(),
        'secretKey': secretKey,
        'addedAt': DateTime.now().toIso8601String(),
      });
      
      widget.onSaved(); // Triggers _fetchDashboardData on the home screen

      if (mounted) {
        Navigator.pop(context); 
        _showPopUp('Secured', '${_appNameController.text} secured in offline vault.', Icons.shield_outlined, const Color(0xFF0D9488));
      }
    } catch (e) {
      _showPopUp('Error', 'Failed to save application.', Icons.error_outline, maroonAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color fieldColor = isDark ? const Color(0xFF131D3B) : Colors.transparent;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Add Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            const Text('Link a new app to your AuraLock authenticator vault.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _appNameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Application Name (e.g. Facebook)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: fieldColor,
                prefixIcon: Icon(Icons.apps, color: maroonAccent),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: maroonAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _secretController,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Security Key / Setup Code',
                labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
                filled: true,
                fillColor: fieldColor,
                prefixIcon: Icon(Icons.key, color: maroonAccent),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: maroonAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.qr_code_scanner_rounded, color: maroonAccent),
                    onPressed: _openPremiumScanner,
                    tooltip: 'Scan QR Code',
                  ),
                ),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: maroonAccent, width: 2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text('Paste a setup code or scan a QR code.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _saveApplication,
                child: const Text('Save Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM SCANNER OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class PremiumScannerOverlay extends StatefulWidget {
  const PremiumScannerOverlay({super.key});

  @override
  State<PremiumScannerOverlay> createState() => _PremiumScannerOverlayState();
}

class _PremiumScannerOverlayState extends State<PremiumScannerOverlay> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isProcessing = false;

  final Color maroonAccent = const Color(0xFF9E1A1A);

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isProcessing = true);
      String rawCode = barcodes.first.rawValue!;
      
      if (rawCode.startsWith('otpauth://')) {
        try {
          final uri = Uri.parse(rawCode);
          final secret = uri.queryParameters['secret'];
          if (secret != null) rawCode = secret;
        } catch (_) {}
      }
      Navigator.pop(context, rawCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: maroonAccent, width: 3),
                    boxShadow: [BoxShadow(color: maroonAccent.withOpacity(0.5), blurRadius: _pulseAnimation.value, spreadRadius: _pulseAnimation.value * 0.2)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.1))),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    padding: const EdgeInsets.all(24),
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                      SizedBox(height: 16),
                      Text('Center QR Code in frame', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}