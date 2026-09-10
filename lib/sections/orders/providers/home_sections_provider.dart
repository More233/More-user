import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_section_model.dart';

/// Realtime Stream Provider for all active home sections and their items
final homeSectionsStreamProvider = StreamProvider<List<HomeSectionModel>>((ref) {
  final client = Supabase.instance.client;

  // Stream sections
  return client
      .from('home_sections')
      .stream(primaryKey: ['id'])
      .asyncMap((sectionsData) async {
        try {
          final itemsRes = await client
              .from('home_section_items')
              .select('*')
              .order('sort_order', ascending: true);

          final allItems = (itemsRes as List<dynamic>)
              .map((m) => HomeSectionItemModel.fromMap(m as Map<String, dynamic>))
              .where((i) => i.isActive)
              .toList();

          final sections = sectionsData
              .map((m) {
                final sec = HomeSectionModel.fromMap(m);
                final items = allItems.where((i) => i.sectionId == sec.id).toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                return sec.copyWith(items: items);
              })
              .where((s) => s.isActive)
              .toList();

          sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return sections;
        } catch (e) {
          return _getFallbackSections();
        }
      });
});

List<HomeSectionModel> _getFallbackSections() {
  return [
    const HomeSectionModel(
      id: 'categories',
      sectionKey: 'categories',
      title: 'وش ودك تطلب اليوم؟',
      sortOrder: 1,
      items: [
        HomeSectionItemModel(
          id: '1',
          sectionId: 'categories',
          title: 'مطاعم',
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
          badgeText: '+50,000',
          badgeColor: 'yellow',
          sortOrder: 1,
        ),
        HomeSectionItemModel(
          id: '2',
          sectionId: 'categories',
          title: 'H ماركت',
          imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&q=80',
          badgeText: '20 دقيقة',
          badgeColor: 'yellow',
          sortOrder: 2,
        ),
        HomeSectionItemModel(
          id: '3',
          sectionId: 'categories',
          title: 'مقاضي',
          imageUrl: 'https://images.unsplash.com/photo-1579113800032-c38bd7635818?w=400&q=80',
          sortOrder: 3,
        ),
        HomeSectionItemModel(
          id: '4',
          sectionId: 'categories',
          title: 'استلم بنفسك',
          imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400&q=80',
          badgeText: 'خصم حتى 30%',
          badgeColor: 'red',
          sortOrder: 4,
        ),
        HomeSectionItemModel(
          id: '5',
          sectionId: 'categories',
          title: 'قهوة وحلى',
          imageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=400&q=80',
          sortOrder: 5,
        ),
        HomeSectionItemModel(
          id: '6',
          sectionId: 'categories',
          title: 'صيدليات',
          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&q=80',
          sortOrder: 6,
        ),
        HomeSectionItemModel(
          id: '7',
          sectionId: 'categories',
          title: 'ورود وأكثر',
          imageUrl: 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?w=400&q=80',
          sortOrder: 7,
        ),
        HomeSectionItemModel(
          id: '8',
          sectionId: 'categories',
          title: 'هدايا',
          imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=400&q=80',
          badgeText: 'خصم 30%',
          badgeColor: 'red',
          sortOrder: 8,
        ),
      ],
    ),
    const HomeSectionModel(
      id: 'daily_offers',
      sectionKey: 'daily_offers',
      title: 'العروض اليومية',
      sortOrder: 2,
      items: [
        HomeSectionItemModel(
          id: 'd1',
          sectionId: 'daily_offers',
          title: 'حلى',
          subtitle: 'حلى ولذاذة',
          imageUrl: 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=500&q=80',
          sortOrder: 1,
        ),
        HomeSectionItemModel(
          id: 'd2',
          sectionId: 'daily_offers',
          title: 'أجواء الصيف',
          subtitle: 'آيسكريم الصيف',
          imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=500&q=80',
          sortOrder: 2,
        ),
        HomeSectionItemModel(
          id: 'd3',
          sectionId: 'daily_offers',
          title: 'الصيف يبيله قهوة',
          subtitle: 'مشروبات باردة',
          imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&q=80',
          sortOrder: 3,
        ),
        HomeSectionItemModel(
          id: 'd4',
          sectionId: 'daily_offers',
          title: 'عروض كبرى',
          subtitle: 'خصومات خاصة',
          imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&q=80',
          sortOrder: 4,
        ),
      ],
    ),
    const HomeSectionModel(
      id: 'featured_meals',
      sectionKey: 'featured_meals',
      title: 'وجبات ابتداءً من 19 ريال',
      subtitle: '19 ريال',
      bannerImageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=800&q=80',
      sortOrder: 3,
      items: [
        HomeSectionItemModel(
          id: 'm1',
          sectionId: 'featured_meals',
          title: 'سوبر برجر كلاسيك ديو',
          subtitle: '30 دقائق | مجاني',
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
          price: 29.00,
          oldPrice: 41.43,
          badgeText: 'سوبر',
          badgeColor: 'yellow',
          promoText: 'مع بطاطس ومشروب',
          sortOrder: 1,
        ),
        HomeSectionItemModel(
          id: 'm2',
          sectionId: 'featured_meals',
          title: 'سوبر برجر سبايسي ديو',
          subtitle: '30 دقائق | مجاني',
          imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=400&q=80',
          price: 29.00,
          oldPrice: 41.43,
          badgeText: 'إعلان',
          badgeColor: 'gray',
          promoText: 'نكهة حارة لا تقاوم',
          sortOrder: 2,
        ),
        HomeSectionItemModel(
          id: 'm3',
          sectionId: 'featured_meals',
          title: 'وجبة ساندويتش كباب...',
          subtitle: '20 دقائق | مجاني',
          imageUrl: 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=400&q=80',
          price: 20.56,
          oldPrice: 25.70,
          promoText: 'مشوي على الفحم',
          sortOrder: 3,
        ),
      ],
    ),
    const HomeSectionModel(
      id: 'picks',
      sectionKey: 'picks',
      title: 'مختارات',
      sortOrder: 4,
      items: [
        HomeSectionItemModel(
          id: 'p1',
          sectionId: 'picks',
          title: 'النقلـي',
          subtitle: 'محمصة',
          imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=800&q=80',
          rating: 4.4,
          ratingCount: 38,
          price: 20.00,
          promoText: 'توصيل مجاني وقسيمة بـ 10 ريال',
          badgeText: 'H+',
          badgeColor: 'blue',
          sortOrder: 1,
        ),
        HomeSectionItemModel(
          id: 'p2',
          sectionId: 'picks',
          title: 'جمر الكانون',
          subtitle: 'ساندوتشات، مشويات، عربي',
          imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
          rating: 4.6,
          ratingCount: 24,
          price: 0.00,
          promoText: 'توصيل مجاني وقسيمة بـ 15 ريال',
          badgeText: 'H+',
          badgeColor: 'blue',
          sortOrder: 2,
        ),
      ],
    ),
    const HomeSectionModel(
      id: 'cuisines',
      sectionKey: 'cuisines',
      title: 'استكشف المطابخ',
      sortOrder: 5,
      items: [
        HomeSectionItemModel(
          id: 'c1',
          sectionId: 'cuisines',
          title: 'مأكولات سريعة',
          imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400&q=80',
          sortOrder: 1,
        ),
        HomeSectionItemModel(
          id: 'c2',
          sectionId: 'cuisines',
          title: 'حلى',
          imageUrl: 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400&q=80',
          sortOrder: 2,
        ),
        HomeSectionItemModel(
          id: 'c3',
          sectionId: 'cuisines',
          title: 'عربي',
          imageUrl: 'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=400&q=80',
          sortOrder: 3,
        ),
        HomeSectionItemModel(
          id: 'c4',
          sectionId: 'cuisines',
          title: 'صحي',
          imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
          sortOrder: 4,
        ),
        HomeSectionItemModel(
          id: 'c5',
          sectionId: 'cuisines',
          title: 'قهوة',
          imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&q=80',
          sortOrder: 5,
        ),
      ],
    ),
  ];
}
