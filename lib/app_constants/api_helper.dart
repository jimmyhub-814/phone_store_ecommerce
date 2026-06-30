import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:phone_store/app_constants/api_config.dart'; 

class ApiHelper {
  Future<String> sendMsgApi({required String msg}) async {
    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${ApiConfig.geminiApiKey}",
      );
      final response = await http.post(
      url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": msg}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        print(response.body);
        return '';
      }

      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    } catch (e) {
      print(e);
      return '';
    }
  }
}
