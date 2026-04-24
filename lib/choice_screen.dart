import 'package:flutter/material.dart';
import 'screens/direct_search_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment chercher ?'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Titre
            const Text(
              'Comment souhaitez-vous\nchercher un avocat ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Option 1 : Recherche directe
            _buildOptionCard(
              context,
              icon: Icons.search,
              title: 'Je connais la catégorie',
              subtitle: 'Recherche par spécialité juridique',
              color: Colors.blue,
              onTap: () {
                debugPrint('Option 1 sélectionnée');
                // On ira vers la recherche directe
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DirectSearchScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Option 2 : Questionnaire
            _buildOptionCard(
              context,
              icon: Icons.help_outline,
              title: 'Je ne sais pas',
              subtitle: 'Questionnaire guidé pour identifier votre besoin',
              color: Colors.green,
              onTap: () {
                debugPrint('Option 2 sélectionnée');
                // On ira vers le questionnaire (AI لاحقاً)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Flèche
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
