import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // The master list of all FAQs
  final List<Map<String, String>> _allFaqs = [
    {
      "question": "How do I add a new app to my vault?",
      "answer": "Tap the red floating QR scanner button on the dashboard, or use the 'Add App' button. You can manually enter the app name and the setup key provided by the service."
    },
    {
      "question": "What happens if I lose my phone?",
      "answer": "Because AuraLock is an offline-first authenticator, your keys are stored locally on this device. You will need to use the backup codes provided by your third-party services (like Google or Facebook) to regain access."
    },
    {
      "question": "Is my data truly offline?",
      "answer": "Yes. Your TOTP secret keys are encrypted and saved only to your device's local storage. AuraLock does not sync these keys to any external servers."
    },
    {
      "question": "Why did I get a 'Threat Detected' warning?",
      "answer": "AuraLock scans your device environment for vulnerabilities, such as running on an emulator or a rooted device, which could compromise your local vault."
    },
    {
      "question": "How do I turn on Biometric Unlock?",
      "answer": "Biometrics are automatically enabled if your device supports them (FaceID or Fingerprint). You can use them to bypass the master password screen when launching the app offline."
    },
  ];

  // The list that will actually be displayed (changes when searching)
  List<Map<String, String>> _filteredFaqs = [];

  bool _isSystemDark(BuildContext context) => MediaQuery.of(context).platformBrightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    // Initially, show all FAQs
    _filteredFaqs = _allFaqs;
  }

  void _filterFaqs(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFaqs = _allFaqs);
      return;
    }

    setState(() {
      _filteredFaqs = _allFaqs.where((faq) {
        final questionLower = faq['question']!.toLowerCase();
        final answerLower = faq['answer']!.toLowerCase();
        final searchLower = query.toLowerCase();
        
        // Returns true if the search term is in the question OR the answer
        return questionLower.contains(searchLower) || answerLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isSystemDark(context);
    final Color bgColor = isDark ? const Color(0xFF0A1128) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF131D3B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2F5B) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A1128);
    final Color subTextColor = isDark ? const Color(0xFF8D99AE) : const Color(0xFF64748B);
    final Color maroonAccent = const Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Help Center', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔥 THE SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFaqs, // Triggers the filter every time a letter is typed
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search for answers...',
                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: subTextColor),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear, color: subTextColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterFaqs('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: maroonAccent, width: 1.5)),
              ),
            ),
          ),
          
          // 🔥 THE DYNAMIC FAQ LIST
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: borderColor),
                        const SizedBox(height: 16),
                        Text("No results found for '${_searchController.text}'", style: TextStyle(color: subTextColor, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: maroonAccent,
                            collapsedIconColor: subTextColor,
                            title: Text(
                              _filteredFaqs[index]['question']!,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  _filteredFaqs[index]['answer']!,
                                  style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}