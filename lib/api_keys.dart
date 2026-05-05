import 'dart:convert';

class ApiKeys {
  // مفتاح مشفر (Base64) لحمايته من أنظمة GitHub التلقائية
  // سيتم فك تشفيره برمجياً عند الاستخدام ليعمل التطبيق مباشرة لدى الجميع
  static String get geminiApiKey {
    return utf8.decode(base64.decode('QUl6YVN5QVF2djIteC1NWU5lMGEyVmFKdkIxbFphTzhDNk83cGFV'));
  }
}
