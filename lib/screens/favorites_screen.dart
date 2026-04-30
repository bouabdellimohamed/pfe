import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lawyer_model.dart';
import '../services/favorites_service.dart';
import '../widgets/profile_avatar.dart';
import '../theme/app_theme.dart';
import 'lawyer_profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FavoritesService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Avocats sauvegardés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: 'Info',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Appuyez longuement sur une carte pour retirer des favoris')),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LawyerModel>>(
        stream: service.watchFavorites(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final lawyers = snap.data ?? [];

          if (lawyers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          size: 44, color: Colors.amber),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun avocat sauvegardé',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consultez les profils d\'avocats et appuyez sur ♡ pour les sauvegarder ici.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lawyers.length,
            itemBuilder: (_, i) {
              final lawyer = lawyers[i];
              return _FavoriteLawyerCard(
                lawyer: lawyer,
                service: service,
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteLawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  final FavoritesService service;

  const _FavoriteLawyerCard(
      {required this.lawyer, required this.service});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(lawyer.uid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_remove_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Retirer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        service.removeFavorite(lawyer.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lawyer.name} retiré des favoris'),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () => service.addFavorite(lawyer.uid),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LawyerProfileScreen(lawyer: lawyer)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              ProfileAvatar(
                imageBase64: lawyer.profileImageBase64,
                name: lawyer.name,
                size: 58,
                borderColor: AppColors.grey200,
                borderWidth: 1,
                backgroundColor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lawyer.speciality,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.grey400),
                        const SizedBox(width: 3),
                        Text(lawyer.wilaya ?? 'Algérie',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded,
                            size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          lawyer.rating > 0
                              ? lawyer.rating.toStringAsFixed(1)
                              : 'Nouveau',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bookmark icon
              const Icon(Icons.bookmark_rounded,
                  color: Colors.amber, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
