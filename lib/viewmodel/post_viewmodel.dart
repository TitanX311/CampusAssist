// lib/viewmodel/post_viewmodel.dart
import 'dart:async';

import 'package:campusassist/models/post_model.dart';
import 'package:campusassist/repositories/community_remote_repository.dart';
import 'package:campusassist/repositories/feed_repository.dart';
import 'package:campusassist/repositories/post_remote_repository.dart';
import 'package:campusassist/viewmodel/auth_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── Community post list ───────────────────────────────────────────────────────

/// Cache so the same communityId always returns the same provider instance.
final _postListProviderCache =
    <String, AsyncNotifierProvider<PostListNotifier, List<Post>>>{};

/// Returns a cached [AsyncNotifierProvider] scoped to [communityId].
///
/// Usage:
///   ref.watch(postListProvider('community_id'))
///   ref.read(postListProvider('community_id').notifier).createPost(...)
AsyncNotifierProvider<PostListNotifier, List<Post>> postListProvider(
  String communityId,
) {
  return _postListProviderCache.putIfAbsent(
    communityId,
    () => AsyncNotifierProvider<PostListNotifier, List<Post>>(
      () => PostListNotifier(communityId),
    ),
  );
}

class PostListNotifier extends AsyncNotifier<List<Post>> {
  final String communityId;

  PostListNotifier(this.communityId);

  PostRemoteRepository get _repo => ref.read(postRemoteRepositoryProvider);

  @override
  Future<List<Post>> build() => _repo.getPostsByCommunity(communityId);

  Future<void> refresh({String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getPostsByCommunity(communityId, category: category),
    );
  }

  /// Creates a post in this community and prepends it to the local list.
  /// [onFileProgress] is forwarded to the attachment uploader for progress UI.
  Future<Post> createPost({
    required String content,
    String category = 'general',
    String? locationLabel,
    double? locationLat,
    double? locationLng,
    List<XFile> attachments = const [],
    void Function(int fileIndex, int sent, int total)? onFileProgress,
  }) async {
    final post = await _repo.createPost(
      communityId: communityId,
      content: content,
      category: category,
      locationLabel: locationLabel,
      locationLat: locationLat,
      locationLng: locationLng,
      attachments: attachments,
      onFileProgress: onFileProgress,
    );
    // Prepend into this community's list
    state = state.whenData((posts) => [post, ...posts]);
    // Also push into both merged feeds so they update immediately
    ref.read(feedProvider.notifier).prependPost(post);
    ref.read(globalFeedProvider.notifier).prependPost(post);
    return post;
  }

  /// Deletes a post and removes it from the local list.
  Future<void> deletePost(String postId) async {
    await _repo.deletePost(postId);
    state = state.whenData(
      (posts) => posts.where((p) => p.id != postId).toList(),
    );
  }

  /// Toggles like with an optimistic update; reverts on failure.
  Future<void> toggleLike(String postId) async {
    // Capture current state before the optimistic update
    final currentPost = state.value?.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw StateError('Post $postId not found'),
    );
    final wasUpvoted = currentPost?.hasUpvoted ?? false;

    // Optimistic update
    state = state.whenData(
      (posts) => posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    upvotes: wasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
                    hasUpvoted: !wasUpvoted,
                  )
                : p,
          )
          .toList(),
    );
    try {
      await _repo.likePost(postId, hasUpvoted: wasUpvoted);
    } catch (_) {
      // Revert on failure
      state = state.whenData(
        (posts) => posts
            .map(
              (p) => p.id == postId
                  ? p.copyWith(
                      upvotes: wasUpvoted ? p.upvotes + 1 : p.upvotes - 1,
                      hasUpvoted: wasUpvoted,
                    )
                  : p,
            )
            .toList(),
      );
    }
  }

  /// Updates a post and reflects the change locally.
  Future<Post> updatePost(String postId, {String? content}) async {
    final updated = await _repo.updatePost(postId, content: content);
    state = state.whenData(
      (posts) => posts.map((p) => p.id == postId ? updated : p).toList(),
    );
    return updated;
  }
}

