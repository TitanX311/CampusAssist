// lib/services/data_service.dart
import '../models/post_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  College? _selectedCollege;
  College? get selectedCollege => _selectedCollege;
  void setCollege(College c) => _selectedCollege = c;

  // ─── Mock posts ───────────────────────────────────────────────────────────
  late List<Post> _posts = [
    Post(
      id: 'p1',
      collegeId: 'c1',
      collegeName: 'IIT Guwahati',
      title: 'Which mess is the best on campus this semester?',
      body:
          'I\'m a first-year student and can\'t decide which mess to register for. Brahmputra or Disang? Quality and pricing both matter.',
      authorAlias: 'Student#4821',
      category: PostCategory.food,
      upvotes: 47,
      answerCount: 12,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      locationLabel: 'Central Mess Area',
    ),
    Post(
      id: 'p2',
      collegeId: 'c1',
      collegeName: 'IIT Guwahati',
      title: 'Power cuts in Barak hostel – any permanent fix coming?',
      body:
          'Been facing power outages every evening from 7-9 PM in Barak hostel. Anyone filed a complaint? What\'s the status?',
      authorAlias: 'Student#2045',
      category: PostCategory.hostel,
      upvotes: 89,
      answerCount: 7,
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      locationLabel: 'Barak Hostel Block B',
    ),
    Post(
      id: 'p3',
      collegeId: 'c1',
      collegeName: 'IIT Guwahati',
      title: 'CS 301 – Data Structures mid-sem preparation tips?',
      body:
          'Any seniors who can guide on what topics are heavily tested in mid-sems for CS301? Prof Sharma\'s course.',
      authorAlias: 'Student#9934',
      category: PostCategory.academics,
      upvotes: 34,
      answerCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Post(
      id: 'p4',
      collegeId: 'c1',
      collegeName: 'IIT Guwahati',
      title: 'Internship referrals at Goldman Sachs – anyone in touch?',
      body:
          'Looking for a referral for the Goldman Sachs summer internship 2025 from any alum or senior. Please DM!',
      authorAlias: 'Student#7732',
      category: PostCategory.career,
      upvotes: 61,
      answerCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Post(
      id: 'p5',
      collegeId: 'c3',
      collegeName: 'IIT Delhi',
      title: 'IITD sports complex timings changed?',
      body:
          'Heard they changed the sports complex timings after renovation. Can someone confirm the new schedule?',
      authorAlias: 'Student#1103',
      category: PostCategory.facilities,
      upvotes: 23,
      answerCount: 6,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      locationLabel: 'Sports Complex Gate 2',
    ),
    Post(
      id: 'p6',
      collegeId: 'c4',
      collegeName: 'IIT Bombay',
      title: 'H4 vs H5 – which hostel has better internet?',
      body:
          'Shifting rooms next sem. Wi-Fi speed in H4 vs H5 – which one is better for late-night coding sessions?',
      authorAlias: 'Student#5581',
      category: PostCategory.hostel,
      upvotes: 102,
      answerCount: 19,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Post(
      id: 'p7',
      collegeId: 'c5',
      collegeName: 'BITS Pilani',
      title: 'Placement season 2025 – which companies already visited?',
      body:
          'Listing all companies that have visited for placements so far. Update in comments!',
      authorAlias: 'Student#3312',
      category: PostCategory.career,
      upvotes: 178,
      answerCount: 31,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Post(
      id: 'p8',
      collegeId: 'c6',
      collegeName: 'VIT Vellore',
      title: 'North Side canteen food quality – is it just me?',
      body:
          'The north side canteen has been serving really poor quality food for the past 2 weeks. Has anyone else noticed?',
      authorAlias: 'Student#8871',
      category: PostCategory.food,
      upvotes: 55,
      answerCount: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      locationLabel: 'North Canteen Block',
    ),
    Post(
      id: 'p9',
      collegeId: 'c2',
      collegeName: 'NIT Silchar',
      title: 'Annual cultural fest Srijan 2025 – volunteer registration open!',
      body:
          'Volunteer registrations for Srijan 2025 are now open. Core team is looking for volunteers across 8 departments. Link in comments.',
      authorAlias: 'Student#2290',
      category: PostCategory.events,
      upvotes: 143,
      answerCount: 22,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Post(
      id: 'p10',
      collegeId: 'c7',
      collegeName: 'Jadavpur University',
      title: 'Library renewal hours – any change for exams?',
      body:
          'Does the central library extend hours during exam season? What\'s been the norm in previous years?',
      authorAlias: 'Student#6642',
      category: PostCategory.facilities,
      upvotes: 18,
      answerCount: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      locationLabel: 'Central Library',
    ),
  ];

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
        const College(id: '', name: 'Unknown', city: '', state: '');
    final post = Post(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      authorAlias:
          'Student#${(1000 + (DateTime.now().millisecond * 9)).toString().substring(0, 4)}',
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

  // ─── Answers ──────────────────────────────────────────────────────────────
  final Map<String, List<Answer>> _answers = {
    'p1': [
      Answer(
        id: 'a1',
        postId: 'p1',
        body:
            'Brahmaputra mess has better quality but slightly more expensive. Worth it though for the variety!',
        authorAlias: 'Student#3311',
        upvotes: 18,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Answer(
        id: 'a2',
        postId: 'p1',
        body:
            'Disang is fine for regular meals. The breakfast is great but dinner can be hit or miss.',
        authorAlias: 'Student#7820',
        upvotes: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
    'p2': [
      Answer(
        id: 'a3',
        postId: 'p2',
        body:
            'I filed a complaint via the student portal 2 weeks ago. They said transformer upgrade is planned for next month.',
        authorAlias: 'Student#6634',
        upvotes: 31,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  };

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
      authorAlias:
          'Student#${(1000 + (DateTime.now().millisecond * 7)).toString().substring(0, 4)}',
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
