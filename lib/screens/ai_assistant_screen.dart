// 👇 نفس الكود تبعك لكن محسّن
import 'package:flutter/material.dart';
import 'lawyers_result_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;
  String? _result;

  final String _apikey = "AIzaSyDvo7vQ-oBb_cNM0jyYCLOoI43dny0YobY";

  final List<String> allowed = [
    "Droit familial",
    "Droit pénal",
    "Droit commercial",
    "Droit civil",
    "Droit immobilier",
    "Droit administratif",
    "Droit du travail",
  ];

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color lightBlueBg = const Color(0xFFE3F2FD);
  final Color greyText = const Color(0xFF757575);
  final Color darkText = const Color(0xFF263238);

  // 🤖 Gemini
  Future<void> _analyzeWithGemini() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("اكتبي وصف القضية أولًا")));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apikey",
      );

      final prompt =
          """
Tu es un expert juridique algérien.

Analyse cette situation et retourne UNIQUEMENT un mot EXACT parmi cette liste:

[Droit familial, Droit pénal, Droit commercial, Droit civil, Droit immobilier, Droit administratif, Droit du travail]

Ne donne aucune phrase.

Situation:
${_controller.text}
""";

      final response = await http.post(
        url,
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

      print(response.body);

      final data = jsonDecode(response.body);

      print("FULL RESPONSE: $data");

      if (data["error"] != null) {
        throw Exception(data["error"]["message"]);
      }

      if (data["candidates"] == null || data["candidates"].isEmpty) {
        throw Exception("No candidates returned");
      }

      final candidates = data["candidates"];
      final content = candidates[0]["content"];
      final parts = content["parts"];

      if (parts == null || parts.isEmpty) {
        throw Exception("No text returned from AI");
      }

      String result = parts[0]["text"];

      result = result.replaceAll('.', '').replaceAll('\n', '').trim();

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        _result = "Erreur: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Assistant IA",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightBlueBg.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 50,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Décrivez votre situation",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Notre intelligence artificielle va analyser votre texte.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyText, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildInputSection(),
            const SizedBox(height: 30),

            // 🔥 زر التحليل (مع تعطيل وقت اللود)
            GestureDetector(
              onTap: _isLoading ? null : _analyzeWithGemini,
              child: _buildAnalyzeOptionCard(),
            ),

            const SizedBox(height: 40),

            if (_isLoading)
              CircularProgressIndicator(color: primaryBlue)
            else if (_result != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _controller,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: "Ex: J'ai un problème avec mon employeur...",
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildAnalyzeOptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analyser ma situation",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF263238),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Lancer l'intelligence artificielle",
                  style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Catégorie Identifiée :",
            style: TextStyle(
              color: greyText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _result!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 25),

          // 🔗 زر المحامين
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                if (_result != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LawyersResultScreen(speciality: _result!),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: BorderSide(color: primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Voir les avocats recommandés",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
