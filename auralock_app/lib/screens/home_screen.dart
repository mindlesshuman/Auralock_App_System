import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'threat_resolution_screen.dart';
import 'session_logs_screen.dart';
import 'track_screen.dart';
import 'activity_screen.dart';
import 'ai_advisor_sheet.dart';
import 'package:auralock_app/services/vault_service.dart';
import 'package:auralock_app/widgets/aura_toast.dart';
import 'package:auralock_app/widgets/premium_sidebar.dart';
import 'package:auralock_app/widgets/add_application_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String _username = "Loading...";
  String _email = "Loading...";
  int _totalSessions = 0;

  bool _hasActiveThreat = false;
  String _threatMessage = "System Secure";


  Timer? _standbyTimer;
  Timer? _securityScannerTimer;
  bool _threatAlreadyLogged = false;

  void _startContinuousSecurityScan() {
    _securityScannerTimer?.cancel();
    _runSecurityScan();
    _securityScannerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint("Telemetry: Running background security sweep...");
      _runSecurityScan();
    });
  }

  final Color maroonAccent = const Color(0xFF9E1A1A);
  final Color safeAccent = const Color(0xFF0D9488);

  // final TextEditingController appNameController = TextEditingController();
  // final TextEditingController secretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _startStandbyTimer();
    _startContinuousSecurityScan();
  }

  @override
  void dispose() {
    _standbyTimer?.cancel();
    _securityScannerTimer?.cancel();
   //appNameController.dispose();
    //secretController.dispose();
    super.dispose();
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> _forceLogout() async {
    await _storage.delete(key: 'jwt_token');
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _startStandbyTimer() {
    _standbyTimer?.cancel();
    _standbyTimer = Timer(const Duration(minutes: 1), () async {
    debugPrint("Security Protocol: User idle for 1 minute. Logging out.");
    if (mounted) await _forceLogout();
  });
  }

  void _handleUserInteraction([_]) {
    _startStandbyTimer();
  }

  Future<void> _initializeDashboard() async {
    await _runSecurityScan();
    await _fetchDashboardData();
  }

  Future<void> _runSecurityScan() async {
    final deviceInfo = DeviceInfoPlugin();
    bool isEmulator = false;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        isEmulator = !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        isEmulator = !iosInfo.isPhysicalDevice;
      }

      if (isEmulator) {
        if (!_hasActiveThreat) {
          setState(() {
            _hasActiveThreat = true;
            _threatMessage = "CRITICAL: Virtualized Environment Detected.";
          });
        }

        if (!_threatAlreadyLogged) {
          _threatAlreadyLogged = true;

          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
            'title': 'Active Threat Detected!',
            'message': 'AuraLock is running in a virtualized or unauthorized environment. Vault lockdown initiated.',
            'type': 'threat',
            'isUnread': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            AuraToast.show(
              context: context,
              title: 'Security Alert',
              message: 'Virtualized Environment Detected.',
              icon: Icons.gpp_bad_outlined,
              color: maroonAccent,
            );
          }
        }
        if (kReleaseMode) {
        Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _forceLogout();
          });
        }
      }
    } catch (e) {
      debugPrint("Scanner Error: $e");
    }
  }

  Future<void> _fetchDashboardData() async {
    // 1. Check for BOTH Firebase AND our offline keycard
    final user = FirebaseAuth.instance.currentUser;
    final String? localToken = await _storage.read(key: 'jwt_token');

    // 2. Only force logout if BOTH are completely gone
    if (user == null && localToken == null) {
      _forceLogout();
      return;
    }

    setState(() {
      // 3. Gracefully handle the offline state
      if (user != null) {
        _email = user.email ?? 'Unknown Email';
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _username = user.displayName!;
        } else {
          _username = _email.split('@')[0];
        }
      } else {
        // 🔥 If Firebase is offline, we use fallback UI but keep the vault open!
        _username = "Offline User";
        _email = "Vault Unlocked Locally";
      }

      _totalSessions = VaultService.box.length;
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Widget _buildShortcutCard({
  //   required IconData icon,
  //   required String title,
  //   required Color color,
  //   required Color cardColor,
  //   required Color borderColor,
  //   required Color textColor,
  // }) {
  //   return InkWell(
  //     onTap: () {},
  //     borderRadius: BorderRadius.circular(16),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 16),
  //       decoration: BoxDecoration(
  //         color: cardColor,
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(color: borderColor),
  //         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
  //       ),
  //       child: Column(
  //         children: [
  //           Icon(icon, color: color, size: 28),
  //           const SizedBox(height: 8),
  //           Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildMenuCardGroup(Color cardColor, Color borderColor, List<Widget> children) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: cardColor,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: borderColor),
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
  //     ),
  //     child: Column(children: children),
  //   );
  // }

  // Widget _buildMenuItem(IconData icon, String title, Color textColor, Color subTextColor,
  //     {String? badge, VoidCallback? onTap}) {
  //   return ListTile(
  //     leading: Icon(icon, color: textColor),
  //     title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
  //     trailing: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         if (badge != null)
  //           Container(
  //             padding: const EdgeInsets.all(6),
  //             decoration: const BoxDecoration(color: Color(0xFF9E1A1A), shape: BoxShape.circle),
  //             child: Text(badge,
  //                 style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  //           ),
  //         const SizedBox(width: 8),
  //         Icon(Icons.chevron_right, color: subTextColor, size: 20),
  //       ],
  //     ),
  //     onTap: onTap,
  //   );
  // }

  // Widget _buildMenuDivider(Color borderColor) {
  //   return Divider(color: borderColor, height: 1, indent: 56);
  // }

  Widget _buildDashboardView(
      BuildContext context, Color textColor, Color subTextColor, Color cardColor, Color borderColor) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: maroonAccent));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      borderRadius: BorderRadius.circular(28),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: maroonAccent.withOpacity(0.2),
                        child: Text(
                          _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: maroonAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_username,
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: -0.5)),
                          Text(_email, style: TextStyle(fontSize: 14, color: subTextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration:
                    BoxDecoration(color: maroonAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.auto_awesome, color: maroonAccent),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AIAdvisorSheet(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStatusCard(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: textColor,
            title: '$_totalSessions Keys Secured',
            subtitle: 'Offline Vault is Active',
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const SessionLogsScreen())),
          ),
          const SizedBox(height: 12),
          if (_hasActiveThreat)
            _buildStatusCard(
              context: context,
              icon: Icons.warning_amber_rounded,
              iconColor: maroonAccent,
              title: 'Threat Detected',
              subtitle: _threatMessage,
              cardColor: cardColor,
              borderColor: maroonAccent.withOpacity(0.5),
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ThreatResolutionScreen(threatMessage: _threatMessage))),
            ),
          const SizedBox(height: 24),
          Text('Secured Authenticator Keys',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          if (VaultService.box.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  "No applications secured yet. Tap the scanner to add one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor),
                ),
              ),
            )
          else
            ...VaultService.box.keys.map((key) {
              final data = Map<String, dynamic>.from(VaultService.box.get(key) as Map);
              return TOTPCodeCard(
                key: ValueKey(key),
                appName: data['appName'] ?? 'Unknown App',
                secretKey: data['secretKey'] ?? '',
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subTextColor: subTextColor,
                onDelete: () async {
                  await VaultService.box.delete(key);
                  _fetchDashboardData();
                  if (mounted) {
                    AuraToast.show(
                      context: context,
                      title: 'Key Removed',
                      message: '${data['appName']} has been removed from your vault.',
                      icon: Icons.delete_outline,
                      color: const Color(0xFF9E1A1A),
                    );
                  }
                },
                onEdit: (newName) => _fetchDashboardData(), // ✅ onEdit hooked up
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context,
      {required IconData icon,
      required String label,
      required int index,
      required Color activeColor,
      required Color inactiveColor}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        _onItemTapped(index);
        _handleUserInteraction();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 24,
              color: activeColor,
            ),
        ],
      ),
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

    return Listener(
      onPointerDown: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: PremiumSidebar(
          username: _username,
          email: _email,
          onLogout: _forceLogout,
          onTabSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        backgroundColor: bgColor,
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddApplicationSheet(
              onSaved: () => _fetchDashboardData(), // Instantly updates the dashboard!
            ),
          );
        },
        backgroundColor: maroonAccent,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: SafeArea(
          child: _selectedIndex == 0
              ? _buildDashboardView(context, textColor, subTextColor, cardColor, borderColor)
              : _selectedIndex == 1
                  ? const TrackScreen()
                  : _selectedIndex == 2
                      ? const ActivityScreen()
                      : _selectedIndex == 3
                          ? const AccountScreen()
                          : const Center(child: Text("Error")),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: bgColor,
          elevation: 10,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(context,
                    icon: Icons.shield,
                    label: 'Dashboard',
                    index: 0,
                    activeColor: maroonAccent,
                    inactiveColor: subTextColor),
                _buildTabItem(context,
                    icon: Icons.grid_view_rounded,
                    label: 'Track',
                    index: 1,
                    activeColor: maroonAccent,
                    inactiveColor: subTextColor),
                const SizedBox(width: 48),
                _buildTabItem(context,
                    icon: Icons.receipt_long,
                    label: 'Activity',
                    index: 2,
                    activeColor: maroonAccent,
                    inactiveColor: subTextColor),
                _buildTabItem(context,
                    icon: Icons.person,
                    label: 'Account',
                    index: 3,
                    activeColor: maroonAccent,
                    inactiveColor: subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, color: subtitleColor ?? subTextColor)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
} // ← ends _HomeScreenState


