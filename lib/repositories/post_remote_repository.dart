import 'package:campusassist/core/interceptors/auth_interceptor.dart';
import 'package:campusassist/core/server_constants.dart';
import 'package:campusassist/models/post_model.dart';
import 'package:campusassist/repositories/attachment_remote_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final postDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ServerConstants.baseURL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});

final postRemoteRepositoryProvider = Provider<PostRemoteRepository>((ref) {
  return PostRemoteRepository(
    ref.read(postDioProvider),
    ref.read(attachmentRemoteRepositoryProvider),
  );
});

class PostRemoteRepository {
  final Dio _dio;
  final AttachmentRemoteRepository _attachmentRepo;

  PostRemoteRepository(this._dio, this._attachmentRepo);

  /// GET /api/posts/community/{community_id}
  Future<List<Post>> getPostsByCommunity(String communityId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/posts/community/$communityId',
      );
      final raw = response.data!;
      final posts =
          (raw['posts'] ?? raw['items'] ?? raw['data'] ?? []) as List<dynamic>;
      return posts
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /api/posts/{post_id}
  Future<Post> getPostById(String postId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/posts/$postId');
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts
  /// Step 1: Upload each [XFile] via POST /api/attachments/upload.
  /// Step 2: POST /api/posts with the returned attachment IDs.
  ///
  /// [onFileProgress] is called with (fileIndex, bytesSent, totalBytes)
  /// so callers can show per-file upload progress.
  Future<Post> createPost({
    required String communityId,
    required String content,
    List<XFile> attachments = const [],
    void Function(int fileIndex, int sent, int total)? onFileProgress,
  }) async {
    try {
      // Step 1 — upload files and collect their IDs.
      List<String> attachmentIds = [];
      if (attachments.isNotEmpty) {
        final uploaded = await _attachmentRepo.uploadFiles(
          attachments,
          onFileProgress: onFileProgress,
        );
        attachmentIds = uploaded.map((a) => a.id).toList();
      }

      // Step 2 — create the post with attachment IDs.
      final response = await _dio.post<Map<String, dynamic>>(
        '/posts',
        data: {
          'community_id': communityId,
          'content': content,
          if (attachmentIds.isNotEmpty) 'attachment_ids': attachmentIds,
        },
      );
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 403) {
        throw Exception('You must be a member of this community to post.');
      }
      throw _mapDioError(e);
    }
  }

  /// PATCH /api/posts/{post_id}
  Future<Post> updatePost(String postId, {String? content}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/posts/$postId',
        data: {if (content != null) 'content': content},
      );
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/posts/{post_id}
  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/posts/$postId');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts/{post_id}/like (toggle like/unlike)
  Future<void> likePost(String postId) async {
    try {
      await _dio.post('/posts/$postId/like');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts/{post_id}/comments
  Future<Comment> addComment(String postId, String body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/posts/$postId/comments',
        data: {'body': body},
      );
      return Comment.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/posts/{post_id}/comments/{comment_id}
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _dio.delete('/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final message =
        (e.response?.data is Map
            ? (e.response!.data as Map)['detail']
            : null) ??
        e.message ??
        'Something went wrong';
    if (status == 404) return Exception('Not found');
    if (status == 401 || status == 403) return Exception('Unauthorized');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection');
    }
    return Exception(message);
  }
}
