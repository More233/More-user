import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_picker_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  final double currentLat;
  final double currentLng;

  const AddPlaceScreen({
    super.key,
    required this.currentLat,
    required this.currentLng,
  });

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _withinController = TextEditingController();
  final TextEditingController _chainController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();

  // Selected Location
  late double _latitude;
  late double _longitude;
  String _address = "Cairo, Cairo 11568, Egypt";
  GoogleMapController? _mapController;

  // Selected Category
  String _category = "";
  
  // Custom states
  bool _isPrivate = false;
  String _hoursText = "Add hours";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.currentLat;
    _longitude = widget.currentLng;
    _address = "Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _withinController.dispose();
    _chainController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _xController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _address.trim().isNotEmpty &&
        _category.trim().isNotEmpty;
  }

  void _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
        _address = result['address'] as String;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(_latitude, _longitude)),
      );
    }
  }

  void _openCategorySelector() {
    final categories = ["Restaurant", "Coffee", "Bakery", "Bars", "Desserts", "Park", "Other"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Category",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              ...categories.map((cat) => ListTile(
                title: Text(cat, style: GoogleFonts.ibmPlexSansArabic()),
                trailing: _category == cat ? const Icon(Icons.check, color: Color(0xFF7C57FC)) : null,
                onTap: () {
                  setState(() => _category = cat);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _openHoursSelector() {
    final TextEditingController hoursInput = TextEditingController(text: _hoursText == "Add hours" ? "" : _hoursText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Hours", style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: hoursInput,
          decoration: const InputDecoration(hintText: "e.g., Mon-Fri: 9 AM - 10 PM"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _hoursText = hoursInput.text.trim().isEmpty ? "Add hours" : hoursInput.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _discardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Discard place?",
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to discard this place?",
          style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF82858C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Keep editing",
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, color: const Color(0xFF7C57FC)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Discard and go back
            },
            child: Text(
              "Discard",
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _submitPlace() async {
    if (!_isFormValid()) return;
    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      // Insert custom venue into custom_venues table in Supabase
      await client.from('custom_venues').insert({
        'name': _nameController.text.trim(),
        'address': _address,
        'latitude': _latitude,
        'longitude': _longitude,
        'category_name': _category,
        'user_id': user?.id,
        // Since other fields may not exist as columns yet in public.custom_venues,
        // we can store them in a JSONB 'meta' column if it exists, or just omit them
        // to avoid database constraints, or store them safely.
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show success checkmark animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context, true); // Pop screen with success result!
            }
          });
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF4CAF50),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Place added successfully!",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding place: $e")),
        );
      }
    }
  }

  Widget _buildTextFieldCard({
    required String label,
    required String hintText,
    required TextEditingController controller,
    IconData? icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            if (isRequired)
              const Text(
                "*",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF82858C)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF82858C)) : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: EdgeInsets.only(top: topPadding + 10, bottom: 12, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _discardDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A2E)),
                  ),
                ),
                Text(
                  "Add a place",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Automatically add place box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Automatically add a place",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Upload a photo to capture the details needed to automatically add a new place.",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: const Color(0xFF82858C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Photo scanning is mocked for testing.")),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE8E8E8)),
                                backgroundColor: const Color(0xFFF1F3F5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: Text(
                                "Scan photo",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Place Information",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Place name field
                    _buildTextFieldCard(
                      label: "Place name",
                      hintText: "Enter place name",
                      controller: _nameController,
                      isRequired: true,
                    ),

                    // Address field
                    Row(
                      children: [
                        Text(
                          "Address",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const Text(
                          "*",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _address,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 15,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF82858C)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mini map container
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_latitude, _longitude),
                                zoom: 15.0,
                              ),
                              onMapCreated: (controller) => _mapController = controller,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                            ),
                            // Selection pin in center of mini map
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1F242E),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(Radius.circular(1.5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Edit map location button overlay
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: _openLocationPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: const Color(0xFFE8E8E8)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "Edit map location",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category field
                    Row(
                      children: [
                        Text(
                          "Category",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const Text(
                          "*",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openCategorySelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _category.isEmpty ? "Enter category" : _category,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                color: _category.isEmpty ? const Color(0xFF82858C) : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF82858C)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Private place switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Private place",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (val) => setState(() => _isPrivate = val),
                          activeThumbColor: const Color(0xFF7C57FC),
                          activeTrackColor: const Color(0xFF7C57FC).withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    Text(
                      "This place will only be visible to you and won't appear in public searches.",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: const Color(0xFF82858C),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Located within
                    _buildTextFieldCard(
                      label: "Located within",
                      hintText: "e.g., JFK International Airport",
                      controller: _withinController,
                      icon: Icons.search,
                    ),

                    // Chain or Franchise
                    _buildTextFieldCard(
                      label: "Chain or Franchise",
                      hintText: "Search chain or franchise",
                      controller: _chainController,
                      icon: Icons.search,
                    ),

                    // Hours section
                    Text(
                      "Hours",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openHoursSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _hoursText,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                color: _hoursText == "Add hours" ? const Color(0xFF82858C) : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF82858C)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Contact",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextFieldCard(
                      label: "Phone Number",
                      hintText: "Enter phone number",
                      controller: _phoneController,
                    ),
                    _buildTextFieldCard(
                      label: "Website",
                      hintText: "Enter website",
                      controller: _websiteController,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Socials",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextFieldCard(
                      label: "X (Twitter)",
                      hintText: "Enter X handle",
                      controller: _xController,
                    ),
                    _buildTextFieldCard(
                      label: "Instagram",
                      hintText: "Enter Instagram handle",
                      controller: _instagramController,
                    ),
                    _buildTextFieldCard(
                      label: "Facebook",
                      hintText: "Enter Facebook page name",
                      controller: _facebookController,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Persistent Action Buttons (Cancel / Submit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _discardDialog,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8E8E8)),
                        backgroundColor: const Color(0xFFF1F3F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isFormValid() && !_isSubmitting) ? _submitPlace : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid() ? const Color(0xFF1F242E) : const Color(0xFFF1F3F5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF1F3F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(
                              "Submit",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isFormValid() ? Colors.white : const Color(0xFF82858C),
                              ),
                            ),
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
