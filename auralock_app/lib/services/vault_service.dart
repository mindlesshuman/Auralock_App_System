import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VaultService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'aura_vault_master_key';
  static const _boxName = 'encrypted_authenticator_vault';

  // We will store the external apps as a simple List of Maps for now
  static Future<void> init() async {
    await Hive.initFlutter();

    // 1. Get or create the master encryption key from the phone's Hardware Keystore
    var key = await _storage.read(key: _keyName);
    if (key == null) {
      final secureKey = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(secureKey));
      key = base64UrlEncode(secureKey);
    }

    // 2. Open the encrypted local database using the secure key
    final encryptionKeyUint8List = base64Url.decode(key);
    await Hive.openBox(
      _boxName,
      encryptionKey: encryptionKeyUint8List,
    );
    print("AuraLock: Offline Encrypted Vault Initialized.");
  }

  // Quick access to the vault anywhere in the app
  static Box get box => Hive.box(_boxName);
}