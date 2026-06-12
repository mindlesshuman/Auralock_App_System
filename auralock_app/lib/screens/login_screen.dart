import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:auralock_app/services/two_factor_services.dart';
import 'forgot_password_screen.dart';
import 'package:auralock_app/widgets/aura_toast.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController   = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isLoading        = false;
  bool _obscurePassword  = true;
  bool _rememberMe       = false;
  bool _bioUnlockEnabled = false; // reflects pref_bio stored by AccountScreen

  final Color maroonAccent = const Color(0xFF9E1A1A);
  final Color safeAccent   = const Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadBioPreference();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD SAVED STATE
  // ---------------------------------------------------------------------------
  Future<void> _loadSavedCredentials() async {
    final savedEmail    = await _storage.read(key: 'saved_email');
    final savedPassword = await _storage.read(key: 'saved_password');
    final rememberMe    = await _storage.read(key: 'remember_me');

    if (rememberMe == 'true') {
      setState(() {
        _rememberMe = true;
        if (savedEmail    != null) _identifierController.text = savedEmail;
        if (savedPassword != null) _passwordController.text   = savedPassword;
      });
    }
  }

  Future<void> _loadBioPreference() async {
    final val = await _storage.read(key: 'pref_bio');
    if (mounted) setState(() => _bioUnlockEnabled = val == 'true');
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  bool _isSystemDark(BuildContext context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // BIOMETRIC AUTH
  // ---------------------------------------------------------------------------
  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;

    try {
      // Guard: user must have enabled biometric unlock in settings first.
      final String? prefBio = await _storage.read(key: 'pref_bio');
      if (prefBio != 'true') {
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Biometric Unlock Disabled',
          message: 'Enable it under Account & Security settings.',
          icon: Icons.info_outline,
          color: maroonAccent,
        );
        return;
      }

      // Check hardware support.
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported  = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Biometrics Unavailable',
          message: 'Biometrics are not set up or supported on this device.',
          icon: Icons.warning_amber_rounded,
          color: maroonAccent,
        );
        return;
      }

      // Check enrolled biometrics.
      final List<BiometricType> enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'No Biometrics Enrolled',
          message: 'Please enroll a fingerprint or face in your device settings.',
          icon: Icons.fingerprint,
          color: maroonAccent,
        );
        return;
      }

      // Require a cached session token — biometrics are an unlock, not a login.
      final String? cachedToken = await _storage.read(key: 'jwt_token');
      if (cachedToken == null) {
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'No Offline Session',
          message: 'Please log in with your password first.',
          icon: Icons.info_outline,
          color: maroonAccent,
        );
        return;
      }

      // Prompt biometric dialog.
      bool didAuthenticate = false;
      try {
        didAuthenticate = await _auth.authenticate(
          localizedReason: 'Scan your fingerprint or face to unlock AuraLock',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } on PlatformException catch (e) {
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Biometric Error',
          message: e.message ?? e.code,
          icon: Icons.error_outline,
          color: maroonAccent,
        );
        return;
      }

      // User cancelled — return silently.
      if (!didAuthenticate) return;

      // Verify Firebase session is still valid.
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final User? firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) await firebaseUser.reload();

        if (FirebaseAuth.instance.currentUser == null) {
          await _storage.delete(key: 'jwt_token');
          if (!mounted) return;
          AuraToast.show(
            context: context,
            title: 'Session Expired',
            message: 'Your session is no longer valid. Please log in again.',
            icon: Icons.lock_clock,
            color: maroonAccent,
          );
          return;
        }
      } catch (_) {
        await _storage.delete(key: 'jwt_token');
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Session Invalid',
          message: 'Could not verify your session. Please log in again.',
          icon: Icons.lock_outline,
          color: maroonAccent,
        );
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }

      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Vault Unlocked',
        message: 'Biometric verification successful.',
        icon: Icons.fingerprint,
        color: safeAccent,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'System Error',
        message: e.toString(),
        icon: Icons.error_outline,
        color: maroonAccent,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // ---------------------------------------------------------------------------
  Future<void> _login() async {
    if (_identifierController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      AuraToast.show(
        context: context,
        title: 'Missing Fields',
        message: 'Please enter your Email and Password.',
        icon: Icons.edit_note,
        color: maroonAccent,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email:    _identifierController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Enforce email verification.
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Email Not Verified',
          message: 'Please verify your email before accessing AuraLock.',
          icon: Icons.mark_email_unread_outlined,
          color: maroonAccent,
        );
        return;
      }

      await _storage.write(key: 'jwt_token', value: userCredential.user!.uid);

      if (_rememberMe) {
        await _storage.write(
            key: 'saved_email', value: _identifierController.text.trim());
        await _storage.write(key: 'remember_me', value: 'true');
      } else {
        await _storage.delete(key: 'saved_email');
        await _storage.delete(key: 'saved_password');
        await _storage.write(key: 'remember_me', value: 'false');
      }

      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Access Granted',
        message: 'Secure session established.',
        icon: Icons.check_circle_outline,
        color: safeAccent,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          errorMessage = 'No account found with these credentials.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Unknown error occurred.';
      }

      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Login Failed',
        message: errorMessage,
        icon: Icons.lock_outline,
        color: maroonAccent,
      );
    } catch (e) {
      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'System Error',
        message: e.toString(),
        icon: Icons.error_outline,
        color: maroonAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------------------------
  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken:     googleUser.authentication.idToken,
        accessToken: clientAuth.accessToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Email Not Verified',
          message: 'Please verify your email before accessing AuraLock.',
          icon: Icons.mark_email_unread_outlined,
          color: maroonAccent,
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (FirebaseAuth.instance.currentUser == null) {
        await _storage.delete(key: 'jwt_token');
        if (!mounted) return;
        AuraToast.show(
          context: context,
          title: 'Session Error',
          message: 'Account could not be verified. Please try again.',
          icon: Icons.error_outline,
          color: maroonAccent,
        );
        return;
      }

      await _storage.write(key: 'jwt_token', value: userCredential.user!.uid);

      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Google Login',
        message: 'Access Granted via Google.',
        icon: Icons.g_mobiledata,
        color: safeAccent,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Google Sign-In Error',
        message: e.toString(),
        icon: Icons.error_outline,
        color: maroonAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // MICROSOFT LOGIN
  // ---------------------------------------------------------------------------
  Future<void> _loginWithMicrosoft() async {
    try {
      setState(() => _isLoading = true);

      final microsoftProvider = OAuthProvider('microsoft.com')
        ..addScope('user.read');

      final userCredential =
          await FirebaseAuth.instance.signInWithProvider(microsoftProvider);
      await _storage.write(key: 'jwt_token', value: userCredential.user!.uid);

      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Microsoft Login',
        message: 'Access Granted via Microsoft.',
        icon: Icons.window,
        color: safeAccent,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AuraToast.show(
        context: context,
        title: 'Microsoft Sign-In Error',
        message: e.toString(),
        icon: Icons.error_outline,
        color: maroonAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);

    final Color bgColor      = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color fieldColor   = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor  = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor    = isDark ? Colors.white             : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // ── Logo ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: maroonAccent.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Image.asset('assets/images/icons/system_auralock.png'),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'AuraLock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your All in One Security System Tracker.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: subTextColor, height: 1.5),
              ),
              const SizedBox(height: 40),

              // ── Email ─────────────────────────────────────────────
              Text('Email Address',
                  style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _identifierController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'admin@auralock.com',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.4)),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon:
                      Icon(Icons.person_outline, color: subTextColor),
                ),
              ),
              const SizedBox(height: 24),

              // ── Password ──────────────────────────────────────────
              Text('Password',
                  style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: maroonAccent, width: 1.5)),
                  prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: subTextColor),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Remember Me / Forgot Password ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value!),
                          activeColor: maroonAccent,
                          checkColor: Colors.white,
                          side: BorderSide(color: subTextColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember me',
                          style:
                              TextStyle(color: subTextColor, fontSize: 13)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: Text('Forgot Password?',
                        style: TextStyle(
                            color: maroonAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Login Button ──────────────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: maroonAccent.withOpacity(0.5),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Access System',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
              ),
              const SizedBox(height: 16),

              // ── Biometric Unlock Button ───────────────────────────
              // Appearance adapts to whether the user has enabled pref_bio.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: _bioUnlockEnabled
                          ? maroonAccent.withOpacity(0.5)
                          : borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(
                    Icons.fingerprint,
                    color: _bioUnlockEnabled ? textColor : subTextColor,
                  ),
                  label: Text(
                    _bioUnlockEnabled
                        ? 'Unlock with Biometrics'
                        : 'Biometric Unlock (Disabled)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _bioUnlockEnabled ? textColor : subTextColor,
                    ),
                  ),
                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                ),
              ),
              const SizedBox(height: 32),

              // ── Divider ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Or continue with',
                        style: TextStyle(color: subTextColor, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Social Buttons ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: _buildSocialImage(context,
                          'assets/images/icons/google.png', _loginWithGoogle)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSocialImage(
                          context,
                          'assets/images/icons/microsoft.jpg',
                          _loginWithMicrosoft)),
                ],
              ),
              const SizedBox(height: 40),

              // ── Sign Up ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: subTextColor, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: Text('Sign up',
                        style: TextStyle(
                            color: maroonAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
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

  // ---------------------------------------------------------------------------
  // SOCIAL BUTTON HELPER
  // ---------------------------------------------------------------------------
  Widget _buildSocialImage(
      BuildContext context, String imagePath, VoidCallback onTap) {
    final bool isDark = _isSystemDark(context);
    final Color fieldColor =
        isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: _isLoading ? null : onTap, // Disable during any auth operation
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
            errorBuilder: (context, error, stackTrace) => Icon(
              imagePath.contains('google') ? Icons.g_mobiledata : Icons.window,
              size: 24,
              color: isDark ? Colors.white : const Color(0xFF0A1128),
            ),
          ),
        ),
      ),
    );
  }
}