import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/delivery_address_service.dart';

class AddressSearchScreen extends StatefulWidget {
  final double? userLat;
  final double? userLng;

  const AddressSearchScreen({
    super.key,
    this.userLat,
    this.userLng,
  });

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    final results = await DeliveryAddressService.instance.searchPlaces(
      query,
      userLat: widget.userLat,
      userLng: widget.userLng,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  String _calculateDistance(double destLat, double destLng) {
    if (widget.userLat == null || widget.userLng == null) return '';
    final meters = Geolocator.distanceBetween(
      widget.userLat!,
      widget.userLng!,
      destLat,
      destLng,
    );
    final km = meters / 1000.0;
    if (km < 1.0) {
      return '${meters.toInt()} م';
    }
    return '${km.toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back arrow
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: textColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Yellow-bordered search text box
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF7C57FC),
                          width: 2.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _onSearch('');
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBDBDBD),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              onChanged: _onSearch,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن عنوان',
                                hintStyle: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 15,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1E2022),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                color: Color(0xFF7C57FC),
                backgroundColor: Color(0xFFF3F4F6),
              ),

            // Results List
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.isEmpty
                            ? 'ابحث عن مدينة، حي، أو شارع...'
                            : 'لا توجد نتائج مطابقة',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, idx) {
                        final item = _results[idx];
                        final title = item['title'] as String? ?? '';
                        final fullAddress = item['fullAddress'] as String? ?? '';
                        final lat = item['latitude'] as double;
                        final lng = item['longitude'] as double;
                        final distance = _calculateDistance(lat, lng);

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Row(
                              children: [
                                if (distance.isNotEmpty)
                                  Text(
                                    distance,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                      if (fullAddress.isNotEmpty && fullAddress != title) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          fullAddress,
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 12.5,
                                            color: const Color(0xFF757575),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF757575),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),


          ],
        ),
      ),
    );
  }
}
