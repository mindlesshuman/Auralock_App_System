import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIAdvisorSheet extends StatefulWidget {
  const AIAdvisorSheet({super.key});

  @override
  State<AIAdvisorSheet> createState() => _AIAdvisorSheetState();
}

class _AIAdvisorSheetState extends State<AIAdvisorSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color maroonAccent = const Color(0xFF9E1A1A);
  final String _geminiApiKey = "ADD_YOUR_CHOSEN_AI_API_KEY_HERE"; 

  bool _isTyping = false;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Hello! I am Carat AI, your personal security advisor. I am here to help keep your AuraLock vault safe, analyze your telemetry, and answer any questions. How can I assist you today?'
    }
  ];

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userText = _messageController.text.trim();

    setState(() {
      _messages.add({'sender': 'user', 'text': userText});
      _messageController.clear();
      _isTyping = true; 
    });

    _scrollToBottom();

    try {
      // Pointing to the stable gemini-pro endpoint
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "role": "user", 
            "parts": [{"text": "You are Carat AI, an elite cybersecurity assistant for the AuraLock app. Keep your answers concise, professional, and helpful. DO NOT use markdown formatting. DO NOT use asterisks for bolding text. Respond in pure, plain text only. The user says: $userText"}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 🔥 THE UI BOUNCER: Scrub out any stray asterisks
        final String rawReply = data['candidates'][0]['content']['parts'][0]['text'];
        final String cleanReply = rawReply.replaceAll('**', '');
        
        setState(() {
          _messages.add({'sender': 'ai', 'text': cleanReply.trim()});
          _isTyping = false; 
        });
      } else {
        String exactError = "Unknown Error";
        try {
          final errorData = jsonDecode(response.body);
          exactError = errorData['error']['message'] ?? response.body;
        } catch (_) {
          exactError = response.body;
        }

        setState(() {
          _messages.add({'sender': 'ai', 'text': 'API Error ${response.statusCode}: $exactError'});
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': 'Network Error: $e'});
        _isTyping = false;
      });
    }
    
    _scrollToBottom();
  }
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color aiBubbleColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFF1F5F9);
    final Color userBubbleColor = maroonAccent;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, 
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: maroonAccent, size: 24),
                        const SizedBox(width: 8),
                        Text('Carat AI Advisor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

              // --- CHAT MESSAGES ---
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['sender'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? userBubbleColor : aiBubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          message['text']!,
                          style: TextStyle(
                            fontSize: 15,
                            color: isUser ? Colors.white : textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- TYPING INDICATOR ---
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Carat AI is analyzing...',
                      style: TextStyle(color: maroonAccent, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),

              // --- INPUT FIELD ---
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16, 
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Ask Carat AI a security question...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: maroonAccent,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}