// lib/services/data_service.dart
import '../models/post_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  College? _selectedCollege;
  College? get selectedCollege => _selectedCollege;
  void setCollege(College c) => _selectedCollege = c;

  final List<Post> _posts = [];

  /// TODO: Replace with GET /api/posts?scope=college&college_id=:id
  Future<List<Post>> getMyCollegePosts({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
    var posts = _posts
        .where((p) => p.collegeId == (_selectedCollege?.id ?? 'c1'))
        .toList();
    if (category != null && category != 'All') {
      posts = posts.where((p) => p.category.label == category).toList();
    }
    posts.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    return posts;
  }

  /// TODO: Replace with GET /api/posts?scope=india
  Future<List<Post>> getAcrossIndiaPosts({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    var posts = List<Post>.from(_posts);
    if (category != null && category != 'All') {
      posts = posts.where((p) => p.category.label == category).toList();
    }
    posts.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    return posts;
  }

  /// TODO: Replace with POST /api/posts/:id/upvote
  Future<Post> upvotePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw Exception('Post not found');
    final post = _posts[index];
    final updated = post.copyWith(
      upvotes: post.hasUpvoted ? post.upvotes - 1 : post.upvotes + 1,
      hasUpvoted: !post.hasUpvoted,
    );
    _posts[index] = updated;
    return updated;
  }

  /// TODO: Replace with POST /api/posts
  Future<Post> createPost({
    required String title,
    required String body,
    required PostCategory category,
    String? locationLabel,
    bool isAnonymous = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final college =
        _selectedCollege ??
        const College(id: '', name: '', city: '', state: '');
    final post = Post(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      authorAlias: isAnonymous ? 'Anonymous' : 'You',
      collegeId: college.id,
      collegeName: college.name,
      category: category,
      upvotes: 0,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      locationLabel: locationLabel,
    );
    _posts.insert(0, post);
    return post;
  }

  final Map<String, List<Answer>> _answers = {};

  /// TODO: Replace with GET /api/posts/:id/answers
  Future<List<Answer>> getAnswers(String postId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = _answers[postId] ?? [];
    return list..sort((a, b) => b.upvotes.compareTo(a.upvotes));
  }

  /// TODO: Replace with POST /api/posts/:id/answers
  Future<Answer> createAnswer({
    required String postId,
    required String body,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final answer = Answer(
      id: 'ans${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      body: body,
      authorAlias: 'You',
      upvotes: 0,
      createdAt: DateTime.now(),
    );
    _answers[postId] = [...(_answers[postId] ?? []), answer];
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx] = Post(
        id: _posts[idx].id,
        title: _posts[idx].title,
        body: _posts[idx].body,
        authorAlias: _posts[idx].authorAlias,
        collegeId: _posts[idx].collegeId,
        collegeName: _posts[idx].collegeName,
        category: _posts[idx].category,
        upvotes: _posts[idx].upvotes,
        hasUpvoted: _posts[idx].hasUpvoted,
        answerCount: _posts[idx].answerCount + 1,
        createdAt: _posts[idx].createdAt,
        isAnonymous: _posts[idx].isAnonymous,
        locationLabel: _posts[idx].locationLabel,
      );
    }
    return answer;
  }

  /// TODO: Replace with POST /api/answers/:id/upvote
  Future<Answer> upvoteAnswer(String postId, String answerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = _answers[postId] ?? [];
    final idx = list.indexWhere((a) => a.id == answerId);
    if (idx == -1) throw Exception('Answer not found');
    final a = list[idx];
    list[idx] = a.copyWith(
      upvotes: a.hasUpvoted ? a.upvotes - 1 : a.upvotes + 1,
      hasUpvoted: !a.hasUpvoted,
    );
    _answers[postId] = list;
    return list[idx];
  }

  Post? getPost(String id) => _posts.firstWhere((p) => p.id == id);
}
