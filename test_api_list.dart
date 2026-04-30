import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyB2SUOvzXcCD8Qurk7usXgC4Ve5CfGkpHE';
  
  print('Listing models...');
  var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  var response = await http.get(url);
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
