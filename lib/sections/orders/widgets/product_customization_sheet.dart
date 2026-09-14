import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../providers/cart_provider.dart';

class ProductCustomizationSheet extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;
  final MenuItemModel item;
  final List<MenuModifierModel> modifiers;
  final List<MenuItemModel> upsellItems;

  const ProductCustomizationSheet({
    super.key,
    required this.restaurant,
    required this.item,
    this.modifiers = const [],
    this.upsellItems = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required RestaurantModel restaurant,
    required MenuItemModel item,
    List<MenuModifierModel> modifiers = const [],
    List<MenuItemModel> upsellItems = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductCustomizationSheet(
        restaurant: restaurant,
        item: item,
        modifiers: modifiers,
        upsellItems: upsellItems,
      ),
    );
  }

  @override
  ConsumerState<ProductCustomizationSheet> createState() =>
      _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState
    extends ConsumerState<ProductCustomizationSheet> {
  int _quantity = 1;
  final Set<ModifierOption> _selectedModifiers = {};

  // Quick preset options matching screenshot 3
  static const List<Map<String, dynamic>> _quickCombos = [
    {
      'title': 'نوتيلا + مكسرات',
      'price': 65.0,
      'badge': '+1k طلب',
      'items': ['نوتيلا', 'مكسرات']
    },
    {
      'title': 'بسبوسة + نوتيلا',
      'price': 50.0,
      'badge': '+800 طلب',
      'items': ['بسبوسة', 'نوتيلا']
    },
  ];

  int? _selectedComboIndex;

  @override
  void initState() {
    super.initState();
  }

  double _calculateTotal() {
    double mods = 0;
    for (final m in _selectedModifiers) {
      mods += m.price;
    }
    return (widget.item.price + mods) * _quantity;
  }

  void _onComboTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedComboIndex == index) {
        _selectedComboIndex = null;
        _selectedModifiers.clear();
      } else {
        _selectedComboIndex = index;
        _selectedModifiers.clear();
        final combo = _quickCombos[index];
        final itemNames = combo['items'] as List<String>;

        // Find matching modifiers
        for (final mod in widget.modifiers) {
          for (final opt in mod.options) {
            if (itemNames.contains(opt.name)) {
              _selectedModifiers.add(opt);
            }
          }
        }
      }
    });
  }

  void _toggleModifier(ModifierOption opt) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedComboIndex = null; // Customizing breaks preset
      if (_selectedModifiers.contains(opt)) {
        _selectedModifiers.remove(opt);
      } else {
        _selectedModifiers.add(opt);
      }
    });
  }

  void _handleAddToCart() {
    HapticFeedback.mediumImpact();
    ref.read(cartProvider.notifier).addItem(
          restaurant: widget.restaurant,
          item: widget.item,
          modifiers: _selectedModifiers.toList(),
          quantity: _quantity,
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة ${widget.item.name} إلى السلة',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E2022),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
    final total = _calculateTotal();

    // Collect available modifiers
    final modifierGroup = widget.modifiers.isNotEmpty
        ? widget.modifiers.first
        : MenuModifierModel(
            id: 'default',
            menuItemId: widget.item.id,
            name: 'إضافات ${widget.restaurant.name}',
            options: const [
              ModifierOption(name: 'بسبوسة', price: 25, isPopular: true),
              ModifierOption(name: 'نوتيلا', price: 25, isPopular: true),
              ModifierOption(name: 'مكسرات', price: 40, isPopular: false),
              ModifierOption(name: 'لوتس صوص', price: 35, isPopular: false),
              ModifierOption(name: 'لوتس بودر', price: 35, isPopular: false),
              ModifierOption(name: 'عسل نحل', price: 20, isPopular: false),
            ],
          );

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Hero Image with circular 'X' button (matching Screenshot 3)
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : const Color(0xFFF3F4F6),
                          ),
                          child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),
                      ),

                      // Circular Close button
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF1E2022),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Dish Title and Description
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.item.name,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 6),
                        if (widget.item.description != null && widget.item.description!.isNotEmpty)
                          Text(
                            widget.item.description!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.right,
                          ),
                      ],
                    ),
                  ),
                ),

                // 3. Quick Options Box ("جرب هذه الخيارات السريعة" - Screenshot 3)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED), // Warm soft peach
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'جرب هذه الخيارات السريعة',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2022),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'يمكنك تعديل اختياراتك من القائمة أدناه',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: const Color(0xFF78350F).withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Combo Cards Row
                        Row(
                          children: List.generate(_quickCombos.length, (index) {
                            final combo = _quickCombos[index];
                            final isSelected = _selectedComboIndex == index;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _onComboTapped(index),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? 8 : 0,
                                    right: index == 1 ? 8 : 0,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFFEA580C)
                                                    : const Color(0xFF9CA3AF),
                                                width: isSelected ? 5 : 1.5,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1F2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${combo['badge']} 🔥',
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFE11D48),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        combo['title'] as String,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E2022),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '+${(combo['price'] as double).toStringAsFixed(2)} ج.م',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1E2022),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Modifiers & Add-ons Section ("إضافات بلبن - اختر حتى 99 صنف")
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            modifierGroup.isRequired ? 'إجباري' : 'إختياري',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              modifierGroup.name,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'إختر حتى ${modifierGroup.maxSelections} صنف',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Modifiers Checkbox list items (Screenshot 3 & 4)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final opt = modifierGroup.options[index];
                      final isSelected = _selectedModifiers.contains(opt);

                      return InkWell(
                        onTap: () => _toggleModifier(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Checkbox
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFFD1D5DB),
                                    width: 1.8,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFEA580C)
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Price difference
                              Text(
                                '(+${opt.price.toStringAsFixed(2)} ج.م)',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                ),
                              ),

                              const Spacer(),

                              // Option Name & Fire Badge
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (opt.isPopular) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'شائع 🔥',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFE11D48),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Text(
                                    opt.name,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: modifierGroup.options.length,
                  ),
                ),

                // 5. Upsell Section: "تُطلب معًا" (Screenshot 4)
                if (widget.upsellItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAF9F6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'تُطلب معًا',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'عادةً ما يطلب المستخدمون هذه المنتجات أيضًا',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Upsell Items Horizontal List
                          SizedBox(
                            height: 175,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              reverse: true, // RTL natural scrolling
                              itemCount: widget.upsellItems.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 14),
                              itemBuilder: (context, idx) {
                                final upItem = widget.upsellItems[idx];
                                return Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(15)),
                                            child: Container(
                                              height: 95,
                                              width: double.infinity,
                                              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                              child: upItem.imageUrl != null
                                                  ? Image.network(
                                                      upItem.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          _buildImagePlaceholder(),
                                                    )
                                                  : _buildImagePlaceholder(),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 6,
                                            left: 6,
                                            child: GestureDetector(
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                ref.read(cartProvider.notifier).addItem(
                                                      restaurant: widget.restaurant,
                                                      item: upItem,
                                                      modifiers: [],
                                                      quantity: 1,
                                                    );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('تمت إضافة ${upItem.name} للسلة'),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.15),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.add_rounded,
                                                  color: Color(0xFFEA580C),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              upItem.name,
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${upItem.price.toStringAsFixed(2)} ج.م',
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),

          // 6. Sticky Bottom Add-to-Cart Bar (Screenshot 3 & 4)
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // CTA Add-to-Cart Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF95700), // Vibrant Orange matching Talabat
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        'أضف للسلة ${total.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Stepper [- 1 +]
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Plus
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        color: textColor,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Minus
                      IconButton(
                        onPressed: _quantity > 1
                            ? () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        color: _quantity > 1 ? textColor : Colors.grey,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Color(0xFF0284C7), size: 50),
      ),
    );
  }
}
