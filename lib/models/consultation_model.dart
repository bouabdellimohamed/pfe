import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationAnswer {
  final String lawyerId;
  final String lawyerName;
  final String answer;
  final DateTime answeredAt;

  ConsultationAnswer({
    required this.lawyerId,
    required this.lawyerName,
    required this.answer,
    required this.answeredAt,
  });

  factory ConsultationAnswer.fromMap(Map<String, dynamic> map) {
    return ConsultationAnswer(
      lawyerId: map['lawyerId'] ?? '',
      lawyerName: map['lawyerName'] ?? '',
      answer: map['answer'] ?? '',
      answeredAt: (map['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lawyerId': lawyerId,
        'lawyerName': lawyerName,
        'answer': answer,
        'answeredAt': Timestamp.fromDate(answeredAt),
      };
}

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
  final String? attachedFileName;
  final String? attachedFileBase64;
  final List<ConsultationAnswer> answers;
  final bool isPrivate;

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
    this.attachedFileName,
    this.attachedFileBase64,
    this.answers = const [],
    this.isPrivate = false,
  });

  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    List<ConsultationAnswer> answersList = [];
    
    if (d['answers'] != null) {
      answersList = (d['answers'] as List?)
              ?.map((e) => ConsultationAnswer.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];
      answersList.sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
    } else if (d['answer'] != null && d['lawyerId'] != null) {
      // Compatibilité ascendante pour les anciennes consultations à réponse unique
      answersList = [
        ConsultationAnswer(
          lawyerId: d['lawyerId'] ?? '',
          lawyerName: d['lawyerName'] ?? 'Avocat',
          answer: d['answer'] ?? '',
          answeredAt: (d['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        )
      ];
    }

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
      attachedFileName: d['attachedFileName']?.toString(),
      attachedFileBase64: d['attachedFileBase64']?.toString(),
      answers: answersList,
      isPrivate: d['isPrivate'] ?? false,
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
        'attachedFileName': attachedFileName,
        'attachedFileBase64': attachedFileBase64,
        'answers': answers.map((e) => e.toMap()).toList(),
        'isPrivate': isPrivate,
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
  final String? attachedFileBase64;

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
    this.attachedFileBase64,
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
      attachedFileBase64: d['attachedFileBase64']?.toString(),
    );
  }
}

