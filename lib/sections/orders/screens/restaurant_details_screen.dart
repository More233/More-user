import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_customization_sheet.dart';
import 'cart_screen.dart';

class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  ConsumerState<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends ConsumerState<RestaurantDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<MenuCategoryModel> _categories = [];
  List<MenuItemModel> _items = [];
  List<MenuModifierModel> _modifiers = [];
  bool _loading = true;
  String _selectedCategoryId = '';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    try {
      final client = Supabase.instance.client;

      // 1. Categories
      final catRows = await client
          .from('menu_categories')
          .select()
          .eq('venue_id', widget.restaurant.id)
          .order('sort_order');

      final cats = (catRows as List)
          .map((m) => MenuCategoryModel.fromMap(m))
          .toList();

      // 2. Items
      final itemRows = await client
          .from('menu_items')
          .select()
          .eq('venue_id', widget.restaurant.id)
          .order('sort_order');

      final items = (itemRows as List)
          .map((m) => MenuItemModel.fromMap(m))
          .toList();

      // 3. Modifiers
      if (items.isNotEmpty) {
        final modRows = await client
            .from('menu_modifiers')
            .select()
            .inFilter('menu_item_id', items.map((i) => i.id).toList());

        final mods = (modRows as List)
            .map((m) => MenuModifierModel.fromMap(m))
            .toList();
        _modifiers = mods;
      }

      setState(() {
        _categories = cats;
        _items = items;
        if (cats.isNotEmpty) {
          _selectedCategoryId = cats.first.id;
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _openCustomization(MenuItemModel item) {
    HapticFeedback.lightImpact();
    final itemMods =
        _modifiers.where((m) => m.menuItemId == item.id).toList();
    final upsells = _items.where((i) => i.id != item.id).take(4).toList();

    ProductCustomizationSheet.show(
      context,
      restaurant: widget.restaurant,
      item: item,
      modifiers: itemMods,
      upsellItems: upsells,
    );
  }

  void _showCategoriesDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'أقسام قائمة الطعام',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E2022),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSel = _selectedCategoryId == cat.id;
                    final count =
                        _items.where((i) => i.categoryId == cat.id).length;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                        Navigator.pop(ctx);
                      },
                      leading: isSel
                          ? const Icon(Icons.check_rounded, color: Color(0xFF7C57FC))
                          : null,
                      trailing: Text(
                        '($count)',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      title: Text(
                        cat.name,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? const Color(0xFF7C57FC)
                              : (isDark ? Colors.white : const Color(0xFF1E2022)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    final cartState = ref.watch(cartProvider);
    final isCurrentRestaurantCart = cartState.restaurant?.id == r.id;
    final hasCartItems = isCurrentRestaurantCart && cartState.items.isNotEmpty;

    // Filter items by selected category
    final displayedItems = _selectedCategoryId.isNotEmpty
        ? _items.where((i) => i.categoryId == _selectedCategoryId).toList()
        : _items;

    final currentCatName = _categories
            .firstWhere(
              (c) => c.id == _selectedCategoryId,
              orElse: () => const MenuCategoryModel(
                  id: '', venueId: '', name: 'اختيارات على ذوقك 🔥'),
            )
            .name;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main Scroll View
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Cover Header with Top Navigation Buttons (Screenshot 2)
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover photo
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : const Color(0xFFE5E7EB),
                      ),
                      child: r.coverUrl != null && r.coverUrl!.isNotEmpty
                          ? Image.network(
                              r.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildCoverFallback(),
                            )
                          : _buildCoverFallback(),
                    ),

                    // Dark Top Overlay for icon visibility
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Action Buttons Row (Screenshot 2)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left actions: Search, Favorite, Group Order
                          Row(
                            children: [
                              _buildCircleIconBtn(
                                icon: Icons.search_rounded,
                                onTap: () {},
                              ),
                              const SizedBox(width: 10),
                              _buildCircleIconBtn(
                                icon: _isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _isFavorite
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF1E2022),
                                onTap: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Right action: Back Button (RTL back)
                          _buildCircleIconBtn(
                            icon: Icons.arrow_forward_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // 2. Floating Restaurant Info Card (Overlapping Cover, Screenshot 2)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: -130,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Logo + Name Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 14, color: Color(0xFF6B7280)),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      r.name,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.cuisineTypes.isNotEmpty
                                          ? r.cuisineTypes.join(', ')
                                          : 'الحلويات, حلويات عربية',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 12.5,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Rating & Badge
                                    Row(
                                      children: [
                                        if (r.isFeatured) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF7ED),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'مميز 🏆',
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFEA580C),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          '${r.rating.toStringAsFixed(1)} ★ ${r.reviewsFormatted}',
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Logo
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : const Color(0xFFEEEEEE),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: r.logoUrl != null &&
                                            r.logoUrl!.isNotEmpty
                                        ? Image.network(
                                            r.logoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildLogoFallback(),
                                          )
                                        : _buildLogoFallback(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Delivery Info Line (Screenshot 2)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 14, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 4),
                                Text(
                                  'التوصيل بواسطة More',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('•',
                                    style: TextStyle(
                                        color: Color(0xFF9CA3AF), fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  '🛵 ${r.deliveryFeeFormatted}',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('•',
                                    style: TextStyle(
                                        color: Color(0xFF9CA3AF), fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  r.deliveryTimeFormatted,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Promo Delivery Strip
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'توصيل مجاني لأول طلب',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF9A3412),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('🛵', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer for the overlapping floating card
              const SliverToBoxAdapter(child: SizedBox(height: 146)),

              // 3. Bank Promotion Banner Card (Screenshot 2)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // Light purple banner
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المزيد من المعلومات',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C57FC),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'خصم 30% مع More Pro وبطاقات الشركاء',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4C1D95),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.credit_card_rounded,
                              size: 18, color: Color(0xFF7C57FC)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Sticky Menu Categories TabBar (Screenshot 2)
              if (_categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Categories Drawer Icon Button
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          color: textColor,
                          onPressed: _showCategoriesDrawer,
                        ),

                        // Horizontal Category Tabs
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true, // RTL
                              itemCount: _categories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 18),
                              itemBuilder: (context, idx) {
                                final cat = _categories[idx];
                                final isSelected = _selectedCategoryId == cat.id;

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedCategoryId = cat.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF1E2022)
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      cat.name,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? textColor
                                            : (isDark
                                                ? Colors.white60
                                                : const Color(0xFF6B7280)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 5. Section Header (Screenshot 2: "اختيارات على ذوقك 🔥")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentCatName,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'منتجات رائجة ستنال إعجابك',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Products Grid (Screenshot 2)
              _loading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF7C57FC))),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = displayedItems[index];
                            return _buildProductCard(item, isDark, cardBg, textColor);
                          },
                          childCount: displayedItems.length,
                        ),
                      ),
                    ),

              // Bottom Padding for sticky cart bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // 7. Sticky Bottom Cart / Min Order Bar (Screenshot 2)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: hasCartItems
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C57FC).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${cartState.totalAmount.toStringAsFixed(2)} ج.م',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'عرض السلة (${cartState.totalCount})',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'أضف منتجات بقيمة ${widget.restaurant.minOrderAmount.toStringAsFixed(2)} ج.م لتبدأ الطلب',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      MenuItemModel item, bool isDark, Color cardBg, Color textColor) {
    return GestureDetector(
      onTap: () => _openCustomization(item),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Product Image + Circular Arrow (Screenshot 2)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17)),
                  child: Container(
                    height: 125,
                    width: double.infinity,
                    color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildItemPlaceholder(),
                          )
                        : _buildItemPlaceholder(),
                  ),
                ),

                // White circular arrow indicator (matching Screenshot 2)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),

                  // Base Price
                  Text(
                    '${item.price.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),

                  // Pro Price (Screenshot 2)
                  if (item.proPrice != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'pro ${item.proPrice!.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF1E2022),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCoverFallback() {
    return Container(
      color: const Color(0xFF7C57FC).withValues(alpha: 0.2),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: Color(0xFF7C57FC), size: 60),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.store_rounded, color: Color(0xFF0284C7), size: 28),
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Colors.grey, size: 36),
      ),
    );
  }
}
