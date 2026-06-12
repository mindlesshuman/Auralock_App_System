import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final Color maroonAccent = const Color(0xFF9E1A1A); 

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter your email.'), backgroundColor: maroonAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🛡️ THE PRE-FLIGHT NETWORK CHECK
      final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No internet connection. Password resets require an active network.'),
              backgroundColor: maroonAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; 
      }

      // 🔥 FIREBASE SECURE RESET LINK 🔥
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secure recovery link sent! Check your email.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
        // We just pop back to the login screen now! No more ResetPasswordScreen.
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error sending reset email.'), backgroundColor: maroonAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('System Error: $e'), backgroundColor: maroonAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA); 
    final Color fieldColor = isDark ? const Color(0xFF131D3B) : Colors.white; 
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0); 
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128); 
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fieldColor,
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(color: maroonAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
                    ],
                  ),
                  child: Icon(Icons.lock_reset, size: 50, color: maroonAccent), 
                ),
              ),
              const SizedBox(height: 32),
              Text('Forgot Password?', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              // Updated copy to reflect the link instead of the code
              Text('Enter your email address and we will send you a secure link to reset your vault password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: subTextColor, height: 1.5)),
              const SizedBox(height: 40),

              Text('Registered Email', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'admin@auralock.com',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.4)),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: maroonAccent.withOpacity(0.5),
                ),
                onPressed: _isLoading ? null : _sendResetCode,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}