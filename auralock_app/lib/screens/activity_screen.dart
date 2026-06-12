import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore Database

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _activities = [];

  final Color maroonAccent = const Color(0xFF9E1A1A); 

  @override
  void initState() {
    super.initState();
    _fetchActivityFeed();
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // 🔥 FIREBASE: FETCH FROM CLOUD FIRESTORE 🔥
  Future<void> _fetchActivityFeed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Point to the specific user's activity log collection in Firebase
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity_logs')
          .orderBy('timestamp', descending: true) // Newest first
          .get();

      // 2. Map the Firebase documents back into your standard List structure
      final List<Map<String, dynamic>> fetchedActivities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'] ?? 'Unknown Event',
          'location': data['location'] ?? 'Unknown Device',
          'time': data['time'] ?? 'Just now', // You can save strings like "2 mins ago" here
          'type': data['type'] ?? 'info',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _activities = fetchedActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: $e'), backgroundColor: maroonAccent));
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'success': return Icons.fingerprint;
      case 'warning': return Icons.warning_amber_rounded;
      default: return Icons.shield;
    }
  }

  Color _getColorForType(String type, Color defaultColor) {
    switch (type) {
      case 'success': return Colors.blueAccent;
      case 'warning': return maroonAccent;
      default: return defaultColor;
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
        title: Text('System Audit Log', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: maroonAccent))
        : _activities.isEmpty
            ? Center(child: Text("No system activity recorded yet.", style: TextStyle(color: subTextColor)))
            : RefreshIndicator(
                color: maroonAccent,
                onRefresh: _fetchActivityFeed, 
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final bool isWarning = activity['type'] == 'warning';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isWarning ? maroonAccent.withOpacity(0.5) : borderColor),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getColorForType(activity['type'], textColor).withOpacity(0.1),
                              child: Icon(_getIconForType(activity['type']), color: _getColorForType(activity['type'], textColor)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activity['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWarning ? maroonAccent : textColor)),
                                  const SizedBox(height: 4),
                                  Text(activity['location'], style: TextStyle(fontSize: 13, color: subTextColor)),
                                ],
                              ),
                            ),
                            Text(activity['time'], style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}