import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lawyer Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Requests"),
            Tab(text: "Reviews"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRequests(), _buildReviews()],
      ),
    );
  }

  // 📩 Requests
  Widget _buildRequests() {
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final docs = (snapshot.data?.docs ?? []).toList();
        docs.sort((a, b) {
          final at = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          return (bt?.toDate() ?? DateTime(1970))
              .compareTo(at?.toDate() ?? DateTime(1970));
        });

        if (docs.isEmpty) {
          return const Center(child: Text("No requests yet"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString();
            final description = (data['description'] ?? '').toString();
            final type = (data['type'] ?? '').toString();
            final status = (data['status'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(title.isNotEmpty ? title : '(Sans titre)'),
                subtitle: Text(
                  [
                    if (type.isNotEmpty) type,
                    if (description.isNotEmpty) description,
                    if (status.isNotEmpty) 'Status: $status',
                  ].join('\n'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        _acceptRequest(doc.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        _rejectRequest(doc.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ⭐ Reviews
  Widget _buildReviews() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('lawyerId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No reviews yet"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index];

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("⭐ ${data['rating']}"),
                subtitle: Text(data['comment']),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
      'status': 'closed',
      'acceptedLawyerId': user!.uid,
      'acceptedAt': FieldValue.serverTimestamp(),
      'respondedLawyerIds': FieldValue.arrayUnion([user!.uid]),
    });
  }

  Future<void> _rejectRequest(String requestId) async {
    // Rejection should not close the request globally. We only record that this
    // lawyer has responded/seen it.
    await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
      'respondedLawyerIds': FieldValue.arrayUnion([user!.uid]),
    });
  }
}
