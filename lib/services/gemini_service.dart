import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_keys.dart';

class GeminiService {
  static Future<String> classifyCase(String description) async {
    final apiKey = ApiKeys.geminiApiKey;

    final prompt =
        """
Classify the following legal case into one category only from this list:
[Criminal Law, Family Law, Civil Law, Commercial Law, Labor Law]

Return ONLY the category name.

Case:
$description
""";

    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    final data = jsonDecode(response.body);

    return data["candidates"][0]["content"]["parts"][0]["text"].trim();
  }
}
