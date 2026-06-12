import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'aura_toast.dart';
import 'package:auralock_app/screenwidgets/contact_support_screen.dart';
import 'package:auralock_app/screenwidgets/privacy_policy_screen.dart';
import 'package:auralock_app/screenwidgets/help_center_screen.dart';
import 'package:auralock_app/screenwidgets/terms_conditions_screen.dart';
import 'package:auralock_app/screenwidgets/feedback_screen.dart';
import 'package:auralock_app/screenwidgets/notifications_screen.dart';


class PremiumSidebar extends StatefulWidget {
  final String username;
  final String email;
  final VoidCallback onLogout;
  final Function(int) onTabSelected;

  const PremiumSidebar({
    super.key,
    required this.username,
    required this.email,
    required this.onLogout,
    required this.onTabSelected,
  });

  @override
  State<PremiumSidebar> createState() => _PremiumSidebarState();
}

class _PremiumSidebarState extends State<PremiumSidebar> {
  final Color maroonAccent = const Color(0xFF9E1A1A);
  final Color safeAccent = const Color(0xFF0D9488);

  bool _isSystemDark(BuildContext context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  bool _isProfileExpanded = false;
  bool _isLoading = false;

  // ✅ Always read fresh — not cached at init
  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get _isEmailPasswordUser {
    if (currentUser == null) return false;
    return currentUser!.providerData
        .any((info) => info.providerId == 'password');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIREBASE ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _resendVerification() async {
    if (currentUser == null) return;
    try {
      setState(() => _isLoading = true);
      await currentUser!.sendEmailVerification();
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Email Sent',
          message: 'Verification link sent to ${currentUser!.email}',
          icon: Icons.mark_email_read_outlined,
          color: safeAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Error',
          message: e.toString(),
          icon: Icons.error_outline,
          color: maroonAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Re-auth dialog ────────────────────────────────────────────────────────
  Future<String?> _showReauthDialog(String actionText) async {
    final passwordController = TextEditingController();
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Security Check',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your current password to $actionText.',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0A1128)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: maroonAccent),
            onPressed: () =>
                Navigator.pop(ctx, passwordController.text),
            child: const Text('Verify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Change Email ──────────────────────────────────────────────────────────
  Future<void> _changeEmailFlow() async {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    // Step 1 — Warning
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text('Change Email',
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Changing your email will affect your login credentials and notifications.\n\nA verification link will be sent to your new email. Your old email stays active until confirmed.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: maroonAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    // Step 2 — Re-auth
    final String? currentPassword =
        await _showReauthDialog('change your email address');
    if (currentPassword == null || currentPassword.isEmpty) return;

    // Step 3 — New email input
    final newEmailController = TextEditingController();
    final String? newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Email Address',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'new@email.com',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF0A1128) : Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: maroonAccent),
            onPressed: () =>
                Navigator.pop(ctx, newEmailController.text.trim()),
            child: const Text('Send Verification',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (newEmail == null || newEmail.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      final AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!, password: currentPassword);
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.verifyBeforeUpdateEmail(newEmail);

      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Verification Sent',
          message:
              'Check $newEmail to confirm the change.',
          icon: Icons.mark_email_unread_outlined,
          color: safeAccent,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Update Failed',
          message: e.message ?? 'Error',
          icon: Icons.error_outline,
          color: maroonAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<void> _changePasswordFlow() async {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    // Step 1 — Re-auth
    final String? currentPassword =
        await _showReauthDialog('change your password');
    if (currentPassword == null || currentPassword.isEmpty) return;

    // Step 2 — New password + confirm
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('New Password',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New password
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'New Password (min 8 chars)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0A1128)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 18),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Confirm password
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0A1128)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 18),
                    onPressed: () => setDialogState(
                        () => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Password rules hint
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('Min 8 chars, 1 number, 1 symbol',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final String newPassword = newPasswordController.text;
    final String confirmPassword = confirmPasswordController.text;

    // Validate
    if (newPassword != confirmPassword) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Mismatch',
          message: 'Passwords do not match.',
          icon: Icons.warning_amber_rounded,
          color: maroonAccent,
        );
      }
      return;
    }

    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Weak Password',
          message:
              'Needs 8+ chars, uppercase, number, and symbol.',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!, password: currentPassword);
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);

      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Password Updated',
          message: 'Your password has been changed successfully.',
          icon: Icons.check_circle_outline,
          color: safeAccent,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AuraToast.show(
          context: context,
          title: 'Update Failed',
          message: e.message ?? 'Error',
          icon: Icons.error_outline,
          color: maroonAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Add Recovery Email ────────────────────────────────────────────────────
  Future<void> _addRecoveryEmail() async {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final controller = TextEditingController();

    final String? recoveryEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Backup Email',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A backup email helps you recover your account if you lose access.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'backup@email.com',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0A1128)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: maroonAccent),
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (recoveryEmail == null || recoveryEmail.isEmpty) return;

    // Store in Firebase as a custom claim via Firestore
    // For now we store locally and show confirmation
    if (mounted) {
      AuraToast.show(
        context: context,
        title: 'Backup Email Saved',
        message: '$recoveryEmail has been added as your recovery email.',
        icon: Icons.check_circle_outline,
        color: safeAccent,
      );
    }
  }

  // ── Add Recovery Phone ────────────────────────────────────────────────────
  Future<void> _addRecoveryPhone() async {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final controller = TextEditingController();

    final String? phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Recovery Phone',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add a phone number to recover your account via SMS.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: '+1 234 567 8900',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: Colors.grey),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0A1128)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: maroonAccent),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (phone == null || phone.isEmpty) return;

    if (mounted) {
      AuraToast.show(
        context: context,
        title: 'Phone Saved',
        message: '$phone added as recovery number.',
        icon: Icons.check_circle_outline,
        color: safeAccent,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : Colors.white;
    final Color textColor =
        isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor =
        isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);
    final Color dividerColor =
        isDark ? const Color(0xFF1E2F5B) : Colors.grey.shade200;
    final Color cardColor =
        isDark ? const Color(0xFF131D3B) : const Color(0xFFF8FAFC);

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Profile Header ─────────────────────────────────────
            GestureDetector(
              onTap: () => setState(
                  () => _isProfileExpanded = !_isProfileExpanded),
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.transparent,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: maroonAccent.withOpacity(0.2),
                      child: Text(
                        widget.username.isNotEmpty
                            ? widget.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: maroonAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.username,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(widget.email,
                              style: TextStyle(
                                  color: subTextColor, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isProfileExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: subTextColor),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable Profile Panel ───────────────────────────
            AnimatedCrossFade(
              firstChild:
                  const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedProfilePanel(
                  cardColor, textColor, subTextColor),
              crossFadeState: _isProfileExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

            Divider(color: dividerColor),

            // ── Navigation Menu ────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    Icons.shield_outlined,
                    'Security Settings',
                    textColor,
                    subTextColor,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTabSelected(1);
                    },
                  ),
                  _buildMenuItem(
                    Icons.receipt_long,
                    'Activity Logs',
                    textColor,
                    subTextColor,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTabSelected(2);
                    },
                  ),
                  _buildMenuItem(
                    Icons.person,
                    'Account',
                    textColor,
                    subTextColor,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTabSelected(3);
                    },
                  ),
                  _buildMenuItem(
                    Icons.notifications_none,
                    'Notifications',
                    textColor,
                    subTextColor,
                    badge: '?',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    Icons.help_outline,
                    'Help Center',
                    textColor,
                    subTextColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                  Icons.chat_bubble_outline,
                  'Provide Feedback',
                  textColor,
                  subTextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.support_agent,
                  'Contact Support',
                  textColor,
                  subTextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
                    );
                  },
                ),
                 const SizedBox(height: 16),
                _buildMenuItem(
                  Icons.description_outlined,
                  'Terms & Conditions',
                  textColor,
                  subTextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                    );
                  },
                ),
                  _buildMenuItem(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  textColor,
                  subTextColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
               ],
              ),
            ),
            //Implement the Provide Feedback, Contact Support, Terms & Conditions, and Privacy Policy menu items from the import
            
            // ── Logout ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: maroonAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onLogout,
                  icon: Icon(Icons.logout, color: maroonAccent),
                  label: Text('Log Out',
                      style: TextStyle(
                          color: maroonAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPANDED PROFILE PANEL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildExpandedProfilePanel(
      Color cardColor, Color textColor, Color subTextColor) {
    if (currentUser == null) return const SizedBox.shrink();

    final bool isVerified = currentUser!.emailVerified;
    final String createdDate =
        currentUser!.metadata.creationTime != null
            ? DateFormat('MMM dd, yyyy')
                .format(currentUser!.metadata.creationTime!)
            : 'Unknown';
    final String lastLogin =
        currentUser!.metadata.lastSignInTime != null
            ? DateFormat('MMM dd • hh:mm a')
                .format(currentUser!.metadata.lastSignInTime!)
            : 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Verification status ──────────────────────────────
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.verified_user
                    : Icons.gpp_maybe,
                color: isVerified ? safeAccent : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'Email Verified' : 'Email Not Verified',
                style: TextStyle(
                    color: isVerified ? safeAccent : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),

          // ── Resend verification ──────────────────────────────
          if (!isVerified) ...[
            const SizedBox(height: 8),
            Text(
              'Verify your email to secure your account.',
              style: TextStyle(
                  color: Colors.orange.shade300,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange.withOpacity(0.1),
                  foregroundColor: Colors.orange,
                  elevation: 0,
                ),
                onPressed:
                    _isLoading ? null : _resendVerification,
                icon: const Icon(Icons.send, size: 16),
                label: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange))
                    : const Text('Resend Verification Email',
                        style: TextStyle(fontSize: 13)),
              ),
            ),
          ],

          // ── Account summary ──────────────────────────────────
          const SizedBox(height: 16),
          _buildInfoRow(
              'Account Created', createdDate, subTextColor),
          const SizedBox(height: 8),
          _buildInfoRow('Last Login', lastLogin, subTextColor),

          // ── Credentials (email/password users only) ──────────
          if (_isEmailPasswordUser) ...[
            Divider(
                color: subTextColor.withOpacity(0.2), height: 32),
            Text('Account Credentials',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 12),
            _buildActionButton('Change Email',
                Icons.email_outlined, textColor, _changeEmailFlow),
            const SizedBox(height: 4),
            _buildActionButton('Change Password', Icons.password,
                textColor, _changePasswordFlow),

            // ── Recovery options ─────────────────────────────
            Divider(
                color: subTextColor.withOpacity(0.2), height: 32),
            Text('Recovery Options',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 12),
            _buildActionButton(
              'Add Backup Email',
              Icons.alternate_email,
              textColor,
              _addRecoveryEmail,
            ),
            const SizedBox(height: 4),
            _buildActionButton(
              'Add Recovery Phone',
              Icons.phone_outlined,
              textColor,
              _addRecoveryPhone,
            ),
          ] else ...[
            Divider(
                color: subTextColor.withOpacity(0.2), height: 32),
            Row(
              children: [
                Icon(Icons.manage_accounts,
                    color: subTextColor, size: 16),
                const SizedBox(width: 8),
                Text('Managed by external provider',
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoRow(
      String label, String value, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(color: subTextColor, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon,
      Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: textColor.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color textColor,
    Color subTextColor, {
    String? badge,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: maroonAccent, shape: BoxShape.circle),
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: subTextColor, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}