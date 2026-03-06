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
  final String content;
  final List<String> attachments;
  final String authorAlias; // anonymized handle shown in the UI
  final String communityId;
  final String collegeId;
  final String collegeName;
  final PostCategory category;
  final int upvotes;
  final bool hasUpvoted;
  final int answerCount;
  final DateTime createdAt;
  final String? locationLabel; // selected campus landmark label

  const Post({
    required this.id,
    required this.content,
    this.attachments = const [],
    required this.authorAlias,
    this.communityId = '',
    this.collegeId = '',
    this.collegeName = '',
    required this.category,
    this.upvotes = 0,
    this.hasUpvoted = false,
    this.answerCount = 0,
    required this.createdAt,
    this.locationLabel,
  });

  Post copyWith({int? upvotes, bool? hasUpvoted}) => Post(
    id: id,
    content: content,
    attachments: attachments,
    authorAlias: authorAlias,
    communityId: communityId,
    collegeId: collegeId,
    collegeName: collegeName,
    category: category,
    upvotes: upvotes ?? this.upvotes,
    hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    answerCount: answerCount,
    createdAt: createdAt,
    locationLabel: locationLabel,
  );

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    attachments: (json['attachments'] as List<dynamic>? ?? []).cast<String>(),
    authorAlias: json['author_alias'] as String? ?? '',
    communityId: json['community_id'] as String? ?? '',
    collegeId: json['college_id'] as String? ?? '',
    collegeName: json['college_name'] as String? ?? '',
    category: PostCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => PostCategory.general,
    ),
    upvotes: json['upvotes'] as int? ?? 0,
    hasUpvoted: json['has_upvoted'] as bool? ?? false,
    answerCount: json['answer_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    locationLabel: json['location_label'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'attachments': attachments,
    'author_alias': authorAlias,
    'community_id': communityId,
    'college_id': collegeId,
    'college_name': collegeName,
    'category': category.name,
    'upvotes': upvotes,
    'has_upvoted': hasUpvoted,
    'answer_count': answerCount,
    'created_at': createdAt.toIso8601String(),
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

/// Maps to the API comment shape for /api/posts/{post_id}/comments
class Comment {
  final String id;
  final String postId;
  final String body;
  final String authorAlias;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.body,
    required this.authorAlias,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    postId: json['post_id'] as String? ?? '',
    body: json['body'] as String,
    authorAlias: json['author_alias'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'body': body,
    'author_alias': authorAlias,
    'created_at': createdAt.toIso8601String(),
  };
}
