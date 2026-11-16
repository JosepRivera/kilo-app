import 'package:flutter/foundation.dart';

String apiBaseUrl() {
  const configured = String.fromEnvironment('API_URL');
  if (configured.isNotEmpty) return configured;
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3001'
      : 'http://localhost:3001';
}
