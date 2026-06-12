import 'package:flutter/material.dart';

// ==========================================
// 1. THE APP ICON (Using your custom PNG)
// ==========================================
class AuraAppIcon extends StatelessWidget {
  final double size;
  
  const AuraAppIcon({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // 🔥 This line imports your custom picture
      child: Image.asset(
        'assets/icons/app_icon.png', 
        fit: BoxFit.contain,
      ),
    );
  }
}

// ==========================================
// 2. THE AI ICON (Using your custom GIF)
// ==========================================
class AuraAiIcon extends StatelessWidget {
  final double size;
  
  const AuraAiIcon({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // 🔥 Flutter will automatically play the GIF!
      child: Image.asset(
        'assets/icons/ai_icon.gif', 
        fit: BoxFit.contain,
      ),
    );
  }
}

// ==========================================
// 3. THE USER PROFILE ICON (Image with Fallback)
// ==========================================
class AuraProfileIcon extends StatelessWidget {
  final double size;
  final String? customImagePath; // If they upload a custom picture
  final String initial;

  const AuraProfileIcon({
    super.key, 
    this.size = 50, 
    this.customImagePath,
    this.initial = "?", 
  });

  @override
  Widget build(BuildContext context) {
    // If they have a custom image, use it. Otherwise, use your default design.
    final ImageProvider imageProvider = customImagePath != null 
        ? AssetImage(customImagePath!) 
        : const AssetImage('assets/icons/default_profile.png');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Main Avatar Picture
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.2), width: size * 0.04),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // The Verification Badge overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488), // Safe Accent Green
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A1128), width: size * 0.04), 
              ),
              child: Center(
                child: Icon(Icons.check, color: Colors.white, size: size * 0.22, weight: 800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}