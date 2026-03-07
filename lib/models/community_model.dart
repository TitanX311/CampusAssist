// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

// lib/models/community_model.dart

class Community {
  final String id;
  final String name;
  final String type;
  final List<String> member_users;
  final List<String> requested_users;
  final List<String> parent_colleges;
  final List<String> posts;
  final DateTime created_at;
  final DateTime updated_at;

  Community({
    required this.id,
    required this.name,
    required this.type,
    required this.member_users,
    required this.requested_users,
    required this.parent_colleges,
    required this.posts,
    required this.created_at,
    required this.updated_at,
  });

  Community copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? member_users,
    List<String>? requested_users,
    List<String>? parent_colleges,
    List<String>? posts,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      member_users: member_users ?? this.member_users,
      requested_users: requested_users ?? this.requested_users,
      parent_colleges: parent_colleges ?? this.parent_colleges,
      posts: posts ?? this.posts,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'member_users': member_users,
      'requested_users': requested_users,
      'parent_colleges': parent_colleges,
      'posts': posts,
      'created_at': created_at.toIso8601String(),
      'updated_at': updated_at.toIso8601String(),
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    // Support both 'id' and '_id' (MongoDB style)
    final id = (map['id'] ?? map['_id'] ?? '').toString();

    return Community(
      id: id,
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'PUBLIC').toString(),
      member_users: _parseStringList(map['member_users']),
      requested_users: _parseStringList(map['requested_users']),
      parent_colleges: _parseStringList(map['parent_colleges']),
      posts: _parseStringList(map['posts']),
      created_at: _parseDate(map['created_at']),
      updated_at: _parseDate(map['updated_at']),
    );
  }

  /// Safely parses a list that may contain strings or maps with an id/\_id field.
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) {
            if (e == null) return '';
            if (e is String) return e;
            if (e is Map) return (e['id'] ?? e['_id'] ?? '').toString();
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Safely parses a date that may be a String, int (ms), or null.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  String toJson() => json.encode(toMap());

  factory Community.fromJson(String source) =>
      Community.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Community(id: $id, name: $name, type: $type, member_users: $member_users, '
        'requested_users: $requested_users, parent_colleges: $parent_colleges, '
        'posts: $posts, created_at: $created_at, updated_at: $updated_at)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.type == type &&
        listEquals(other.member_users, member_users) &&
        listEquals(other.requested_users, requested_users) &&
        listEquals(other.parent_colleges, parent_colleges) &&
        listEquals(other.posts, posts) &&
        other.created_at == created_at &&
        other.updated_at == updated_at;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        member_users.hashCode ^
        requested_users.hashCode ^
        parent_colleges.hashCode ^
        posts.hashCode ^
        created_at.hashCode ^
        updated_at.hashCode;
  }
}
