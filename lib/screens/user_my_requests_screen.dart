import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/consultation_model.dart';

class UserMyRequestsScreen extends StatelessWidget {
  final String uid;
  const UserMyRequestsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: auth.getUserRequests(uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur lors du chargement de l’historique:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 14),
                Text('Aucune demande publiée',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _RequestCard(r: list[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel r;
  const _RequestCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final open = r.status == 'open';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(r.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14,
                    color: Color(0xFF263238)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: open
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(open ? 'Ouvert' : 'Fermé',
                  style: TextStyle(
                      color: open ? Colors.green : Colors.grey,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(r.type,
              style: const TextStyle(
                  color: Color(0xFF1565C0), fontSize: 12)),
          const SizedBox(height: 6),
          Text(r.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.people_outline_rounded,
                size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${r.respondedLawyerIds.length} réponse(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
