// lib/models/post_model.dart

enum PostCategory {
  academics,
  hostel,
  facilities,
  food,
  career,
  events,
  general,
}

extension PostCategoryExtension on PostCategory {
  String get label {
    switch (this) {
      case PostCategory.academics:
        return 'Academics';
      case PostCategory.hostel:
        return 'Hostel';
      case PostCategory.facilities:
        return 'Facilities';
      case PostCategory.food:
        return 'Food';
      case PostCategory.career:
        return 'Career';
      case PostCategory.events:
        return 'Events';
      case PostCategory.general:
        return 'General';
    }
  }
}

class Post {
  final String id;
  final String title;
  final String body;
  final String authorAlias; // anonymized handle e.g. "Student#4821"
  final String collegeId;
  final String collegeName;
  final PostCategory category;
  final int upvotes;
  final bool hasUpvoted;
  final int answerCount;
  final DateTime createdAt;
  final bool isAnonymous;
  final String? locationLabel; // e.g. "Block C Hostel" – for map feature

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.authorAlias,
    required this.collegeId,
    required this.collegeName,
    required this.category,
    this.upvotes = 0,
    this.hasUpvoted = false,
    this.answerCount = 0,
    required this.createdAt,
    this.isAnonymous = true,
    this.locationLabel,
  });

  Post copyWith({int? upvotes, bool? hasUpvoted}) => Post(
    id: id,
    title: title,
    body: body,
    authorAlias: authorAlias,
    collegeId: collegeId,
    collegeName: collegeName,
    category: category,
    upvotes: upvotes ?? this.upvotes,
    hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    answerCount: answerCount,
    createdAt: createdAt,
    isAnonymous: isAnonymous,
    locationLabel: locationLabel,
  );

  // TODO: Replace with API call
  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    authorAlias: json['author_alias'],
    collegeId: json['college_id'],
    collegeName: json['college_name'],
    category: PostCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => PostCategory.general,
    ),
    upvotes: json['upvotes'] ?? 0,
    hasUpvoted: json['has_upvoted'] ?? false,
    answerCount: json['answer_count'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
    isAnonymous: json['is_anonymous'] ?? true,
    locationLabel: json['location_label'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'author_alias': authorAlias,
    'college_id': collegeId,
    'college_name': collegeName,
    'category': category.name,
    'upvotes': upvotes,
    'has_upvoted': hasUpvoted,
    'answer_count': answerCount,
    'created_at': createdAt.toIso8601String(),
    'is_anonymous': isAnonymous,
    'location_label': locationLabel,
  };
}

class Answer {
  final String id;
  final String postId;
  final String body;
  final String authorAlias;
  final int upvotes;
  final bool hasUpvoted;
  final DateTime createdAt;

  const Answer({
    required this.id,
    required this.postId,
    required this.body,
    required this.authorAlias,
    this.upvotes = 0,
    this.hasUpvoted = false,
    required this.createdAt,
  });

  Answer copyWith({int? upvotes, bool? hasUpvoted}) => Answer(
    id: id,
    postId: postId,
    body: body,
    authorAlias: authorAlias,
    upvotes: upvotes ?? this.upvotes,
    hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    createdAt: createdAt,
  );
}

class College {
  final String id;
  final String name;
  final String city;
  final String state;

  const College({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
  });

  String get displayName => '$name, $city';
}
