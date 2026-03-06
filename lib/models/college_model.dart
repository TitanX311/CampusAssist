// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class CollegeModel {
  final String id;
  final String name;
  final String contactEmail;
  final String physicalAddress;
  final List<String> adminUsers;
  final List<String> communities;
  CollegeModel({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.physicalAddress,
    required this.adminUsers,
    required this.communities,
  });

  CollegeModel copyWith({
    String? id,
    String? name,
    String? contactEmail,
    String? physicalAddress,
    List<String>? adminUsers,
    List<String>? communities,
  }) {
    return CollegeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactEmail: contactEmail ?? this.contactEmail,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      adminUsers: adminUsers ?? this.adminUsers,
      communities: communities ?? this.communities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'contactEmail': contactEmail,
      'physicalAddress': physicalAddress,
      'adminUsers': adminUsers,
      'communities': communities,
    };
  }

  factory CollegeModel.fromMap(Map<String, dynamic> map) {
    return CollegeModel(
      id: (map['id'] ?? map['_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      contactEmail:
          (map['contactEmail'] ?? map['contact_email'] ?? '') as String,
      physicalAddress:
          (map['physicalAddress'] ??
                  map['physical_address'] ??
                  map['address'] ??
                  '')
              as String,
      adminUsers: map['adminUsers'] != null
          ? List<String>.from(map['adminUsers'] as List)
          : map['admin_users'] != null
          ? List<String>.from(map['admin_users'] as List)
          : [],
      communities: map['communities'] != null
          ? List<String>.from(map['communities'] as List)
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory CollegeModel.fromJson(String source) =>
      CollegeModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CollegeModel(id: $id, name: $name, contactEmail: $contactEmail, physicalAddress: $physicalAddress, adminUsers: $adminUsers, communities: $communities)';
  }

  @override
  bool operator ==(covariant CollegeModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.contactEmail == contactEmail &&
        other.physicalAddress == physicalAddress &&
        listEquals(other.adminUsers, adminUsers) &&
        listEquals(other.communities, communities);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        contactEmail.hashCode ^
        physicalAddress.hashCode ^
        adminUsers.hashCode ^
        communities.hashCode;
  }
}
