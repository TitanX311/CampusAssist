// lib/viewmodel/post_viewmodel.dart
import 'dart:async';

import 'package:campusassist/models/post_model.dart';
import 'package:campusassist/repositories/community_remote_repository.dart';
import 'package:campusassist/repositories/post_remote_repository.dart';
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

// ── Feed (all joined communities, merged newest-first) ───────────────────────

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Post>>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<List<Post>> {
  PostRemoteRepository get _repo => ref.read(postRemoteRepositoryProvider);
  CommunityRemoteRepository get _communityRepo =>
      ref.read(communityRemoteRepositoryProvider);

  @override
  Future<List<Post>> build() => _loadFeed();

  Future<List<Post>> _loadFeed({String? category}) async {
    final communities = await _communityRepo.getMyCommunities();
    if (communities.isEmpty) return [];

    final nameById = {for (final c in communities) c.id: c.name};

    final results = await Future.wait(
      communities.map(
        (c) => _repo
            .getPostsByCommunity(c.id, pageSize: 20)
            .then(
              (posts) =>
                  posts.map((p) => _enrichCommunityName(p, nameById)).toList(),
            )
            .catchError((_) => <Post>[]),
      ),
    );

    final seen = <String>{};
    final merged =
        results.expand((list) => list).where((p) => seen.add(p.id)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  Future<void> refresh({String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFeed(category: category));
  }

  /// Fills in collegeName (used as communityName in the UI) on a post.
  static Post _enrichCommunityName(Post p, Map<String, String> nameById) {
    if (p.collegeName.isNotEmpty) return p;
    final name = nameById[p.communityId];
    if (name == null || name.isEmpty) return p;
    return Post(
      id: p.id,
      content: p.content,
      attachments: p.attachments,
      authorAlias: p.authorAlias,
      authorPicture: p.authorPicture,
      userId: p.userId,
      communityId: p.communityId,
      collegeId: p.collegeId,
      collegeName: name,
      category: p.category,
      upvotes: p.upvotes,
      hasUpvoted: p.hasUpvoted,
      answerCount: p.answerCount,
      views: p.views,
      createdAt: p.createdAt,
      locationLabel: p.locationLabel,
    );
  }

  /// Call this after creating a new post so the feed shows it immediately
  /// without a full network round-trip.
  void prependPost(Post post) {
    state = state.whenData((posts) {
      if (posts.any((p) => p.id == post.id)) return posts;
      return [post, ...posts];
    });
  }

  Future<void> toggleLike(String postId) async {
    final currentPost = state.value?.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw StateError('Post $postId not found'),
    );
    final wasUpvoted = currentPost?.hasUpvoted ?? false;

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
}

// ── Global feed (Across India — all public communities) ──────────────────────

final globalFeedProvider =
    AsyncNotifierProvider<GlobalFeedNotifier, List<Post>>(
      GlobalFeedNotifier.new,
    );

class GlobalFeedNotifier extends AsyncNotifier<List<Post>> {
  PostRemoteRepository get _repo => ref.read(postRemoteRepositoryProvider);
  CommunityRemoteRepository get _communityRepo =>
      ref.read(communityRemoteRepositoryProvider);

  @override
  Future<List<Post>> build() => _loadGlobalFeed();

  Future<List<Post>> _loadGlobalFeed({String? category}) async {
    final communities = await _communityRepo.getMyCommunities();
    if (communities.isEmpty) return [];

    final nameById = {for (final c in communities) c.id: c.name};

    final results = await Future.wait(
      communities.map(
        (c) => _repo
            .getPostsByCommunity(c.id, pageSize: 30)
            .then(
              (posts) => posts
                  .map((p) => FeedNotifier._enrichCommunityName(p, nameById))
                  .toList(),
            )
            .catchError((_) => <Post>[]),
      ),
    );

    final seen = <String>{};
    final merged =
        results.expand((list) => list).where((p) => seen.add(p.id)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  Future<void> refresh({String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadGlobalFeed(category: category));
  }

  void prependPost(Post post) {
    state = state.whenData((posts) {
      if (posts.any((p) => p.id == post.id)) return posts;
      return [post, ...posts];
    });
  }

  Future<void> toggleLike(String postId) async {
    final currentPost = state.value?.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw StateError('Post $postId not found'),
    );
    final wasUpvoted = currentPost?.hasUpvoted ?? false;

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
}

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
