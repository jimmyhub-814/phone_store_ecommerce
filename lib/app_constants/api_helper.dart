import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:phone_store/app_constants/api_config.dart'; 

class ApiHelper {
  Future<String> sendMsgApi({required String msg}) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.geminiBaseUrl}?key=${ApiConfig.geminiApiKey}"),
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
