import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyB2SUOvzXcCD8Qurk7usXgC4Ve5CfGkpHE';
  
  var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  var response = await http.get(url);
  var data = jsonDecode(response.body);
  
  for (var model in data['models']) {
    if (model['name'].contains('gemini') && (model['supportedGenerationMethods']?.contains('generateContent') ?? false)) {
      print(model['name']);
    }
  }
}
