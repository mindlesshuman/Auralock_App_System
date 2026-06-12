import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();
  final Color maroonAccent = const Color(0xFF9E1A1A);

  @override
  void initState() {
    super.initState();
    _checkOfflineSession();
  }

  Future<void> _checkOfflineSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    String? token = await _storage.read(key: 'jwt_token');
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (token != null || firebaseUser != null) {
      String? requiresBio = await _storage.read(key: 'use_biometrics');
      
      if (requiresBio == 'true') {
        bool passed = await _triggerBiometrics();
        if (!passed) {
          // 🔥 SECURITY PATCH: The user failed or cancelled the scan.
          // Do not let them hang on the splash screen. Kick them to the Login Screen!
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          }
          return; // Stop the code here!
        }
      }
      
      // If we reach here, they either passed the scan, or didn't have biometrics enabled.
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }
  }

  Future<bool> _triggerBiometrics() async {
    try {
      final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      
      // 🔥 SECURITY PATCH: If hardware is missing or broken, FAIL CLOSED (return false).
      if (!canAuthenticate) {
        debugPrint("Biometric hardware missing or disabled.");
        return false; 
      }

      return await _auth.authenticate(
        localizedReason: 'Unlock AuraLock Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: ${e.message}");
      return false; // Always fail closed on error!
    }
  }

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA); 

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your spinning/pulsing logo goes here
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: maroonAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: Image.asset('assets/images/icons/system_auralock.png'), 
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(color: maroonAccent),
          ],
        ),
      ),
    );
  }
}