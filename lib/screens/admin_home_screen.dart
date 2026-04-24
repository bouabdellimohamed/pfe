import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Lawyers'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            _LawyersTab(),
            _RequestsTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const Center(child: Text('No users.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['fullName'] ?? '').toString();
            final email = (d['email'] ?? '').toString();
            final disabled = (d['disabled'] ?? false) == true;
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tileColor: Colors.white,
              title: Text(name.isNotEmpty ? name : doc.id),
              subtitle: Text(email),
              trailing: Switch(
                value: disabled,
                onChanged: (v) => FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .update({'disabled': v}),
              ),
            );
          },
        );
      },
    );
  }
}

class _LawyersTab extends StatelessWidget {
  const _LawyersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lawyers').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const Center(child: Text('No lawyers.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['name'] ?? '').toString();
            final email = (d['email'] ?? '').toString();
            final speciality = (d['speciality'] ?? '').toString();
            final disabled = (d['disabled'] ?? false) == true;
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tileColor: Colors.white,
              title: Text(name.isNotEmpty ? name : doc.id),
              subtitle: Text([email, speciality].where((s) => s.isNotEmpty).join(' • ')),
              trailing: Switch(
                value: disabled,
                onChanged: (v) => FirebaseFirestore.instance
                    .collection('lawyers')
                    .doc(doc.id)
                    .update({'disabled': v}),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur: ${snap.error}'));
        }
        final docs = (snap.data?.docs ?? const []).toList();
        docs.sort((a, b) {
          final at = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          return (bt?.toDate() ?? DateTime(1970))
              .compareTo(at?.toDate() ?? DateTime(1970));
        });
        if (docs.isEmpty) return const Center(child: Text('No requests.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final title = (d['title'] ?? '').toString();
            final status = (d['status'] ?? 'open').toString();
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tileColor: Colors.white,
              title: Text(title.isNotEmpty ? title : doc.id),
              subtitle: Text('Status: $status'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => FirebaseFirestore.instance
                        .collection('requests')
                        .doc(doc.id)
                        .update({'status': 'open'}),
                    child: const Text('Open'),
                  ),
                  ElevatedButton(
                    onPressed: () => FirebaseFirestore.instance
                        .collection('requests')
                        .doc(doc.id)
                        .update({'status': 'closed'}),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

