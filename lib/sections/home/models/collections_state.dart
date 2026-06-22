import 'collection_model.dart';

class CollectionsState {
  final List<CollectionModel> collections;
  final bool isLoading;

  CollectionsState({
    required this.collections,
    required this.isLoading,
  });

  factory CollectionsState.initial() {
    return CollectionsState(
      collections: [],
      isLoading: false,
    );
  }

  CollectionsState copyWith({
    List<CollectionModel>? collections,
    bool? isLoading,
  }) {
    return CollectionsState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
