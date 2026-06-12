import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; 

// 🔥 1. Import the new Splash Screen instead of LoginScreen
import 'screens/splash_screen.dart'; 
import 'services/vault_service.dart'; 

void main() async {
  
  // 🔥 2. Required for Flutter to use native channels before the UI draws
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 🔥 3. Boot up the Encrypted Offline Vault
  await VaultService.init();

  // 🔥 4. Boot up the Firebase Engine
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await GoogleSignIn.instance.initialize();
  
  runApp(const AuraLockApp());
}

class AuraLockApp extends StatelessWidget {
  const AuraLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraLock',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9E1A1A)),
        useMaterial3: true,
      ),
      // 🔥 5. Route the app to the Splash Screen first!
      home: const SplashScreen(),
    );
  }
}