import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyDio1lwcPDj7NE61Eha7miy1oyGihfMNX0';
  
  print('Listing models...');
  var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  var response = await http.get(url);
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
