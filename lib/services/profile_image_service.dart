import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ خدمة موحدة لاختيار وضغط وحفظ صور الملف الشخصي
class ProfileImageService {
  static final _firestore = FirebaseFirestore.instance;

  /// الحد الأقصى لحجم الصورة بعد الضغط (200×200 بيكسل)
  static const int _maxDimension = 200;
  static const int _jpegQuality = 72;

  /// ✅ اختيار صورة من المعرض + ضغطها + تحويلها إلى Base64
  /// يُرجع null إذا ألغى المستخدم أو حدث خطأ
  static Future<String?> pickAndCompressImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
        return null; // المستخدم ألغى الاختيار
      }

      final bytes = result.files.first.bytes!;
      
      // ✅ التحقق من حجم الملف الأصلي (حد أقصى 10 ميغا)
      if (bytes.length > 10 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image trop volumineuse (max 10 Mo)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // ✅ ضغط الصورة
      final compressed = await _compressImage(bytes);
      if (compressed == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format d\'image non supporté'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// ✅ ضغط الصورة إلى 200×200 بيكسل كـ JPEG
  static Future<Uint8List?> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // تصغير الصورة مع الحفاظ على النسبة
      img.Image resized;
      if (image.width > image.height) {
        resized = img.copyResize(image, width: _maxDimension);
      } else {
        resized = img.copyResize(image, height: _maxDimension);
      }

      // قص لتكون مربعة
      final minDim = resized.width < resized.height ? resized.width : resized.height;
      final x = (resized.width - minDim) ~/ 2;
      final y = (resized.height - minDim) ~/ 2;
      final cropped = img.copyCrop(resized, x: x, y: y, width: minDim, height: minDim);

      // ترميز كـ JPEG بجودة منخفضة
      final jpegBytes = img.encodeJpg(cropped, quality: _jpegQuality);
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// ✅ حفظ صورة الملف الشخصي للمستخدم العادي
  static Future<bool> saveUserProfileImage(String uid, String base64Image) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageBase64': base64Image,
      });
      return true;
    } catch (e) {
      debugPrint('Error saving user profile image: $e');
      return false;
    }
  }

  /// ✅ حفظ صورة الملف الشخصي للمحامي
  static Future<bool> saveLawyerProfileImage(String uid, String base64Image) async {
    try {
      await _firestore.collection('lawyers').doc(uid).update({
        'profileImageBase64': base64Image,
      });
      return true;
    } catch (e) {
      debugPrint('Error saving lawyer profile image: $e');
      return false;
    }
  }

  /// ✅ حذف صورة الملف الشخصي
  static Future<bool> removeProfileImage(String uid, {required bool isLawyer}) async {
    try {
      final collection = isLawyer ? 'lawyers' : 'users';
      await _firestore.collection(collection).doc(uid).update({
        'profileImageBase64': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing profile image: $e');
      return false;
    }
  }
}
