import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/delivery_address_model.dart';
import '../services/delivery_address_service.dart';

class DeliveryAddressDetailsScreen extends StatefulWidget {
  final String title;
  final String fullAddress;
  final double latitude;
  final double longitude;

  const DeliveryAddressDetailsScreen({
    super.key,
    required this.title,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<DeliveryAddressDetailsScreen> createState() => _DeliveryAddressDetailsScreenState();
}

class _DeliveryAddressDetailsScreenState extends State<DeliveryAddressDetailsScreen> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAndContinue() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final region = DeliveryAddressService.instance.findCoveredRegion(widget.latitude, widget.longitude);
    final model = DeliveryAddressModel(
      title: widget.title,
      fullAddress: widget.fullAddress,
      details: _detailsController.text.trim(),
      latitude: widget.latitude,
      longitude: widget.longitude,
      isCovered: region != null,
      regionId: region?.id,
      regionName: region?.name,
    );

    await DeliveryAddressService.instance.saveAddress(model);

    if (mounted) {
      setState(() => _isSaving = false);
      // Pop all the way back to Orders home
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'عنوان التوصيل',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: CNButton.icon(
                icon: const CNSymbol('arrow.forward', size: 18),
                style: CNButtonStyle.glass,
                size: 40,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],

      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Location Preview
                    Text(
                      'موقع التوصيل',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (widget.fullAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.fullAddress,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13.5,
                          color: const Color(0xFF616161),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Address Details Section
                    Text(
                      'تفاصيل العنوان',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تفاصيل العنوان ستساعدنا في التوصيل',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),

                    // Input Box
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: _detailsController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14.5,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'مثال: رقم البناية، رقم الفيلا، رقم الشقة',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button: "الحفظ والمتابعة"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onSaveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'الحفظ والمتابعة',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
