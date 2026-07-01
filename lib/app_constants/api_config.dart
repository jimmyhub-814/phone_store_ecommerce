import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get googlePrivateKeyId =>
      dotenv.env['GOOGLE_PRIVATE_KEY_ID'] ?? '';

  static String get googleMapPrivateKey =>
      dotenv.env['GOOGLE_MAP_PRIVATE_KEY_ID'] ?? '';

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
