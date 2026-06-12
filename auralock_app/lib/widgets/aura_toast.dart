import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuraToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const AuraToast({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<AuraToast> createState() => _AuraToastState();

  // 🔥 THE TRIGGER FUNCTION 🔥
  static void show({
    required BuildContext context,
    required String title,
    String message = "",
    IconData icon = Icons.check_circle,
    Color color = const Color(0xFF0D9488), // Safe Accent Green
  }) {
    // Subtle physical vibration
    HapticFeedback.lightImpact(); 
    
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // Safely below the status bar
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: AuraToast(
            title: title,
            message: message,
            icon: icon,
            color: color,
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _AuraToastState extends State<AuraToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    // Smooth fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    // Premium slight drop-down bounce effect
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // Perfect pill shape
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Glassmorphism blur
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1128).withOpacity(0.75), // Deep dark translucent background
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1), // Subtle glass rim
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3)),
                        if (widget.message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(widget.message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}