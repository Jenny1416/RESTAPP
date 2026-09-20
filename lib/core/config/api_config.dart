import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String localBaseUrl = 'http://localhost:3000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:3000';
  static const String universityBaseUrl = 'http://179.197.239.216:3000';
  static const String testBaseUrl = 'https://api-test.restapp.site';
  static const String productionBaseUrl = 'https://api.restapp.site';

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _apiEnvironment = String.fromEnvironment('API_ENV');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_envBaseUrl);
    }

    switch (_apiEnvironment) {
      case 'test':
        return testBaseUrl;
      case 'production':
        return productionBaseUrl;
      case 'university':
        return universityBaseUrl;
      case 'local':
      case '':
        return _localBaseUrl;
      default:
        throw StateError(
          'API_ENV must be local, test, production or university',
        );
    }
  }

  static String get _localBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorBaseUrl;
    }
    return localBaseUrl;
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
