import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:auralock_app/widgets/aura_toast.dart';
// import 'home_screen.dart'; // Uncomment to route after success

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 

  final Color maroonAccent = const Color(0xFF9E1A1A); 
  final Color safeAccent = const Color(0xFF0D9488);

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // ==========================================
  // EMAIL & PASSWORD REGISTRATION
  // ==========================================
  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty) {
      _showError('Username is required!');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match!');
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$');
    if (!passwordRegex.hasMatch(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password needs 8+ chars, 1 uppercase, 1 lowercase, 1 number, and 1 symbol.'), 
          backgroundColor: Colors.orange.shade800, 
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() => _isLoading = false);
        _showError('No internet connection. Registration requires an active network.');
        return; 
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(_usernameController.text.trim());
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
  // ✅ Clear sensitive fields immediately after success
        _passwordController.clear();
        _confirmPasswordController.clear();

        // ✅ Use AuraToast to match the rest of the app
        AuraToast.show(
          context: context,
          title: 'Registration Successful',
          message: 'Please check your email to verify your account.',
          icon: Icons.mark_email_unread_outlined,
          color: safeAccent,
        );

        Navigator.pop(context);
      }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Registration Failed';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'An account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else {
          errorMessage = e.message ?? 'Unknown error occurred.';
        }
        _showError(errorMessage);
      } catch (e) {
        _showError('System Error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
  }

  // ==========================================
  // MICROSOFT OAUTH
  // ==========================================
  Future<void> _registerWithMicrosoft() async {
    try {
      setState(() => _isLoading = true);
      final OAuthProvider provider = OAuthProvider('microsoft.com');
      provider.setCustomParameters({'prompt': 'login'});

      final userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
      await _storage.write(key: 'jwt_token', value: userCredential.user!.uid);

      _routeToHome();
    } catch (e) {
      _showError('Microsoft Authentication Cancelled or Failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // GOOGLE OAUTH
  // ==========================================
  Future<void> _registerWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: clientAuth.accessToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _storage.write(key: 'jwt_token', value: userCredential.user!.uid);

      _routeToHome();
    } catch (e) {
      _showError('Google Sign-Up Cancelled or Failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helpers
      void _showError(String message) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Error',
          message: message,
          icon: Icons.error_outline,
          color: maroonAccent,
        );
      }
    }
    
  void _routeToHome() {
    if (mounted) {
       // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
       print("Successfully Authenticated! Routing to Home...");
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
              // LOGO
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: maroonAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
                    ],
                  ),
                  child: Image.asset('assets/images/icons/system_auralock.png'), 
                ),
              ),
              const SizedBox(height: 24),
              
              // HEADERS
              Text('Create an Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Sign up to start tracking your system securely.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: subTextColor, height: 1.5)),
              const SizedBox(height: 32),

              // USERNAME FIELD
              Text('Username', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'AuraAdmin',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.4)),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon: Icon(Icons.person_outline, color: subTextColor),
                ),
              ),
              const SizedBox(height: 20),

              // EMAIL FIELD
              Text('Email address', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: TextStyle(color: textColor),
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
              const SizedBox(height: 20),

              // PASSWORD FIELD
              Text('Password', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.4)),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: subTextColor),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CONFIRM PASSWORD FIELD
              Text('Confirm Password', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.4)),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon: Icon(Icons.lock_reset, color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: subTextColor),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // SIGN UP BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: maroonAccent.withOpacity(0.5),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              
              const SizedBox(height: 32),

              // DIVIDER
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Or sign up with', style: TextStyle(color: subTextColor, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // SOCIAL LOGIN ROW (Google + Microsoft only)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildSocialImage(context, 'assets/images/icons/google.png', _registerWithGoogle)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSocialImage(context, 'assets/images/icons/microsoft.jpg', _registerWithMicrosoft)),
                ],
              ),

              const SizedBox(height: 40),

              // SIGN IN PROMPT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: subTextColor, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context), 
                    child: Text('Sign In', style: TextStyle(color: maroonAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialImage(BuildContext context, String imagePath, VoidCallback onTap) {
    final bool isDark = _isSystemDark(context);
    final Color fieldColor = isDark ? const Color(0xFF131D3B) : Colors.white; 
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0); 

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fieldColor, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            height: 24,
            width: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}