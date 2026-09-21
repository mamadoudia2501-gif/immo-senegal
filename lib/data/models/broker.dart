import 'package:flutter/foundation.dart';

@immutable
class Broker {
  const Broker({
    required this.id,
    required this.name,
    required this.agency,
    required this.city,
    required this.phone,
    required this.email,
    required this.bio,
    required this.yearsExperience,
    required this.specialty,
  });

  final String id;
  final String name;
  final String agency;
  final String city;
  final String phone;
  final String email;
  final String bio;
  final int yearsExperience;
  final String specialty;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
