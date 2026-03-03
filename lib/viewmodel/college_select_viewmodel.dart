// lib/viewmodel/college_select_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../repositories/college_select_remote_repository.dart';

final collegeSelectViewModelProvider =
    AsyncNotifierProvider<CollegeSelectViewModel, List<College>>(
      CollegeSelectViewModel.new,
    );

class CollegeSelectViewModel extends AsyncNotifier<List<College>> {
  @override
  FutureOr<List<College>> build() async {
    return ref.read(collegeSelectRemoteRepositoryProvider).searchColleges('');
  }

  Future<void> searchColleges(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(collegeSelectRemoteRepositoryProvider).searchColleges(query),
    );
  }
}
