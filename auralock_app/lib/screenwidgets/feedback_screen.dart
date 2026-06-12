import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false; // Prevents multiple submissions

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  // 🔥 THE FUNCTIONAL FIRESTORE LOGIC
  Future<void> _submitFeedback() async {
    final String message = _feedbackController.text.trim();
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback before submitting.'), backgroundColor: Color(0xFF9E1A1A)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus(); // Close the keyboard

    try {
      // 1. Get the current user
      final user = FirebaseAuth.instance.currentUser;
      
      // 2. Save to Firestore "feedback" collection
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? 'unauthenticated',
        'email': user?.email ?? 'No email',
        'rating': _selectedRating,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': '2.1.0', // Helpful for debugging user issues
        'status': 'new', // For your admin dashboard later
      });

      // 3. Show Success & Close
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you! Your feedback has been securely sent.'), backgroundColor: Colors.green),
        );
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send feedback: $e'), backgroundColor: const Color(0xFF9E1A1A)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Provide Feedback', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How are we doing?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text("Your feedback helps us improve AuraLock's security and user experience.", style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B))),
            const SizedBox(height: 32),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _selectedRating ? Colors.amber : borderColor,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _selectedRating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Text Area
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Tell us what you love, or what we can do better...',
                hintStyle: TextStyle(color: isDark ? const Color(0xFF8D99AE).withOpacity(0.5) : const Color(0xFF64748B).withOpacity(0.5)),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.all(20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: maroonAccent.withOpacity(0.5),
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Feedback', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}