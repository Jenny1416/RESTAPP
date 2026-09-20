import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _androidEnvBaseUrl = String.fromEnvironment(
    'ANDROID_API_BASE_URL',
  );

  static String get baseUrl {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _androidEnvBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_androidEnvBaseUrl);
    }

    if (_envBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is required. Define it with --dart-define-from-file=.env.',
      );
    }

    return _withoutTrailingSlash(_envBaseUrl);
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
