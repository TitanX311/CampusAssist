// lib/viewmodel/post_viewmodel.dart
import 'dart:async';

import 'package:campusassist/models/post_model.dart';
import 'package:campusassist/repositories/post_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Returns an [AsyncNotifierProvider] scoped to [communityId].
///
/// Usage:
///   ref.watch(postListProvider('community_id'))
///   ref.read(postListProvider('community_id').notifier).createPost(...)
AsyncNotifierProvider<PostListNotifier, List<Post>> postListProvider(
  String communityId,
) {
  return AsyncNotifierProvider<PostListNotifier, List<Post>>(
    () => PostListNotifier(communityId),
  );
}

class PostListNotifier extends AsyncNotifier<List<Post>> {
  final String communityId;

  PostListNotifier(this.communityId);

  PostRemoteRepository get _repo => ref.read(postRemoteRepositoryProvider);

  @override
  Future<List<Post>> build() => _repo.getPostsByCommunity(communityId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getPostsByCommunity(communityId),
    );
  }

  /// Creates a post in this community and prepends it to the local list.
  /// [onFileProgress] is forwarded to the attachment uploader for progress UI.
  Future<Post> createPost({
    required String content,
    List<XFile> attachments = const [],
    void Function(int fileIndex, int sent, int total)? onFileProgress,
  }) async {
    final post = await _repo.createPost(
      communityId: communityId,
      content: content,
      attachments: attachments,
      onFileProgress: onFileProgress,
    );
    state = state.whenData((posts) => [post, ...posts]);
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
    // Optimistic update
    state = state.whenData(
      (posts) => posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    upvotes: p.hasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
                    hasUpvoted: !p.hasUpvoted,
                  )
                : p,
          )
          .toList(),
    );
    try {
      await _repo.likePost(postId);
    } catch (_) {
      // Revert on failure
      state = state.whenData(
        (posts) => posts
            .map(
              (p) => p.id == postId
                  ? p.copyWith(
                      upvotes: p.hasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
                      hasUpvoted: !p.hasUpvoted,
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
