import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:auralock_app/widgets/aura_toast.dart'; 
import 'vault_screen.dart';
import 'package:auralock_app/services/vault_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  // 🔥 PARSE THE QR CODE DATA
  Future<void> _processScannedCode(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Standard 2FA QR codes always start with otpauth://
    if (rawValue.startsWith('otpauth://totp/')) {
      try {
        final Uri uri = Uri.parse(rawValue);
        
        // 1. Extract the secret key
        final String? secret = uri.queryParameters['secret'];
        
        // 2. Extract App Name and Username
        String appName = uri.queryParameters['issuer'] ?? 'Unknown App';
        String username = 'No account name';

        if (uri.pathSegments.isNotEmpty) {
          // The path usually looks like "Google:admin@auralock.com"
          final pathParts = uri.pathSegments.last.split(':');
          
          if (appName == 'Unknown App' && pathParts.isNotEmpty) {
            appName = pathParts.first; // Fallback if issuer isn't in parameters
          }
          if (pathParts.length > 1) {
            username = pathParts[1]; // Grabs the email/username part
          }
        }

        if (secret != null && secret.isNotEmpty) {
          _scannerController.stop();

          // 🔥 SAVE TO YOUR OFFLINE VAULT 🔥
          // Using a unique key (appName + timestamp) prevents overwriting if they add two Google accounts
          final uniqueKey = '${appName}_${DateTime.now().millisecondsSinceEpoch}';
          
          await VaultService.box.put(uniqueKey, {
            'appName': appName,
            'secretKey': secret,
            'username': username,
            'addedAt': DateTime.now().toIso8601String(),
          });

          if (mounted) {
            AuraToast.show(
              context: context,
              title: 'App Secured!',
              message: '$appName has been added to your vault.',
              icon: Icons.qr_code_scanner,
              color: const Color(0xFF0D9488), 
            );
            
            Navigator.pop(context, true); 
          }
          return;
        }
      } catch (e) {
        debugPrint("Error parsing QR: $e");
      }
    }

    // If it's a regular website QR code or invalid:
    if (mounted) {
      AuraToast.show(
        context: context,
        title: 'Invalid QR Code',
        message: 'Please scan a valid 2FA setup code.',
        icon: Icons.error_outline,
        color: const Color(0xFF9E1A1A), // Maroon
      );
      // Wait a second before allowing another scan
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScannedCode(barcode.rawValue!);
                  break; // Stop after first barcode found
                }
              }
            },
          ),
          
          // 2. The Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black, // This creates the transparent cutout
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. The Scanning Targeting Brackets
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: maroonAccent, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // 4. Custom App Bar Elements
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(color: bgColor.withOpacity(0.8), shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: bgColor.withOpacity(0.8), shape: BoxShape.circle),
                    child: ValueListenableBuilder(
                      valueListenable: _scannerController, // 🔥 Listen to the entire controller now!
                      builder: (context, state, child) {
                        // 🔥 Access the torchState from inside the emitted state
                        final isTorchOn = state.torchState == TorchState.on;

                        return IconButton(
                          icon: Icon(
                            isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: isTorchOn ? Colors.amber : textColor,
                          ),
                          onPressed: () => _scannerController.toggleTorch(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 5. Instruction Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                const SizedBox(height: 16),
                Text(
                  "Position the QR code inside the frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}