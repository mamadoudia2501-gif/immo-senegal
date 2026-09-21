import 'package:flutter/foundation.dart';

enum InquiryStatus {
  envoyee,
  enCours,
  traitee;

  String get label => switch (this) {
    InquiryStatus.envoyee => 'Envoyée',
    InquiryStatus.enCours => 'En cours',
    InquiryStatus.traitee => 'Traitée',
  };
}

@immutable
class Inquiry {
  const Inquiry({
    required this.id,
    required this.name,
    required this.phone,
    required this.message,
    required this.createdAt,
    this.listingId,
    this.status = InquiryStatus.envoyee,
  });

  final String id;
  final String name;
  final String phone;
  final String message;
  final String? listingId;
  final DateTime createdAt;
  final InquiryStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'message': message,
    'listingId': listingId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      message: json['message'] as String,
      listingId: json['listingId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: InquiryStatus.values.byName(json['status'] as String),
    );
  }
}
