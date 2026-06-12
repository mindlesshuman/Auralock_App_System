import 'package:flutter/material.dart';
import '../services/security_ml_service.dart';
import '../services/vault_service.dart'; // 🔥 Import the offline vault!

class ThreatResolutionScreen extends StatefulWidget {
  final String threatMessage;
  
  const ThreatResolutionScreen({super.key, required this.threatMessage});

  @override
  State<ThreatResolutionScreen> createState() => _ThreatResolutionScreenState();
}

class _ThreatResolutionScreenState extends State<ThreatResolutionScreen> {
  final SecurityMLEngine _mlEngine = SecurityMLEngine();
  List<Map<String, String>> _recommendations = [];
  bool _isAnalyzing = true;

  final Color maroonAccent = const Color(0xFF9E1A1A); 

  @override
  void initState() {
    super.initState();
    _runAIAnalysis();
  }

  Future<void> _runAIAnalysis() async {
    await _mlEngine.loadModel();
    
    // 🔥 REAL DATA: Count how many items are actually in the vault
    final int vaultSize = VaultService.box.length; 
    
    // Pass the real vault size to the AI Engine
    final results = await _mlEngine.analyzeThreat(widget.threatMessage, vaultSize); 

    if (mounted) {
      setState(() {
        _recommendations = results;
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _mlEngine.dispose(); 
    super.dispose();
  }

  bool _isSystemDark(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, color: maroonAccent, size: 20),
            const SizedBox(width: 8),
            Text('Edge AI Advisor', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isAnalyzing 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: maroonAccent),
                const SizedBox(height: 16),
                Text("Neural Engine Analyzing Threat...", style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  border: Border.all(color: maroonAccent.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: maroonAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: Icon(Icons.warning_rounded, size: 45, color: maroonAccent), 
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Threat Analyzed', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: maroonAccent, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(widget.threatMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, height: 1.3)),
            const SizedBox(height: 40),

            Text('AI Recommended Protocol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: subTextColor)),
            const SizedBox(height: 16),

            ..._recommendations.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> rec = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: maroonAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${index + 1}', style: TextStyle(color: maroonAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rec['title']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 8),
                          Text(rec['desc']!, style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}