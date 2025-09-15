import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AppConfig {
  late final String apiUrl;
  late final String apiBinId;

  AppConfig._({required this.apiUrl, required this.apiBinId});

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception("Configuração não foi carregada! Chame AppConfig.load() primeiro.");
    }
    return _instance!;
  }

  static Future<void> load() async {
    if (_instance != null) return;

    String apiUrlValue;
    String apiBinIdValue;

    if (kDebugMode) {
      // Modo Debug: Carrega do arquivo .env local
      await dotenv.load(fileName: ".env");
      apiUrlValue = dotenv.env['FLUTTER_API_URL_PROD']!;
      apiBinIdValue = dotenv.env['FLUTTER_API_BIN_ID_PROD']!;
    
    } else {
      // Modo Release: Carrega das variáveis injetadas pelo CI/CD do GitLab
      apiUrlValue = const String.fromEnvironment('FLUTTER_API_URL_PROD');
      apiBinIdValue = const String.fromEnvironment('FLUTTER_API_BIN_ID_PROD');
    }

    _instance = AppConfig._(apiUrl: apiUrlValue, apiBinId: apiBinIdValue);
  }
}