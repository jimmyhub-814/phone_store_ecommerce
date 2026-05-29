
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get googlePrivateKeyId =>
      dotenv.env['GOOGLE_PRIVATE_KEY_ID'] ?? '';

  static String get googlePrivateKey => dotenv.env['GOOGLE_PRIVATE_KEY'] ?? '';

  static String get geminiBaseUrl => dotenv.env['GEMINI_BASE_URL'] ?? '';
 
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
