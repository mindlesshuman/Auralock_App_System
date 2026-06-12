import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore Database

class SessionLogsScreen extends StatefulWidget {
  const SessionLogsScreen({super.key});

  @override
  State<SessionLogsScreen> createState() => _SessionLogsScreenState();
}

class _SessionLogsScreenState extends State<SessionLogsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _sessions = [];

  final Color maroonAccent = const Color(0xFF9E1A1A); 

  @override
  void initState() {
    super.initState();
    _fetchSessions(); 
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // 🔥 FIREBASE: FETCH FROM CLOUD FIRESTORE 🔥
  Future<void> _fetchSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Point to the specific user's sessions collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> fetchedSessions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'device': data['device'] ?? 'Unknown Device',
          'location': data['location'] ?? 'Unknown Location',
          'ipAddress': data['ipAddress'] ?? '0.0.0.0',
          'timestamp': data['timestamp'], // Passing the raw Firebase data
          'status': data['status'] ?? 'Unknown',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _sessions = fetchedSessions;
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

  // 🔥 UPGRADED: Handles both standard Strings and Firebase Timestamps
  String _formatDate(dynamic timestampData) {
    if (timestampData == null) return "Unknown Time";
    
    try {
      DateTime date;
      // If it's coming from Firebase, it's a Timestamp object
      if (timestampData is Timestamp) {
        date = timestampData.toDate().toLocal();
      } else {
        // Fallback for strings
        date = DateTime.parse(timestampData.toString()).toLocal();
      }
      
      const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final String month = months[date.month - 1];
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return "$month ${date.day}, ${date.year} - $hour:$minute";
    } catch (e) {
      return "Unknown Time";
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Session Logs', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: maroonAccent))
        : _sessions.isEmpty 
            ? Center(child: Text("No session logs found.", style: TextStyle(color: subTextColor)))
            : RefreshIndicator(
                color: maroonAccent,
                onRefresh: _fetchSessions, // Added pull-to-refresh here as well!
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final bool isActive = session['status'] == 'Active';
                    final bool isBlocked = session['status'] == 'Blocked';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isBlocked ? Icons.block : (isActive ? Icons.phone_iphone : Icons.computer), 
                            color: isBlocked ? maroonAccent : (isActive ? Colors.green : subTextColor), 
                            size: 28
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(session['device'] ?? 'Unknown Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                const SizedBox(height: 4),
                                Text('${session['location']} • IP: ${session['ipAddress']}', style: TextStyle(fontSize: 13, color: subTextColor)),
                                const SizedBox(height: 8),
                                Text(_formatDate(session['timestamp']), style: TextStyle(fontSize: 12, color: subTextColor.withOpacity(0.7))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBlocked ? maroonAccent.withOpacity(0.1) : (isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session['status'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: isBlocked ? maroonAccent : (isActive ? Colors.green : subTextColor)
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}