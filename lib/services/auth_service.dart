import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/lawyer_model.dart';
import '../models/user_model.dart';
import '../models/consultation_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get user => _auth.authStateChanges();

  // ── تسجيل مستخدم عادي ───────────────────────────────────────
  // ✅ لا نحفظ في Firestore هنا — نؤجل الحفظ لأول تسجيل دخول ناجح بعد تأكيد الإيميل
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

      // نحفظ البيانات مؤقتاً في displayName كـ JSON — تُستخدم عند أول دخول ناجح
      final pendingData = jsonEncode({
        'fullName': fullName,
        'phone': phone,
        'age': age,
      });
      await u.updateDisplayName(pendingData);
      await u.sendEmailVerification();
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Cet email est déjà utilisé';
      if (e.code == 'weak-password') return 'Mot de passe trop faible (6 min)';
      return 'Erreur: ${e.message ?? e.code}';
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

      // ✅ يجب تأكيد الإيميل قبل أي شيء آخر
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return 'Veuillez vérifier votre email en cliquant sur le lien reçu.';
      }

      // ✅ أول دخول ناجح بعد تأكيد الإيميل — ننشئ وثيقة Firestore الآن
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        // نقرأ البيانات المحفوظة مؤقتاً في displayName
        Map<String, dynamic> pending = {};
        try {
          final dn = cred.user!.displayName ?? '{}';
          pending = jsonDecode(dn) as Map<String, dynamic>;
        } catch (_) {}

        final model = UserModel(
          uid: uid,
          fullName: pending['fullName'] ?? cred.user!.displayName ?? '',
          email: cred.user!.email ?? email,
          phone: pending['phone'] as String?,
          age: pending['age'] as int?,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(uid).set(model.toMap());

        // نحدّث displayName ليكون الاسم الحقيقي (بدل JSON)
        await cred.user!.updateDisplayName(model.fullName);
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

      // ✅ إصلاح خطأ #2: فحص وجود حساب المحامي أولاً — رسائل الخطأ ستكون دقيقة
      final lawyerDoc = await _firestore.collection('lawyers').doc(uid).get();
      if (!lawyerDoc.exists) {
        // نفحص هل هو user عادي لإعطاء رسالة أوضح
        final userDoc = await _firestore.collection('users').doc(uid).get();
        await _auth.signOut();
        if (userDoc.exists) {
          return 'Ce compte est un compte utilisateur.\nUtilisez la connexion utilisateur.';
        }
        return 'Compte avocat introuvable. Veuillez vous inscrire.';
      }

      // ✅ الحساب موجود — الآن نتحقق من الإيميل (الرسالة ستكون منطقية)
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return 'Veuillez vérifier votre email en cliquant sur le lien reçu.';
      }
      // ✅ فحص حالة الطلب
      final status = lawyerDoc.data()?['status'] ?? 'approved';
      if (status == 'pending') {
        await _auth.signOut();
        return 'Votre demande est en cours d\'examen.\nVous pourrez vous connecter dès que l\'administrateur aura approuvé votre dossier.';
      }
      if (status == 'rejected') {
        await _auth.signOut();
        return 'Votre demande a été refusée.\nContactez l\'administrateur pour plus d\'informations.';
      }
      if ((lawyerDoc.data()?['disabled'] ?? false) == true) {
        await _auth.signOut();
        return 'Ce compte avocat est désactivé. Contactez le support.';
      }

      // ✅ تحديث emailVerified في Firestore عند أول دخول ناجح
      if ((lawyerDoc.data()?['emailVerified'] ?? true) == false) {
        await _firestore.collection('lawyers').doc(uid).update({'emailVerified': true});
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
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      final uid = cred.user!.uid;

      // لا نسمح للمحامي بالدخول عبر مدخل المستخدم
      final lawyerDoc = await _firestore.collection('lawyers').doc(uid).get();
      if (lawyerDoc.exists) {
        await _auth.signOut();
        return 'Ce compte est un compte avocat.\nUtilisez la connexion avocat.';
      }

      // ✅ تأكيد الإيميل أولاً قبل أي فحص Firestore
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return 'Veuillez vérifier votre email en cliquant sur le lien reçu.';
      }

      // ✅ أول دخول ناجح — ننشئ وثيقة Firestore إذا لم تكن موجودة
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        Map<String, dynamic> pending = {};
        try {
          final dn = cred.user!.displayName ?? '{}';
          pending = jsonDecode(dn) as Map<String, dynamic>;
        } catch (_) {}

        final model = UserModel(
          uid: uid,
          fullName: pending['fullName'] ?? '',
          email: cred.user!.email ?? email,
          phone: pending['phone'] as String?,
          age: pending['age'] as int?,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(uid).set(model.toMap());
        await cred.user!.updateDisplayName(model.fullName);
      }

      if ((userDoc.data()?['disabled'] ?? false) == true) {
        await _auth.signOut();
        return 'Ce compte est désactivé. Contactez le support.';
      }

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

  // ── الحصول على دور المستخدم ───────────────────────────────
  Future<String> getUserRole(String uid) async {
    try {
      // فحص إذا كان admin
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) return 'admin';

      // فحص إذا كان lawyer
      final lawyerDoc = await _firestore.collection('lawyers').doc(uid).get();
      if (lawyerDoc.exists) return 'lawyer';

      // إذا كان user عادي
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) return userDoc.data()?['role'] ?? 'user';
    } catch (_) {}
    return 'user';
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
    return _firestore.collection('consultations').snapshots().map((s) {
      final list = s.docs.map(ConsultationModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── الاستشارات المشتركة — تُظهر استشارات الآخرين فقط (ليس استشاراته هو)
  Stream<List<ConsultationModel>> getOtherUsersConsultations(String userId) {
    return _firestore
        .collection('consultations')
        .snapshots()
        .map((s) {
      // ✅ نفلتر في الكود: لا يرى استشاراته الخاصة
      // ملاحظة: المستخدم العادي لا يمكنه الإجابة على استشارات، لذا شرط lawyerId != userId
      // كان عديم المعنى للمستخدمين العاديين. نكتفي بإخفاء استشاراته الشخصية.
      final list = s.docs
          .map(ConsultationModel.fromFirestore)
          .where((c) => c.userId != userId)
          .toList();
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
    // ✅ زيادة activityPoints عند الرد على استشارة (+5)
    await _updateLawyerActivity(lawyerId, activityDelta: 5);
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

  // ✅ يجلب الطلبات المتوافقة مع تخصصات المحامي فقط
  Stream<List<RequestModel>> getOpenRequests({List<String>? lawyerSpecialities}) {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) {
      var list = s.docs.map(RequestModel.fromFirestore).toList();

      // فلترة بالتخصص إذا توفرت قائمة تخصصات المحامي
      if (lawyerSpecialities != null && lawyerSpecialities.isNotEmpty) {
        list = list.where((r) {
          final reqType = r.type.toLowerCase().trim();
          return lawyerSpecialities.any((spec) =>
              spec.toLowerCase().trim() == reqType ||
              reqType.contains(spec.toLowerCase().trim()) ||
              spec.toLowerCase().trim().contains(reqType));
        }).toList();
      }

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
    // ✅ زيادة activityPoints عند قبول طلب (+3)
    await _updateLawyerActivity(lawyerId, activityDelta: 3);
  }

  // ── تحديث نقاط النشاط وإعادة حساب finalScore ──────────────────
  Future<void> _updateLawyerActivity(String lawyerId, {required int activityDelta}) async {
    try {
      final doc = await _firestore.collection('lawyers').doc(lawyerId).get();
      if (!doc.exists) return;
      final d = doc.data()!;

      final newActivity = ((d['activityPoints'] ?? 0) as int) + activityDelta;
      final clampedActivity = newActivity.clamp(0, 100);

      // ✅ responseRate = طلبات ردّ عليها ÷ (ردّ عليها + مفتوحة لم يردّ عليها بعد)
      // هذا يعكس نسبة الاستجابة الحقيقية: كم طلباً متاحاً ردّ عليه المحامي
      final respondedRequests = await _firestore.collection('requests')
          .where('respondedLawyerIds', arrayContains: lawyerId).get();
      final openNotRespondedRequests = await _firestore.collection('requests')
          .where('status', isEqualTo: 'open').get();

      // الطلبات المفتوحة التي لم يردّ عليها بعد
      final openNotResponded = openNotRespondedRequests.docs
          .where((doc) {
            final ids = List<String>.from(doc.data()['respondedLawyerIds'] ?? []);
            return !ids.contains(lawyerId);
          })
          .length;

      final respondedCount = respondedRequests.docs.length;
      final totalCount = respondedCount + openNotResponded;
      final responseRate = totalCount > 0
          ? (respondedCount / totalCount).clamp(0.0, 1.0)
          : 0.0;

      // إعادة حساب finalScore
      final rating = (d['rating'] ?? 0.0).toDouble();
      final reviewCount = (d['reviewCount'] ?? 0) as int;
      final experience = (d['experience'] ?? 0) as int;

      final ratingScore   = (rating / 5.0) * 35;
      final expScore      = (experience.clamp(0, 20) / 20.0) * 25;
      final reviewScore   = (reviewCount.clamp(0, 50) / 50.0) * 10;
      final activityScore = (clampedActivity / 100.0) * 20;
      final responseScore = responseRate * 10;
      final newScore = double.parse(
          (ratingScore + expScore + reviewScore + activityScore + responseScore).toStringAsFixed(1));

      await _firestore.collection('lawyers').doc(lawyerId).update({
        'activityPoints': clampedActivity,
        'responseRate': double.parse(responseRate.toStringAsFixed(3)),
        'finalScore': newScore,
      });
    } catch (e) {
      debugPrint('Error updating lawyer activity: $e');
    }
  }

  Future<String> getOrCreateConversationIdForRequest({
    required String requestId,
    required String userId,
    required String lawyerId,
  }) async {
    // ✅ نتحقق أولاً إذا كان هناك شات بين هذا المستخدم وهذا المحامي (بأي requestId)
    final existing = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .where('lawyerId', isEqualTo: lawyerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // لا يوجد شات → ننشئ واحداً جديداً مع حفظ أسماء الطرفين
    // جلب اسم المستخدم العادي لحفظه في المحادثة
    String userName = '';
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        userName = (data['fullName'] ?? data['name'] ?? '').toString();
      }
    } catch (_) {}

    // جلب اسم المحامي لحفظه في المحادثة
    String lawyerName = '';
    try {
      final lawyerDoc = await _firestore.collection('lawyers').doc(lawyerId).get();
      if (lawyerDoc.exists) {
        final data = lawyerDoc.data() as Map<String, dynamic>? ?? {};
        lawyerName = (data['name'] ?? '').toString();
      }
    } catch (_) {}

    final doc = await _firestore.collection('conversations').add({
      'requestId': requestId,
      'userId': userId,
      'lawyerId': lawyerId,
      'userName': userName,
      'lawyerName': lawyerName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': null,
      'lastMessageText': null,
    });
    return doc.id;
  }

  // ── تسجيل محامي جديد (مع وثيقة + انتظار موافقة الأدمين) ────
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
    Uint8List? documentBytes,
    String? documentName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // ── رفع الوثيقة إلى Firebase Storage ──
        String? documentUrl;
        int? totalChunks;
        String? base64String;

        if (documentBytes != null && documentName != null) {
          try {
            final ext = documentName.contains('.')
                ? documentName.split('.').last.toLowerCase()
                : 'pdf';
            final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
            
            base64String = base64Encode(documentBytes);
            // 800KB per chunk to stay well under the 1MB limit
            final int chunkSize = 800000;
            totalChunks = (base64String.length / chunkSize).ceil();
            
            if (totalChunks > 1) {
              documentUrl = 'chunked:$mimeType:$totalChunks';
            } else {
              documentUrl = 'data:$mimeType;base64,$base64String';
            }

          } catch (e) {
            await firebaseUser.delete();
            await _auth.signOut();
            return 'Erreur lors de la préparation du fichier.';
          }
        }

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
        final expScore = ((experience ?? 0).clamp(0, 20) / 20.0) * 25;
        final initialScore = double.parse(expScore.toStringAsFixed(1));
        await _firestore.collection('lawyers').doc(firebaseUser.uid).set({
          ...lawyer.toMap(),
          'finalScore': initialScore,
          'status': 'pending',        // ✅ في انتظار موافقة الأدمين
          'documentUrl': documentUrl, // ✅ رابط الوثيقة
          'createdAt': FieldValue.serverTimestamp(), // ✅ مرة واحدة فقط عند الإنشاء
          'emailVerified': false, // ✅ يُحدَّث عند أول تسجيل دخول ناجح
        });

        // ✅ حفظ الأجزاء (Chunks) إذا كان الملف كبيراً
        if (documentUrl != null && documentUrl.startsWith('chunked:') && base64String != null && totalChunks != null) {
          final int chunkSize = 800000;
          for (int i = 0; i < totalChunks; i++) {
            int start = i * chunkSize;
            int end = (i + 1) * chunkSize;
            if (end > base64String.length) end = base64String.length;
            
            String chunkData = base64String.substring(start, end);
            await _firestore.collection('lawyers')
              .doc(firebaseUser.uid)
              .collection('document_chunks')
              .doc('chunk_$i')
              .set({'data': chunkData});
          }
        }

        await firebaseUser.updateDisplayName(name);
        // ✅ إرسال رسالة تفعيل الإيميل للمحامي بعد رفع الوثيقة وإنشاء الحساب
        await firebaseUser.sendEmailVerification();
        await _auth.signOut();
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

  // ── إعادة إرسال رابط التحقق ──────────────────────────────────
  Future<String?> resendVerificationEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        await _auth.signOut();
        return null;
      }
      return "L'email est déjà vérifié.";
    } catch (e) {
      return e.toString();
    }
  }

  // ── جلب بيانات المحامي ───────────────────────────────────────
  Future<LawyerModel?> getLawyerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('lawyers').doc(uid).get();
      if (doc.exists)
        return LawyerModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Erreur getProfile: $e');
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
