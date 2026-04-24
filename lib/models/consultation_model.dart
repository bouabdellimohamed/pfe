import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationModel {
  final String id;
  final String userId;
  final String userFullName;
  final String type;
  final String question;
  final String? answer;
  final String? lawyerId;
  final String? lawyerName;
  final String status; // 'pending' | 'answered'
  final DateTime createdAt;
  final DateTime? answeredAt;

  ConsultationModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.type,
    required this.question,
    this.answer,
    this.lawyerId,
    this.lawyerName,
    required this.status,
    required this.createdAt,
    this.answeredAt,
  });

  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConsultationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userFullName: d['userFullName'] ?? '',
      type: d['type'] ?? '',
      question: d['question'] ?? '',
      answer: d['answer'],
      lawyerId: d['lawyerId'],
      lawyerName: d['lawyerName'],
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answeredAt: (d['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userFullName': userFullName,
    'type': type,
    'question': question,
    'answer': answer,
    'lawyerId': lawyerId,
    'lawyerName': lawyerName,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
  };
}

class RequestModel {
  final String id;
  final String userId;
  final String userFullName;
  final String title;
  final String type;
  final String description;
  final String? attachedFileName;
  final String status; // 'open' | 'closed'
  final List<String> respondedLawyerIds;
  final String? acceptedLawyerId;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.title,
    required this.type,
    required this.description,
    this.attachedFileName,
    required this.status,
    required this.respondedLawyerIds,
    this.acceptedLawyerId,
    required this.createdAt,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userFullName: d['userFullName'] ?? '',
      title: d['title'] ?? '',
      type: d['type'] ?? '',
      description: d['description'] ?? '',
      attachedFileName: d['attachedFileName'],
      status: d['status'] ?? 'open',
      respondedLawyerIds: List<String>.from(d['respondedLawyerIds'] ?? []),
      acceptedLawyerId: d['acceptedLawyerId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