// ─────────────────────────────────────────────────────────────────────────────
// TOTPCodeCard
// ─────────────────────────────────────────────────────────────────────────────

class TOTPCodeCard extends StatefulWidget {
  final String appName;
  final String secretKey;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback? onDelete;
  final void Function(String newName)? onEdit; // ✅ Clean signature

  const TOTPCodeCard({
    super.key,
    required this.appName,
    required this.secretKey,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<TOTPCodeCard> createState() => _TOTPCodeCardState();
}

class _TOTPCodeCardState extends State<TOTPCodeCard> {
  late Timer _timer;
  String _currentCode = "------";
  double _progress = 1.0;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _updateTOTP();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTOTP();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTOTP() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeStep = 30;
    setState(() {
      _secondsRemaining = timeStep - (now % timeStep);
      _progress = _secondsRemaining / timeStep;
      _currentCode = _generateTOTP(widget.secretKey, now ~/ timeStep);
    });
  }

  String _generateTOTP(String secret, int timeEpoch) {
    try {
      String cleanSecret = secret.replaceAll(' ', '').toUpperCase();
      Uint8List secretBytes = base32.decode(cleanSecret);
      var timeBytes = ByteData(8);
      timeBytes.setInt64(0, timeEpoch, Endian.big);
      var msg = timeBytes.buffer.asUint8List();
      var hmac = Hmac(sha1, secretBytes);
      var digest = hmac.convert(msg).bytes;
      int offset = digest[digest.length - 1] & 0xf;
      int binary = ((digest[offset] & 0x7f) << 24) |
          ((digest[offset + 1] & 0xff) << 16) |
          ((digest[offset + 2] & 0xff) << 8) |
          (digest[offset + 3] & 0xff);
      int otp = binary % 1000000;
      return otp.toString().padLeft(6, '0');
    } catch (e) {
      return "ERROR";
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: widget.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Remove ${widget.appName}?',
                style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
            content: Text(
              'This will permanently remove the authenticator key from your vault. You cannot undo this.',
              style: TextStyle(color: widget.subTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: widget.subTextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9E1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ✅ _showEditSheet is INSIDE _TOTPCodeCardState
  void _showEditSheet(BuildContext context) {
    final appNameController = TextEditingController(text: widget.appName);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: maroonAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_outlined, color: maroonAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rename Application',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: widget.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Update the display name for this authenticator entry.',
                style: TextStyle(fontSize: 14, color: widget.subTextColor),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: appNameController,
                autofocus: true,
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  labelText: 'Application Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.apps, color: maroonAccent),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: maroonAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = appNameController.text.trim();
                    if (newName.isEmpty) return;

                    // Preserve secret key, only rename
                    final existing = Map<String, dynamic>.from(
                        VaultService.box.get(widget.appName) as Map);
                    await VaultService.box.delete(widget.appName);
                    await VaultService.box.put(newName, {
                      'appName': newName,
                      'secretKey': existing['secretKey'], // untouched
                      'addedAt': existing['addedAt'],
                    });

                    widget.onEdit?.call(newName); // ✅ Only passes newName

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AuraToast.show(
                        context: context,
                        title: 'Renamed',
                        message: '${widget.appName} → $newName',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF0D9488),
                      );
                    }
                  },
                  child: const Text(
                    'Save Name',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.appName),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        } else {
          _showEditSheet(context);
          return false;
        }
      },
      onDismissed: (_) => widget.onDelete?.call(),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF9E1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Remove',
                style: TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Edit',
                style: TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.appName,
                    style: TextStyle(
                        fontSize: 14,
                        color: widget.subTextColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _currentCode.length == 6
                      ? "${_currentCode.substring(0, 3)} ${_currentCode.substring(3, 6)}"
                      : _currentCode,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      letterSpacing: 2.0),
                ),
              ],
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: widget.borderColor,
                    color: _secondsRemaining <= 5 ? const Color(0xFF9E1A1A) : Colors.green,
                  ),
                  Center(
                    child: Text(
                      _secondsRemaining.toString(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} // ← ends _TOTPCodeCardState AND TOTPCodeCard