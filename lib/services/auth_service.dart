import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../models/user_model.dart';
import '../models/consultation_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get user => _auth.authStateChanges();

  // ── تسجيل مستخدم عادي ───────────────────────────────────────
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    int? age,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = cred.user!;
      final model = UserModel(
        uid: u.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        age: age,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(u.uid).set(model.toMap());
      await u.updateDisplayName(fullName);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Cet email est déjà utilisé';
      if (e.code == 'weak-password') return 'Mot de passe trop faible (6 min)';
      return 'Erreur: ${e.message}';
    }
  }

  // ── تسجيل الدخول كمستخدم (يرفض المحامين) ───────────────────
  Future<String?> signInAsUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // فحص: هل هو محامي؟
      final lawyerDoc = await _firestore.collection('lawyers').doc(uid).get();
      if (lawyerDoc.exists) {
        await _auth.signOut();
        return 'Ce compte est un compte avocat.\nUtilisez la connexion avocat.';
      }

      // فحص: هل هو user؟
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        return 'Compte introuvable. Veuillez créer un compte.';
      }
      if ((userDoc.data()?['disabled'] ?? false) == true) {
        await _auth.signOut();
        return 'Ce compte est désactivé. Contactez le support.';
      }

      return null; // ✅ نجح
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Aucun utilisateur trouvé';
      if (e.code == 'wrong-password') return 'Mot de passe incorrect';
      if (e.code == 'invalid-credential')
        return 'Email ou mot de passe incorrect';
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  // ── تسجيل الدخول كمحامي (يرفض المستخدمين العاديين) ─────────
  Future<String?> signInAsLawyer({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // فحص: هل هو user عادي؟
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await _auth.signOut();
        return 'Ce compte est un compte utilisateur.\nUtilisez la connexion utilisateur.';
      }

      // فحص: هل هو محامي؟
      final lawyerDoc = await _firestore.collection('lawyers').doc(uid).get();
      if (!lawyerDoc.exists) {
        await _auth.signOut();
        return 'Compte avocat introuvable. Veuillez vous inscrire.';
      }
      if ((lawyerDoc.data()?['disabled'] ?? false) == true) {
        await _auth.signOut();
        return 'Ce compte avocat est désactivé. Contactez le support.';
      }

      return null; // ✅ نجح
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Aucun utilisateur trouvé';
      if (e.code == 'wrong-password') return 'Mot de passe incorrect';
      if (e.code == 'invalid-credential')
        return 'Email ou mot de passe incorrect';
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  // ── تسجيل الدخول العام (للـ WelcomeScreen) ──────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Aucun utilisateur trouvé';
      if (e.code == 'wrong-password') return 'Mot de passe incorrect';
      if (e.code == 'invalid-credential')
        return 'Email ou mot de passe incorrect';
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  // ── جلب بيانات المستخدم ──────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!);
    } catch (_) {}
    return null;
  }

  // ── الاستشارات ───────────────────────────────────────────────
  Future<void> createConsultation({
    required String userId,
    required String userFullName,
    required String type,
    required String question,
  }) async {
    await _firestore.collection('consultations').add({
      'userId': userId,
      'userFullName': userFullName,
      'type': type,
      'question': question,
      'status': 'pending',
      'answer': null,
      'lawyerId': null,
      'lawyerName': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
    });
  }

  Stream<List<ConsultationModel>> getUserConsultations(String userId) {
    return _firestore
        .collection('consultations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(ConsultationModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<ConsultationModel>> getAllConsultations() {
    return _firestore
        .collection('consultations')
        .snapshots()
        .map((s) {
          final list = s.docs.map(ConsultationModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> answerConsultation({
    required String consultationId,
    required String lawyerId,
    required String lawyerName,
    required String answer,
  }) async {
    await _firestore.collection('consultations').doc(consultationId).update({
      'answer': answer,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  // ── الطلبات (Requests) ───────────────────────────────────────
  Future<void> createRequest({
    required String userId,
    required String userFullName,
    required String title,
    required String type,
    required String description,
    String? attachedFileName,
  }) async {
    await _firestore.collection('requests').add({
      'userId': userId,
      'userFullName': userFullName,
      'title': title,
      'type': type,
      'description': description,
      'attachedFileName': attachedFileName,
      'status': 'open',
      'respondedLawyerIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<RequestModel>> getOpenRequests() {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) {
          final list = s.docs.map(RequestModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<RequestModel>> getUserRequests(String userId) {
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(RequestModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> respondToRequest(String requestId, String lawyerId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'respondedLawyerIds': FieldValue.arrayUnion([lawyerId]),
    });
  }

  Future<String> getOrCreateConversationIdForRequest({
    required String requestId,
    required String userId,
    required String lawyerId,
  }) async {
    final existing = await _firestore
        .collection('conversations')
        .where('requestId', isEqualTo: requestId)
        .where('userId', isEqualTo: userId)
        .where('lawyerId', isEqualTo: lawyerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _firestore.collection('conversations').add({
      'requestId': requestId,
      'userId': userId,
      'lawyerId': lawyerId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': null,
      'lastMessageText': null,
    });
    return doc.id;
  }

  // ── تسجيل محامي جديد ─────────────────────────────────────────
  Future<String?> registerLawyer({
    required String email,
    required String password,
    required String name,
    required String speciality,
    String? phone,
    String? city,
    int? experience,
    String? bio,
    required bool isGeneralist,
    String? wilaya,
    String? daira,
    String? commune,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        LawyerModel lawyer = LawyerModel(
          uid: firebaseUser.uid,
          email: email,
          name: name,
          speciality: speciality,
          phone: phone,
          city: city,
          experience: experience,
          bio: bio,
          isGeneralist: isGeneralist,
          wilaya: wilaya,
          daira: daira,
          commune: commune,
        );
        await _firestore
            .collection('lawyers')
            .doc(firebaseUser.uid)
            .set(lawyer.toMap());
        await firebaseUser.updateDisplayName(name);
        await firebaseUser.reload();
        return null;
      }
      return 'Erreur lors de la création du compte';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Cet email est déjà utilisé';
      if (e.code == 'weak-password')
        return 'Mot de passe trop faible (6 caractères min)';
      return 'Erreur: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  // ── تسجيل الخروج ─────────────────────────────────────────────
  Future<void> signOut() async => await _auth.signOut();

  // ── جلب بيانات المحامي ───────────────────────────────────────
  Future<LawyerModel?> getLawyerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('lawyers').doc(uid).get();
      if (doc.exists)
        return LawyerModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Erreur getProfile: $e');
    }
    return null;
  }

  Future<void> updateLawyerProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('lawyers').doc(uid).update(updates);
  }
}
