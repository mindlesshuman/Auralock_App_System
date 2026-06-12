import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationSeverity { critical, warning, info }

class AuraNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final NotificationSeverity severity;
  bool isRead;

  AuraNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.severity,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Security audit — real device checks
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityAudit {
  static const _channel = MethodChannel('com.auralock/security');

  static Future<List<AuraNotification>> run() async {
    final results = <AuraNotification>[];
    final now = DateTime.now();

    // ── 1. Emulator / virtual device detection ──────────────────────────────
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final isEmulator = !androidInfo.isPhysicalDevice;
      final suspiciousBrand = ['generic', 'unknown', 'android sdk built for x86']
          .contains(androidInfo.brand.toLowerCase());
      final suspiciousModel = androidInfo.model.toLowerCase().contains('sdk') ||
          androidInfo.model.toLowerCase().contains('emulator') ||
          androidInfo.model.toLowerCase().contains('genymotion');

      if (isEmulator || suspiciousBrand || suspiciousModel) {
        results.add(AuraNotification(
          id: 'virt_env',
          title: 'Virtual Environment Detected',
          message:
              'AuraLock is running on an emulated device (${androidInfo.model}). '
              'Your vault credentials may be at risk. Use a physical device only.',
          timestamp: now,
          icon: Icons.dangerous_outlined,
          severity: NotificationSeverity.critical,
        ));
      }
    } on UnsupportedError {
      // iOS — use iOS device info instead
      try {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          results.add(AuraNotification(
            id: 'virt_env_ios',
            title: 'Simulator Detected',
            message:
                'AuraLock is running in an iOS simulator. '
                'Sensitive data should never be accessed in a simulated environment.',
            timestamp: now,
            icon: Icons.dangerous_outlined,
            severity: NotificationSeverity.critical,
          ));
        }
      } catch (_) {}
    } catch (_) {}

    // ── 2. Root / jailbreak detection via platform channel ──────────────────
    // Your native layer should implement this channel method.
    // Returns: { "rooted": bool, "reason": String }
    try {
      final Map result = await _channel.invokeMethod('checkRootStatus');
      if (result['rooted'] == true) {
        results.add(AuraNotification(
          id: 'root_detected',
          title: 'Rooted / Jailbroken Device',
          message:
              'Your device appears to be rooted or jailbroken (${result['reason']}). '
              'This severely weakens AuraLock\'s security guarantees.',
          timestamp: now,
          icon: Icons.shield_outlined,
          severity: NotificationSeverity.critical,
        ));
      }
    } on MissingPluginException {
      // Native channel not implemented yet — skip silently
    } catch (_) {}

    // ── 3. Developer options / USB debugging ────────────────────────────────
    // Returns: { "adbEnabled": bool }
    try {
      final Map result =
          await _channel.invokeMethod('checkDeveloperOptions');
      if (result['adbEnabled'] == true) {
        results.add(AuraNotification(
          id: 'adb_enabled',
          title: 'USB Debugging Active',
          message:
              'Android Debug Bridge (ADB) is enabled on this device. '
              'This allows external tools to inspect app data. Disable it in Developer Options.',
          timestamp: now,
          icon: Icons.usb_outlined,
          severity: NotificationSeverity.warning,
        ));
      }
    } on MissingPluginException {
      // skip
    } catch (_) {}

    // ── 4. Battery — low battery warning (security ops may be interrupted) ──
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      final state = await battery.batteryState;
      if (level <= 15 && state != BatteryState.charging) {
        results.add(AuraNotification(
          id: 'low_battery',
          title: 'Critical Battery Level',
          message:
              'Battery at $level%. AuraLock operations (TOTP, sync, re-auth) '
              'may be interrupted. Charge your device to maintain security continuity.',
          timestamp: now,
          icon: Icons.battery_alert_outlined,
          severity: NotificationSeverity.warning,
        ));
      }
    } catch (_) {}

    // ── 5. Screen overlay / accessibility abuse detection ───────────────────
    // Returns: { "overlayRisk": bool, "services": List<String> }
    try {
      final Map result =
          await _channel.invokeMethod('checkAccessibilityServices');
      if (result['overlayRisk'] == true) {
        final services = (result['services'] as List?)?.join(', ') ?? 'unknown';
        results.add(AuraNotification(
          id: 'overlay_risk',
          title: 'Suspicious Accessibility Services',
          message:
              'Active services ($services) may intercept input or overlay screens. '
              'Disable unknown accessibility services to protect your credentials.',
          timestamp: now,
          icon: Icons.visibility_outlined,
          severity: NotificationSeverity.critical,
        ));
      }
    } on MissingPluginException {
      // skip
    } catch (_) {}

    return results;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSystemDark(BuildContext context) =>
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  List<AuraNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  static const Color _maroon = Color(0xFF9E1A1A);
  static const Color _safe = Color(0xFF0D9488);
  static const Color _warn = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _SecurityAudit.run();
      // Sort: critical first, then warning, then info; newest within group
      results.sort((a, b) {
        final severityOrder = {
          NotificationSeverity.critical: 0,
          NotificationSeverity.warning: 1,
          NotificationSeverity.info: 2,
        };
        final cmp =
            severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
        if (cmp != 0) return cmp;
        return b.timestamp.compareTo(a.timestamp);
      });
      if (mounted) setState(() => _notifications = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Color _severityColor(NotificationSeverity s) => switch (s) {
        NotificationSeverity.critical => _maroon,
        NotificationSeverity.warning => _warn,
        NotificationSeverity.info => _safe,
      };

  String _severityLabel(NotificationSeverity s) => switch (s) {
        NotificationSeverity.critical => 'CRITICAL',
        NotificationSeverity.warning => 'WARNING',
        NotificationSeverity.info => 'INFO',
      };

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bg = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color card =
        isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color text = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color sub =
        isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notifications',
                style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _maroon,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: TextStyle(
                      color: _maroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: text),
            tooltip: 'Re-scan',
            onPressed: _isLoading ? null : _runAudit,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading(text, sub)
          : _error != null
              ? _buildError(text, sub)
              : _notifications.isEmpty
                  ? _buildEmpty(text, sub, card, border)
                  : _buildList(text, sub, card, border, isDark),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading(Color text, Color sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _maroon),
          const SizedBox(height: 20),
          Text('Scanning device security...',
              style: TextStyle(color: sub, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(Color text, Color sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: _maroon, size: 48),
            const SizedBox(height: 16),
            Text('Scan Failed',
                style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: sub, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(backgroundColor: _maroon),
              onPressed: _runAudit,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty (all clear) ─────────────────────────────────────────────────────

  Widget _buildEmpty(
      Color text, Color sub, Color card, Color border) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _safe.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.verified_user, color: _safe, size: 52),
            ),
            const SizedBox(height: 24),
            Text('All Clear',
                style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'No security issues detected on this device.\nAuraLock will alert you if anything changes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _safe),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _runAudit,
              icon: const Icon(Icons.refresh, color: _safe),
              label: const Text('Re-scan',
                  style: TextStyle(color: _safe)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification list ─────────────────────────────────────────────────────

  Widget _buildList(Color text, Color sub, Color card,
      Color border, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notifications.length,
      itemBuilder: (context, i) {
        final n = _notifications[i];
        final color = _severityColor(n.severity);

        return GestureDetector(
          onTap: () => setState(() => n.isRead = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.isRead ? card : color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: n.isRead ? border : color.withOpacity(0.35),
                  width: n.isRead ? 1 : 1.5),
              boxShadow: n.isRead
                  ? []
                  : [
                      BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(n.isRead ? 0.12 : 1.0),
                      shape: BoxShape.circle),
                  child: Icon(n.icon,
                      color: n.isRead ? color : Colors.white,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          // Severity chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(_severityLabel(n.severity),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(n.message,
                          style: TextStyle(
                              color: sub, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 8),
                      // Footer
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 11, color: sub.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(_formatTime(n.timestamp),
                              style: TextStyle(
                                  color: sub.withOpacity(0.7),
                                  fontSize: 11)),
                          if (!n.isRead) ...[
                            const Spacer(),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text('Unread',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}