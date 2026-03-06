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
  return Community(
    id: map['id'] as String,
    name: map['name'] as String,
    type: map['type'] as String,
    member_users: List<String>.from(map['member_users'] ?? []),
    requested_users: List<String>.from(map['requested_users'] ?? []),
    parent_colleges: List<String>.from(map['parent_colleges'] ?? []),
    posts: List<String>.from(map['posts'] ?? []),
    created_at: DateTime.parse(map['created_at']),
    updated_at: DateTime.parse(map['updated_at']),
  );
}

  String toJson() => json.encode(toMap());

  factory Community.fromJson(String source) =>
      Community.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Community(id: $id, name: $name, type: $type, member_users: $member_users, requested_users: $requested_users, parent_colleges: $parent_colleges, posts: $posts, created_at: $created_at, updated_at: $updated_at)';
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
