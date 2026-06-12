import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_usage/app_usage.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  List<AppUsageInfo> _infos = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  final Color maroonAccent = const Color(0xFF9E1A1A);
  final Color safeAccent = const Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _getUsageStats();
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> _getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      // Fetch usage from exactly 24 hours ago
      DateTime startDate = endDate.subtract(const Duration(hours: 24));

      // This talks to the Android OS!
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
      
      // Filter out system background processes (apps used for 0 seconds)
      infoList.removeWhere((info) => info.usage.inSeconds == 0);
      
      // Sort by the most used apps first
      infoList.sort((a, b) => b.usage.inSeconds.compareTo(a.usage.inSeconds));

      setState(() {
        _infos = infoList;
        _isLoading = false;
        _permissionDenied = false;
      });
    } on PlatformException catch (exception) {
      print(exception);
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  // Helper to format Duration into readable text (e.g., "2h 15m" or "45s")
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('App Tracking Engine', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _buildBody(textColor, subTextColor, cardColor, borderColor),
    );
  }

  Widget _buildBody(Color textColor, Color subTextColor, Color cardColor, Color borderColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: maroonAccent));
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, size: 80, color: maroonAccent),
              const SizedBox(height: 24),
              Text('Permission Required', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(
                'AuraLock needs "Usage Access" to track which apps are running on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: maroonAccent, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                onPressed: _getUsageStats, // Pressing this triggers the Android permission prompt!
                child: const Text('Grant Permission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    if (_infos.isEmpty) {
      return Center(child: Text("No app usage detected today.", style: TextStyle(color: subTextColor)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _infos.length,
      itemBuilder: (context, index) {
        final info = _infos[index];
        
        // Highlight heavy usage (over 1 hour) in Red as a potential distraction/threat!
        final bool isHeavyUsage = info.usage.inHours >= 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Placeholder for App Icon (Android package names are tricky to get icons for without heavy native code)
              CircleAvatar(
                backgroundColor: isHeavyUsage ? maroonAccent.withOpacity(0.1) : safeAccent.withOpacity(0.1),
                child: Icon(Icons.android, color: isHeavyUsage ? maroonAccent : safeAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.packageName.split('.').last, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Text(info.packageName, style: TextStyle(fontSize: 12, color: subTextColor), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatDuration(info.usage), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isHeavyUsage ? maroonAccent : textColor)),
                  Text('Usage Time', style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}