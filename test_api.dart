import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyB2SUOvzXcCD8Qurk7usXgC4Ve5CfGkpHE';
  
  print('Testing gemini-pro...');
  var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');
  var response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {'parts': [{'text': 'Hello'}]}
      ]
    }),
  );
  print('gemini-pro Status: ${response.statusCode}');
  print('gemini-pro Body: ${response.body}\n');

  print('Testing gemini-1.5-flash...');
  url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
  response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {'parts': [{'text': 'Hello'}]}
      ]
    }),
  );
  print('gemini-1.5-flash Status: ${response.statusCode}');
  print('gemini-1.5-flash Body: ${response.body}');
}
