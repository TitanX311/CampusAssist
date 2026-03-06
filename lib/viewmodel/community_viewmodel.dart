// lib/viewmodel/community_viewmodel.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/community_model.dart';
import '../repositories/community_remote_repository.dart';

final communityViewModelProvider =
    AsyncNotifierProvider<CommunityViewModel, List<Community>>(
  CommunityViewModel.new,
);

class CommunityViewModel extends AsyncNotifier<List<Community>> {
  @override
  FutureOr<List<Community>> build() async {
    return _repository.getMyCommunities();
  }
  CommunityRemoteRepository get _repository => 
      ref.read(communityRemoteRepositoryProvider);

  /// Fetch user's joined communities
  Future<void> fetchMyCommunities() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getMyCommunities());
  }

  /// Join a community
  Future<void> joinCommunity(String communityId) async {
    try {
      await _repository.joinCommunity(communityId);
      await fetchMyCommunities(); // refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId) async {
    try {
      await _repository.leaveCommunity(communityId);
      await fetchMyCommunities(); // refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new community
  Future<void> createCommunity({
    required String name,
    required String type,
  }) async {
    await _repository.createCommunity(name: name, type: type);
    await fetchMyCommunities(); // refresh list
  }

  /// Get a specific community details
  Future<Community> getCommunityDetails(String communityId) async {
    return _repository.getCommunityById(communityId);
  }
}
