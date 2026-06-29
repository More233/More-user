import 'package:flutter_test/flutter_test.dart';
import 'package:moor/sections/home/models/timeline_post.dart';

void main() {
  group('TimelinePost - shortLocationAddress & shortTitle (Word Truncation)', () {
    test('short address with <= 4 words is kept fully intact', () {
      final post = TimelinePost(
        id: '1',
        title: 'Helnan Auberge Hotel',
        categoryName: 'Hotel',
        locationAddress: 'Muhafazat al Fayyūm, Egypt',
        visitorCount: 1,
        postTime: 'Just now',
        description: 'Testing',
        imageUrl: null,
        likesCount: 0,
        commentsCount: 0,
        categoryIcon: CategoryIconType.building,
        comments: [],
      );
      expect(post.shortLocationAddress, 'Muhafazat al Fayyūm, Egypt');
      expect(post.shortTitle, 'Helnan Auberge Hotel');
    });

    test('address with > 4 words is truncated to 4 words with ellipsis', () {
      final post = TimelinePost(
        id: '1',
        title: 'Helnan Auberge El Fayoum Hotel',
        categoryName: 'Hotel',
        locationAddress: 'Helnan Auberge El Fayoum Hotel, Muhafazat al Fayyūm, Egypt',
        visitorCount: 1,
        postTime: 'Just now',
        description: 'Testing',
        imageUrl: null,
        likesCount: 0,
        commentsCount: 0,
        categoryIcon: CategoryIconType.building,
        comments: [],
      );
      expect(post.shortLocationAddress, 'Helnan Auberge El Fayoum...');
      expect(post.shortTitle, 'Helnan Auberge El Fayoum...');
    });

    test('address with Arabic commas and generic prefixes is truncated properly without dropping names', () {
      final post = TimelinePost(
        id: '1',
        title: 'قرية السندندور، الغربية، مصر',
        categoryName: 'Other',
        locationAddress: 'قرية، السندندور، الغربية، مصر، الغربية',
        visitorCount: 1,
        postTime: 'Just now',
        description: 'Testing',
        imageUrl: null,
        likesCount: 0,
        commentsCount: 0,
        categoryIcon: CategoryIconType.building,
        comments: [],
      );
      // "قرية، السندندور، الغربية، مصر، الغربية" -> 5 words. First 4 words are "قرية، السندندور، الغربية، مصر،"
      // Trailing comma/whitespace is stripped, then "..." is appended.
      expect(post.shortLocationAddress, 'قرية، السندندور، الغربية، مصر...');
      expect(post.shortTitle, 'قرية السندندور، الغربية، مصر'); // 4 words, kept as is
    });
  });
}
