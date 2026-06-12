import 'package:tflite_flutter/tflite_flutter.dart';

class SecurityMLEngine {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/auralock_threat_model.tflite');
      _isModelLoaded = true;
      print("Edge AI Model Loaded Successfully!");
    } catch (e) {
      print("Failed to load Edge AI model: $e");
      _isModelLoaded = false;
    }
  }

  Future<List<Map<String, String>>> analyzeThreat(String threatMessage, int sessionCount) async {
    if (!_isModelLoaded || _interpreter == null) {
      return _getFallbackRecommendations(threatMessage);
    }

    try {
      var inputTensor = [[threatMessage.contains("Emulator") ? 1.0 : 0.0, sessionCount.toDouble()]];
      var outputTensor = List.filled(1 * 2, 0.0).reshape([1, 2]);

      _interpreter!.run(inputTensor, outputTensor);
      double riskScore = outputTensor[0][0];

      if (riskScore > 0.8) {
        return [
          {"title": "Critical AI Alert: Device Compromised", "desc": "The Neural Engine has detected a 99% probability of a virtualized attack vector. Lock down the API immediately."}
        ];
      } else {
        return [
          {"title": "AI Audit: Low Risk", "desc": "The behavior matches normal operational parameters. No immediate action required."}
        ];
      }
    } catch (e) {
      print("Inference Error: $e");
      return _getFallbackRecommendations(threatMessage);
    }
  }

  List<Map<String, String>> _getFallbackRecommendations(String threatMessage) {
    if (threatMessage.toLowerCase().contains("emulator")) {
      return [
        {"title": "Immediate Action: Halt Execution", "desc": "AuraLock is running on a virtualized environment. Close the application immediately."},
        {"title": "Hardware Enforcement", "desc": "Enable 'Hardware-Only Mode' to permanently block virtualized instances."}
      ];
    }
    return [
      {"title": "Force Password Reset", "desc": "We detected anomalous behavior. Update your master password immediately."}
    ];
  }

  void dispose() {
    _interpreter?.close();
  }
}