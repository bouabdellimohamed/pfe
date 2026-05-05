import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// ✅ ويدجت موحد لعرض صورة الملف الشخصي (Base64 أو initials أو أيقونة افتراضية)
class ProfileAvatar extends StatelessWidget {
  final String? imageBase64;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Widget? badge; // optional badge overlay (e.g., camera icon)

  const ProfileAvatar({
    super.key,
    this.imageBase64,
    this.name,
    this.size = 80,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.5,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.3),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: _buildContent(),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: badge!,
          ),
      ],
    );
  }

  Widget _buildContent() {
    // ✅ أولاً: محاولة عرض الصورة من Base64
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          width: size,
          height: size,
          gaplessPlayback: true, // يمنع الوميض عند التحديث
          errorBuilder: (_, __, ___) => _buildInitials(),
        );
      } catch (_) {
        return _buildInitials();
      }
    }
    return _buildInitials();
  }

  /// ✅ عرض الحروف الأولى من الاسم
  Widget _buildInitials() {
    if (name != null && name!.trim().isNotEmpty) {
      final initials = name!
          .trim()
          .split(' ')
          .where((e) => e.isNotEmpty)
          .map((e) => e[0])
          .take(2)
          .join()
          .toUpperCase();
      return Container(
        color: backgroundColor ?? const Color(0xFF1565C0),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );
    }
    // ✅ أيقونة افتراضية إذا لم يكن هناك اسم ولا صورة
    return Container(
      color: backgroundColor ?? Colors.grey.shade300,
      child: Icon(Icons.person_rounded, size: size * 0.5, color: Colors.grey.shade600),
    );
  }
}
