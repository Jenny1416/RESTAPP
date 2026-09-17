import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String testBaseUrl = 'https://api-test.restapp.site';
  static const String productionBaseUrl = 'https://api.restapp.site';

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _apiEnvironment = String.fromEnvironment('API_ENV');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_envBaseUrl);
    }

    switch (_apiEnvironment) {
      case 'production':
        return productionBaseUrl;
      case 'test':
        return testBaseUrl;
      case '':
        return kReleaseMode
            ? productionBaseUrl
            : testBaseUrl;
      default:
        throw StateError('API_ENV must be test or production');
    }
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