// ── Feed state ────────────────────────────────────────────────────────────────

class FeedState {
  final List<Post> posts;
  final int? nextCursor;
  final bool isLoadingMore;
  final bool hasMore;

  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<Post>? posts,
    int? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    bool? hasMore,
  }) => FeedState(
    posts: posts ?? this.posts,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
  );
}

// ── My Feed (personalised — /api/feed/my) ─────────────────────────────────────

final feedProvider = AsyncNotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<FeedState> {
  FeedRepository get _feedRepo => ref.read(feedRepositoryProvider);
  CommunityRemoteRepository get _communityRepo =>
      ref.read(communityRemoteRepositoryProvider);

  /// communityId → communityName cache, populated lazily.
  final _nameCache = <String, String>{};

  String? get _userType => ref.read(authViewModelProvider).value?.userType;

  @override
  Future<FeedState> build() {
    debugPrint('[FeedNotifier] build() — initial load, userType=$_userType');
    if (_userType != null && _userType != 'USER') {
      debugPrint(
        '[FeedNotifier] userType=$_userType — feed API not available, returning empty',
      );
      return Future.value(const FeedState(hasMore: false));
    }
    return _load(cursor: 0, existing: const FeedState());
  }

  Future<FeedState> _load({
    required int cursor,
    required FeedState existing,
  }) async {
    debugPrint('[FeedNotifier] _load() cursor=$cursor');

    // Warm the community-name cache (best-effort, non-blocking)
    if (_nameCache.isEmpty) {
      debugPrint('[FeedNotifier] warming community-name cache');
      try {
        final communities = await _communityRepo.getMyCommunities();
        for (final c in communities) {
          _nameCache[c.id] = c.name;
        }
        debugPrint(
          '[FeedNotifier] name cache warmed — ${_nameCache.length} communities',
        );
      } catch (e) {
        debugPrint('[FeedNotifier] name cache warm failed: $e');
      }
    }

    final page = await _feedRepo.getMyFeed(cursor: cursor, pageSize: 20);
    debugPrint(
      '[FeedNotifier] GET /feed/my → ${page.items.length} items, '
      'nextCursor=${page.nextCursor}, hasMore=${page.hasMore}, '
      'totalInCache=${page.totalInCache}, builtFresh=${page.builtFresh}',
    );

    final newPosts = page.items
        .map(
          (item) =>
              item.toPost(communityName: _nameCache[item.communityId] ?? ''),
        )
        .toList();

    final merged = cursor == 0 ? newPosts : [...existing.posts, ...newPosts];

    // De-duplicate by id
    final seen = <String>{};
    final deduped = merged.where((p) => seen.add(p.id)).toList();
    debugPrint(
      '[FeedNotifier] merged list → ${deduped.length} posts (${merged.length - deduped.length} dupes removed)',
    );

    return FeedState(
      posts: deduped,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    debugPrint('[FeedNotifier] refresh()');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(cursor: 0, existing: const FeedState()),
    );
    debugPrint('[FeedNotifier] refresh() done — invalidating server cache');
    _feedRepo.invalidateMyCache();
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.isLoadingMore || !s.hasMore || s.nextCursor == null) {
      debugPrint(
        '[FeedNotifier] loadMore() skipped — '
        'isLoadingMore=${s?.isLoadingMore}, hasMore=${s?.hasMore}, nextCursor=${s?.nextCursor}',
      );
      return;
    }
    debugPrint('[FeedNotifier] loadMore() cursor=${s.nextCursor}');
    state = AsyncData(s.copyWith(isLoadingMore: true));
    try {
      final next = await _load(cursor: s.nextCursor!, existing: s);
      state = AsyncData(next);
      debugPrint(
        '[FeedNotifier] loadMore() done — total posts=${next.posts.length}',
      );
    } catch (e) {
      debugPrint('[FeedNotifier] loadMore() error: $e');
      state = AsyncData(s.copyWith(isLoadingMore: false));
    }
  }

  /// Prepends a newly created post so the feed reflects it immediately.
  void prependPost(Post post) {
    debugPrint('[FeedNotifier] prependPost() postId=${post.id}');
    state = state.whenData((s) {
      if (s.posts.any((p) => p.id == post.id)) {
        debugPrint('[FeedNotifier] prependPost() — already exists, skipping');
        return s;
      }
      return s.copyWith(posts: [post, ...s.posts]);
    });
    // Invalidate server cache so next pull includes the new post
    _feedRepo.invalidateMyCache();
  }

  Future<void> toggleLike(String postId) async {
    debugPrint(
      '[FeedNotifier] toggleLike() postId=$postId wasUpvoted=${_wasUpvoted(postId)}',
    );
    _optimisticToggle(postId);
    try {
      await ref
          .read(postRemoteRepositoryProvider)
          .likePost(postId, hasUpvoted: _wasUpvoted(postId));
      debugPrint('[FeedNotifier] toggleLike() success');
    } catch (e) {
      debugPrint('[FeedNotifier] toggleLike() failed — reverting: $e');
      _optimisticToggle(postId); // revert
    }
  }

  bool _wasUpvoted(String postId) =>
      state.value?.posts
          .firstWhere((p) => p.id == postId, orElse: () => _dummyPost)
          .hasUpvoted ??
      false;

  void _optimisticToggle(String postId) {
    state = state.whenData(
      (s) => s.copyWith(
        posts: s.posts.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(
            upvotes: p.hasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
            hasUpvoted: !p.hasUpvoted,
          );
        }).toList(),
      ),
    );
  }
}

