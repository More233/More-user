import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../data/repositories/collection_repository_impl.dart';
import '../models/collections_state.dart';

final collectionsViewModelProvider = StateNotifierProvider<CollectionsViewModel, CollectionsState>((ref) {
  final repo = ref.watch(collectionRepositoryProvider);
  return CollectionsViewModel(collectionRepository: repo);
});

class CollectionsViewModel extends StateNotifier<CollectionsState> {
  final CollectionRepository collectionRepository;
  String? _currentUserId;

  CollectionsViewModel({required this.collectionRepository})
      : super(CollectionsState.initial());

  Future<void> init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      await loadCollections();
    }
  }

  Future<void> loadCollections() async {
    if (_currentUserId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await collectionRepository.fetchCollections(_currentUserId!);
      state = state.copyWith(collections: list, isLoading: false);
    } catch (e) {
      debugPrint("Error loading collections: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addCollection(String name, String? coverImageUrl, {List<String> sharedUserIds = const []}) async {
    if (_currentUserId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await collectionRepository.createCollection(
        _currentUserId!,
        name,
        coverImageUrl,
        sharedUserIds: sharedUserIds,
      );
      await loadCollections();
    } catch (e) {
      debugPrint("Error adding collection: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> removeCollection(String collectionId) async {
    state = state.copyWith(isLoading: true);
    try {
      await collectionRepository.deleteCollection(collectionId);
      await loadCollections();
    } catch (e) {
      debugPrint("Error removing collection: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addPostToCollection(String collectionId, String postId) async {
    state = state.copyWith(isLoading: true);
    try {
      await collectionRepository.addPostToCollection(collectionId, postId);
      await loadCollections();
    } catch (e) {
      debugPrint("Error adding post to collection: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> removePostFromCollection(String collectionId, String postId) async {
    state = state.copyWith(isLoading: true);
    try {
      await collectionRepository.removePostFromCollection(collectionId, postId);
      await loadCollections();
    } catch (e) {
      debugPrint("Error removing post from collection: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> removePostFromAllCollections(String postId) async {
    state = state.copyWith(isLoading: true);
    try {
      await collectionRepository.removePostFromAllCollections(postId);
      await loadCollections();
    } catch (e) {
      debugPrint("Error removing post from all collections: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updatePostBookmarkState(String postId, bool isBookmarked) async {
    try {
      await collectionRepository.updatePostBookmarkState(postId, isBookmarked);
    } catch (e) {
      debugPrint("Error updating bookmark state: $e");
    }
  }

  Future<String> getOrCreateSavedCollection() async {
    if (_currentUserId == null) throw Exception("User not logged in");
    
    // Check local state first
    final idx = state.collections.indexWhere((c) => c.name.toLowerCase() == 'saved');
    if (idx != -1) {
      return state.collections[idx].id;
    }

    state = state.copyWith(isLoading: true);
    try {
      final colId = await collectionRepository.getOrCreateSavedCollection(_currentUserId!);
      await loadCollections();
      return colId;
    } catch (e) {
      debugPrint("Error getOrCreateSavedCollection: $e");
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  bool isPostInCollection(String collectionId, String postId) {
    final idx = state.collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      return state.collections[idx].postIds.contains(postId);
    }
    return false;
  }
}
