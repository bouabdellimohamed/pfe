import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_keys.dart';

class GeminiService {
  static Future<String> generateLegalAdvice(String problem) async {
    final apiKey = ApiKeys.geminiApiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
    );

    final prompt = """
Act as an expert Algerian lawyer. Provide legal advice for the following problem in Arabic:
$problem

Focus on:
1. Relevant Algerian laws.
2. Practical steps the user should take.
3. Keep it professional and empathetic.
""";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"].trim();
    } else {
      throw Exception('Failed to generate advice: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> validateContentSafety(String text) async {
    if (text.trim().isEmpty) return {'isSafe': true, 'reason': ''};
    
    final apiKey = ApiKeys.geminiApiKey;

    final prompt = """
Analyze the following text for a professional legal application. 
Determine if the content is ethical, professional, and safe.

CRITICAL REQUIREMENT: You must be EXTREMELY STRICT and uncompromising.
Flag the content as UNSAFE (isSafe: false) if it contains ANY of the following in ANY language (English, Arabic, French, etc.):

1. Profanity, insults, swearing, or abusive language. This includes:
   - Direct insults (e.g., 'you are a ...').
   - Common swear words in English (e.g., f-word, s-word, etc.), Arabic (e.g., Sab, Shatm), or French.
   - Slang insults or offensive metaphors.
2. Extremism, radical ideologies, or promotion of terrorism/violence.
3. Hate speech, discrimination, or racism.
4. Incitement to violence, illegal acts, or self-harm.
5. Harassment, bullying, or highly offensive language.

Text to analyze:
$text

Return ONLY a JSON object in this format:
{"isSafe": true/false, "reason": "A very brief explanation in Arabic why it was rejected (e.g., 'يحتوي على لغة بذيئة أو سب')"}
""";

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
      );
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data["candidates"] != null && 
            data["candidates"].isNotEmpty && 
            data["candidates"][0]["content"] != null &&
            data["candidates"][0]["content"]["parts"] != null) {
          
          final parts = data["candidates"][0]["content"]["parts"] as List;
          if (parts.isEmpty) throw Exception("Empty parts");

          String resultText = parts[0]["text"].toString().trim();
          
          final startIndex = resultText.indexOf('{');
          final endIndex = resultText.lastIndexOf('}');
          
          if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
            resultText = resultText.substring(startIndex, endIndex + 1);
            try {
              return jsonDecode(resultText);
            } catch (e) {
              // Fallback parse if JSON is slightly malformed
              bool safe = resultText.toLowerCase().contains('"issafe": true') || 
                          resultText.toLowerCase().contains('"issafe":true');
              return {'isSafe': safe, 'reason': safe ? '' : 'محتوى غير لائق'};
            }
          }
        }
        // If blocked by internal filters
        return {
          'isSafe': false, 
          'reason': 'تم حظر المحتوى تلقائياً لمخالفته معايير الأمان.'
        };
      } else {
        print("Safety check API Error: ${response.statusCode} - ${response.body}");
        return {'isSafe': true, 'reason': ''}; // Technical error: allow to avoid blocking legitimate users
      }
    } catch (e) {
      print("Error validating content safety: $e");
      return {'isSafe': true, 'reason': ''}; // Connection error: allow
    }
  }
}