// ── Across-India Feed (/api/feed/india) ───────────────────────────────────────

final globalFeedProvider = AsyncNotifierProvider<GlobalFeedNotifier, FeedState>(
  GlobalFeedNotifier.new,
);

class GlobalFeedNotifier extends AsyncNotifier<FeedState> {
  FeedRepository get _feedRepo => ref.read(feedRepositoryProvider);

  String? get _userType => ref.read(authViewModelProvider).value?.userType;

  @override
  Future<FeedState> build() {
    debugPrint(
      '[GlobalFeedNotifier] build() — initial load, userType=$_userType',
    );
    if (_userType != null && _userType != 'USER') {
      debugPrint(
        '[GlobalFeedNotifier] userType=$_userType — feed API not available, returning empty',
      );
      return Future.value(const FeedState(hasMore: false));
    }
    return _load(cursor: 0, existing: const FeedState());
  }

  Future<FeedState> _load({
    required int cursor,
    required FeedState existing,
  }) async {
    debugPrint('[GlobalFeedNotifier] _load() cursor=$cursor');
    final page = await _feedRepo.getIndiaFeed(cursor: cursor, pageSize: 20);
    debugPrint(
      '[GlobalFeedNotifier] GET /feed/india → ${page.items.length} items, '
      'nextCursor=${page.nextCursor}, hasMore=${page.hasMore}, '
      'totalInCache=${page.totalInCache}, builtFresh=${page.builtFresh}',
    );

    final newPosts = page.items.map((item) => item.toPost()).toList();

    final merged = cursor == 0 ? newPosts : [...existing.posts, ...newPosts];

    final seen = <String>{};
    final deduped = merged.where((p) => seen.add(p.id)).toList();
    debugPrint('[GlobalFeedNotifier] merged list → ${deduped.length} posts');

    return FeedState(
      posts: deduped,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    debugPrint('[GlobalFeedNotifier] refresh()');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(cursor: 0, existing: const FeedState()),
    );
    debugPrint('[GlobalFeedNotifier] refresh() done');
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.isLoadingMore || !s.hasMore || s.nextCursor == null) {
      debugPrint(
        '[GlobalFeedNotifier] loadMore() skipped — '
        'isLoadingMore=${s?.isLoadingMore}, hasMore=${s?.hasMore}, nextCursor=${s?.nextCursor}',
      );
      return;
    }
    debugPrint('[GlobalFeedNotifier] loadMore() cursor=${s.nextCursor}');
    state = AsyncData(s.copyWith(isLoadingMore: true));
    try {
      final next = await _load(cursor: s.nextCursor!, existing: s);
      state = AsyncData(next);
      debugPrint(
        '[GlobalFeedNotifier] loadMore() done — total posts=${next.posts.length}',
      );
    } catch (e) {
      debugPrint('[GlobalFeedNotifier] loadMore() error: $e');
      state = AsyncData(s.copyWith(isLoadingMore: false));
    }
  }

  void prependPost(Post post) {
    debugPrint('[GlobalFeedNotifier] prependPost() postId=${post.id}');
    state = state.whenData((s) {
      if (s.posts.any((p) => p.id == post.id)) return s;
      return s.copyWith(posts: [post, ...s.posts]);
    });
  }

  Future<void> toggleLike(String postId) async {
    debugPrint(
      '[GlobalFeedNotifier] toggleLike() postId=$postId wasUpvoted=${_wasUpvoted(postId)}',
    );
    _optimisticToggle(postId);
    try {
      await ref
          .read(postRemoteRepositoryProvider)
          .likePost(postId, hasUpvoted: _wasUpvoted(postId));
      debugPrint('[GlobalFeedNotifier] toggleLike() success');
    } catch (e) {
      debugPrint('[GlobalFeedNotifier] toggleLike() failed — reverting: $e');
      _optimisticToggle(postId); // revert
    }
  }

  bool _wasUpvoted(String postId) =>
      state.value?.posts
          .firstWhere((p) => p.id == postId, orElse: () => _dummyPost)
          .hasUpvoted ??
      false;

  void _optimisticToggle(String postId) {
    state = state.whenData(
      (s) => s.copyWith(
        posts: s.posts.map((p) {
          if (p.id != postId) return p;
          return p.copyWith(
            upvotes: p.hasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
            hasUpvoted: !p.hasUpvoted,
          );
        }).toList(),
      ),
    );
  }
}

