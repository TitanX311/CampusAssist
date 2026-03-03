// repositories/college_select_remote_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';

final collegeSelectDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      //todo: change to main ip
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
});

final collegeSelectRemoteRepositoryProvider =
    Provider<CollegeSelectRemoteRepository>((ref) {
      return CollegeSelectRemoteRepository(ref.watch(collegeSelectDioProvider));
    });

class CollegeSelectRemoteRepository {
  final Dio _dio;
  CollegeSelectRemoteRepository(this._dio);

  /// GET /institutes?query=:q&page_size=30
  Future<List<College>> searchColleges(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/institutes',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page_size': 30,
        },
      );
      final results = response.data!['results'] as List<dynamic>;
      return results
          .map((e) => College.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.connectionError:
        return 'Could not reach server. Is it running?';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode}). Please try again.';
      default:
        return 'Network error. Please try again.';
    }
  }
}
