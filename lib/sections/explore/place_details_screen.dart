import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onActionTriggered;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.onActionTriggered,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late bool _isSaved;
  late List<String> _images;
  int _currentPage = 0;
  late List<Map<String, dynamic>> _visitors;
  bool _hasCheckedIn = false;
  int? _selectedRatingIndex; // 0: Sad, 1: Okay, 2: Happy
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ratingSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place['isSaved'] as bool? ?? false;
    _images = _getPlaceImages(
      widget.place['type']?.toString() ?? 'Other',
      widget.place['id']?.toString() ?? '',
    );
    final rawVisitors = widget.place['visitors'] as List?;
    _visitors = rawVisitors != null ? List<Map<String, dynamic>>.from(rawVisitors.map((v) => Map<String, dynamic>.from(v as Map))) : [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getPlaceImages(String type, String id) {
    final String defaultImg = widget.place['imageUrl']?.toString() ??
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600';
    
    switch (type) {
      case 'Coffee':
        return [
          defaultImg,
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600',
          'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=600',
          'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=600',
        ];
      case 'Bakery':
        return [
          defaultImg,
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
          'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600',
          'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600',
        ];
      case 'Bars':
        return [
          defaultImg,
          'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=600',
          'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=600',
          'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=600',
        ];
      case 'Restaurant':
      default:
        return [
          defaultImg,
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600',
        ];
    }
  }

  void _scrollToRatingSection() {
    final context = _ratingSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitReview() {
    if (_selectedRatingIndex == null) return;
    String status = "";
    if (_selectedRatingIndex == 0) status = "Sad/Bad";
    if (_selectedRatingIndex == 1) status = "Okay";
    if (_selectedRatingIndex == 2) status = "Happy/Great";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم إرسال تقييمك ($status) بنجاح!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        backgroundColor: const Color(0xFF7C57FC),
      ),
    );
  }

  void _showAddTipDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "إضافة نصيحة للمكان",
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "أكتب نصيحتك أو انطباعك هنا...",
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "إلغاء",
                style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF82858C)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "شكراً لمشاركتك! تم إضافة نصيحتك بنجاح.",
                      style: GoogleFonts.ibmPlexSansArabic(),
                    ),
                    backgroundColor: const Color(0xFF7C57FC),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "حفظ",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sharePlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم نسخ رابط المكان لمشاركته!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  void _performCheckIn() {
    if (_hasCheckedIn) return;
    setState(() {
      _hasCheckedIn = true;
      _visitors.insert(0, {
        'name': 'أنت',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      });
      final placeVisitors = widget.place['visitors'] as List?;
      if (placeVisitors != null) {
        widget.place['visitors'] = [
          {
            'name': 'أنت',
            'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
          },
          ...placeVisitors,
        ];
      } else {
        widget.place['visitors'] = [
          {
            'name': 'أنت',
            'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
          }
        ];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم تسجيل تواجدك في المكان بنجاح!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        backgroundColor: const Color(0xFF7C57FC),
      ),
    );

    widget.onActionTriggered();
  }

  Widget _buildCheckInSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Who's here now",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 12),
        if (_visitors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  color: Color(0xFF82858C),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  "لم يقم أحد بتسجيل التواجد بعد. كن أول من يفعل ذلك!",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF636268),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _performCheckIn,
                  icon: const Icon(Icons.location_on, size: 16, color: Colors.white),
                  label: Text(
                    "تسجيل التواجد",
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _visitors.length == 1 ? 24.0 : (_visitors.length == 2 ? 38.0 : 52.0),
                  height: 24,
                  child: Stack(
                    children: List.generate(_visitors.length > 3 ? 3 : _visitors.length, (index) {
                      final visitor = _visitors[index];
                      final avatarUrl = visitor['avatarUrl'] as String?;
                      
                      Widget avatarChild;
                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        avatarChild = CircleAvatar(
                          radius: 11,
                          backgroundImage: NetworkImage(avatarUrl),
                        );
                      } else {
                        final initials = visitor['name']
                            .toString()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase();
                        avatarChild = CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFFEDE6FC),
                          child: Text(
                            initials.isNotEmpty ? initials : '?',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C57FC),
                            ),
                          ),
                        );
                      }
                      
                      return Positioned(
                        left: index * 14.0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: avatarChild,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final int count = _visitors.length;
                      String text = '';
                      if (count == 1) {
                        text = '${_visitors[0]['name']} متواجد هنا الآن.';
                      } else if (count == 2) {
                        text = '${_visitors[0]['name']} و ${_visitors[1]['name']} متواجدان هنا.';
                      } else {
                        text = '${_visitors[0]['name']}، ${_visitors[1]['name']} و ${count - 2} آخرين متواجدون هنا.';
                      }
                      return Text(
                        text,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: const Color(0xFF636268),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                  ),
                ),
                if (!_hasCheckedIn) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _performCheckIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE6FC),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "تسجيل",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEDE6FC) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF1F242E),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF1F242E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCategoryCard(String label, String imageUrl) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF82858C),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildGreyPillButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F242E),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow({
    required IconData icon,
    required double progress,
    required String count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF82858C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF5F6F8),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF82858C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateOption(int index, IconData icon, String label) {
    final bool isSelected = _selectedRatingIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRatingIndex = index;
          });
        },
        child: Container(
          height: 80,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 6,
            right: index == 2 ? 0 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDE6FC) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                size: 28,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarPlaceCard({
    required String name,
    required String typeAndPrice,
    required String rating,
    required String reviews,
    required String imageUrl,
    required bool isHappy,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 100,
              width: 180,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1F242E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeAndPrice,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF82858C),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isHappy ? Icons.sentiment_satisfied_alt : Icons.sentiment_very_dissatisfied,
                      color: isHappy ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$rating ($reviews)",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F242E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final place = widget.place;
    
    final ratingVal = place['rating'] as num? ?? 7.9;
    final reviewsCount = place['reviewsCount'] as int? ?? 36;
    final distanceStr = place['distance']?.toString() ?? '1.1 km';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Swipable Hero Header Image Stack
          Stack(
            children: [
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: _images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      _images[index],
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),

              // Back button (dark circular card)
              Positioned(
                top: topPadding + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Three-dot action button (dark circular card)
              Positioned(
                top: topPadding + 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Image index indicator e.g. "1/18"
              Positioned(
                bottom: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "${_currentPage + 1}/${_images.length}",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Details Content Scroll View
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    place['name']?.toString() ?? 'Maxim Pizza & Restaurant',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Metadata Subtitle
                  Text(
                    "${place['type'] ?? 'Pizzeria'} • ${place['address'] ?? 'Zagazig, Eastern'} • ${place['price'] ?? '\$\$\$\$'} • $distanceStr",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF82858C),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Overall Rating Row
                  Row(
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt,
                        color: Color(0xFF1F242E),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$ratingVal",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "($reviewsCount)",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Photos Section
                  Text(
                    "Photos",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPhotoCategoryCard("All", _images[0]),
                        _buildPhotoCategoryCard("Food/Drink", _images[1]),
                        _buildPhotoCategoryCard("People", _images[2]),
                        _buildPhotoCategoryCard("Menu", _images[3]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    "About",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // About Items List
                  _buildInfoRow(
                    icon: Icons.restaurant,
                    child: Text(
                      "View Menu",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F242E),
                      ),
                    ),
                  ),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    child: Row(
                      children: [
                        _buildGreyPillButton("Add hours", () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "تم فتح شاشة تعديل أوقات العمل",
                                style: GoogleFonts.ibmPlexSansArabic(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  _buildInfoRow(
                    icon: Icons.phone,
                    child: Text(
                      "055 2353070",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                    ),
                  ),
                  _buildInfoRow(
                    icon: Icons.language,
                    child: Row(
                      children: [
                        _buildGreyPillButton("Add website", () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "تم فتح شاشة إضافة الموقع الإلكتروني",
                                style: GoogleFonts.ibmPlexSansArabic(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  _buildInfoRow(
                    icon: Icons.link,
                    child: Text(
                      place['name']?.toString() ?? 'Maxim Pizza & Restaurant',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                    ),
                  ),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Qaumiyyah, Zagazig",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: const Color(0xFF1F242E),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mapbox Preview Container
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: Stack(
                            children: [
                              // Styled Mapbox Canvas image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600',
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Marker Center
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                              ),
                              // Mapbox Logo attribution
                              Positioned(
                                bottom: 8,
                                left: 12,
                                child: Text(
                                  "mapbox",
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Suggest edit
                        Row(
                          children: [
                            const Icon(Icons.edit, color: Color(0xFF82858C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Suggest an edit",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF1F242E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // See more info
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "See more information",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F242E),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF82858C)),
                      ],
                    ),
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),
                  _buildCheckInSection(),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  // Rating section
                  Row(
                    key: _ratingSectionKey,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rating",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ratings summary and progress bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$ratingVal",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F242E),
                            ),
                          ),
                          Text(
                            "$reviewsCount ratings",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: const Color(0xFF82858C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingRow(
                              icon: Icons.sentiment_satisfied_alt,
                              progress: 0.8,
                              count: "24",
                            ),
                            _buildRatingRow(
                              icon: Icons.sentiment_neutral,
                              progress: 0.2,
                              count: "6",
                            ),
                            _buildRatingRow(
                              icon: Icons.sentiment_very_dissatisfied,
                              progress: 0.05,
                              count: "1",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating community guide box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.face,
                          color: Color(0xFF82858C),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your review will serve as a guide to your friends and the Swarm community.",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: const Color(0xFF636268),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Smiley Face selectors
                  Row(
                    children: [
                      _buildRateOption(0, Icons.sentiment_very_dissatisfied, ""),
                      _buildRateOption(1, Icons.sentiment_satisfied, "Okay"),
                      _buildRateOption(2, Icons.sentiment_very_satisfied, ""),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Submit Rating Button
                  GestureDetector(
                    onTap: _submitReview,
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F242E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Submit",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // What people are saying section
                  Text(
                    "What people are saying",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tips chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text("Great pizza", style: GoogleFonts.ibmPlexSansArabic(fontSize: 13)),
                        backgroundColor: const Color(0xFFF5F6F8),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      Chip(
                        label: Text("Fast service", style: GoogleFonts.ibmPlexSansArabic(fontSize: 13)),
                        backgroundColor: const Color(0xFFF5F6F8),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      Chip(
                        label: Text("Nice staff", style: GoogleFonts.ibmPlexSansArabic(fontSize: 13)),
                        backgroundColor: const Color(0xFFF5F6F8),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // See all tips button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "تم الانتقال لجميع النصائح والتعليقات",
                            style: GoogleFonts.ibmPlexSansArabic(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "See all tips",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Insights section
                  Text(
                    "Insights",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Insights Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Visitors",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      color: const Color(0xFF82858C),
                                    ),
                                  ),
                                  Text(
                                    "287",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F242E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Visits",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      color: const Color(0xFF82858C),
                                    ),
                                  ),
                                  Text(
                                    "663",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F242E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE8E8E8)),
                        
                        // Mayor
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Mohamed H. is the Mayor",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F242E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Added by
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Added by Aven Fauzi on 21 Nov 2011",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  color: const Color(0xFF82858C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Similar Places Section
                  Text(
                    "Similar places",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSimilarPlaceCard(
                          name: "Alexandria Pizza",
                          typeAndPrice: "Pizzeria • \$\$\$\$",
                          rating: "5.2",
                          reviews: "17",
                          imageUrl: 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=300',
                          isHappy: false,
                        ),
                        _buildSimilarPlaceCard(
                          name: "7days Pizza",
                          typeAndPrice: "Pizzeria • \$\$\$\$",
                          rating: "6.1",
                          reviews: "46",
                          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300',
                          isHappy: false,
                        ),
                        _buildSimilarPlaceCard(
                          name: "Quatro Pizza",
                          typeAndPrice: "Pizzeria • \$\$\$",
                          rating: "7.1",
                          reviews: "36",
                          imageUrl: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=300',
                          isHappy: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Floating persistent Bottom Actions Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding > 0 ? bottomPadding + 6 : 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildBottomActionButton(
                  label: "Save",
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  isActive: _isSaved,
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                      place['isSaved'] = _isSaved;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildBottomActionButton(
                  label: "Rate",
                  icon: Icons.sentiment_satisfied_alt,
                  isActive: _selectedRatingIndex != null,
                  onTap: _scrollToRatingSection,
                ),
                const SizedBox(width: 8),
                _buildBottomActionButton(
                  label: "Add a tip",
                  icon: Icons.edit,
                  isActive: false,
                  onTap: _showAddTipDialog,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sharePlace,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6F8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFF1F242E),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