/// A sentinel Post used in `orElse` guards — never rendered.
final _dummyPost = Post(
  id: '',
  content: '',
  authorAlias: '',
  category: PostCategory.general,
  createdAt: DateTime(2000),
);

// ── Comments ──────────────────────────────────────────────────────────────────

/// Cache so the same (postId, communityId) always returns the same provider.
final _commentsProviderCache =
    <
      (String, String),
      AsyncNotifierProvider<CommentsNotifier, List<Comment>>
    >{};

/// Returns a cached [AsyncNotifierProvider] scoped to [postId] + [communityId].
///
/// Usage:
///   ref.watch(commentsProvider(postId: 'x', communityId: 'y'))
///   ref.read(commentsProvider(postId: 'x', communityId: 'y').notifier).addComment(...)
AsyncNotifierProvider<CommentsNotifier, List<Comment>> commentsProvider({
  required String postId,
  required String communityId,
}) {
  return _commentsProviderCache.putIfAbsent(
    (postId, communityId),
    () => AsyncNotifierProvider<CommentsNotifier, List<Comment>>(
      () => CommentsNotifier(postId: postId, communityId: communityId),
    ),
  );
}

class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  final String postId;
  final String communityId;

  CommentsNotifier({required this.postId, required this.communityId});

  PostRemoteRepository get _repo => ref.read(postRemoteRepositoryProvider);

  @override
  Future<List<Comment>> build() {
    debugPrint(
      '[CommentsNotifier] build() postId=$postId (should only fire once per postId)',
    );
    return _repo.getComments(postId, communityId: communityId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getComments(postId, communityId: communityId),
    );
  }

  Future<Comment> addComment(String body) async {
    final comment = await _repo.addComment(
      postId,
      body,
      communityId: communityId,
    );
    state = state.whenData((list) => [comment, ...list]);
    return comment;
  }

  Future<void> deleteComment(String commentId) async {
    await _repo.deleteComment(postId, commentId);
    state = state.whenData(
      (list) => list.where((c) => c.id != commentId).toList(),
    );
  }
}
