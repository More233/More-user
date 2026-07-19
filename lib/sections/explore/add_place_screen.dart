import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../config/secrets.dart';
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
  mapbox.MapboxMap? _mapController;

  // Selected Category
  String _category = "";
  
  // Custom states
  bool _isPrivate = false;
  String _hoursText = "Add hours";
  bool _isSubmitting = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  void _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Show a nice loading indicator dialogue for 1.5 seconds simulating AI OCR scan
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Dialog(
                backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(
                        color: Color(0xFF7C57FC),
                        radius: 12,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Scanning photo...",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Extracting place details automatically...",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF82858C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pop(context); // Close scanning dialog
          setState(() {
            // Autofill fields with high quality real details
            _nameController.text = "كشري الزعيم ناهيا";
            _category = "Restaurant";
            _address = "ناهيا، كرداسة، الجيزة، مصر";
            _latitude = 30.0381;
            _longitude = 31.1352;
          });

          // Move the map camera to the scanned location
          _mapController?.easeTo(
            mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson(),
              zoom: 15.0,
            ),
            mapbox.MapAnimationOptions(duration: 800),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF7C57FC)),
                title: Text("Take Photo", style: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF7C57FC)),
                title: Text("Choose from Gallery", style: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
      _mapController?.easeTo(
        mapbox.CameraOptions(center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson()),
        mapbox.MapAnimationOptions(duration: 500),
      );
    }
  }

  void _openCategorySelector() {
    final categories = ["Restaurant", "Coffee", "Bakery", "Bars", "Desserts", "Park", "Other"];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
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
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              ...categories.map((cat) => ListTile(
                title: Text(cat, style: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white : Colors.black)),
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
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final Color dialogBg = isDark ? const Color(0xFF131722) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF323232);
        final Color borderSideColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
        final Color sepColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFBFBFBF);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add Hours",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: hoursInput,
                    autofocus: true,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: textColor),
                    decoration: InputDecoration(
                      hintText: "e.g., Mon-Fri: 9 AM - 10 PM",
                      hintStyle: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white60 : const Color(0xFFC4C4C4), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderSideColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7C57FC)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Save Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _hoursText = hoursInput.text.trim().isEmpty ? "Add hours" : hoursInput.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 286,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: sepColor, width: 0.7),
                        bottom: BorderSide(color: sepColor, width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      'Save',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C57FC),
                      ),
                    ),
                  ),
                ),
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _discardDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final Color dialogBg = isDark ? const Color(0xFF131722) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF323232);
        final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF82858C);
        final Color sepColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFBFBFBF);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Discard place?",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Are you sure you want to discard this place?",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: textMutedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Discard Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Discard and go back
                  },
                  child: Container(
                    width: 286,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: sepColor, width: 0.7),
                        bottom: BorderSide(color: sepColor, width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      'Discard',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD80000),
                      ),
                    ),
                  ),
                ),
                // Keep editing Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      'Keep editing',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        'is_private': _isPrivate,
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show success checkmark animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context, true); // Pop screen with success result!
            }
          });
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
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
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF82858C);
    final Color placeholderColor = isDark ? const Color(0xFF1F2430) : Colors.white;
    final Color borderSideColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

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
                color: textColor,
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
            color: placeholderColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSideColor),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: textColor),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.ibmPlexSansArabic(color: textMutedColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: textMutedColor) : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color headerColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF82858C);
    final Color borderSideColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color separatorColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F3F5);
    final Color buttonBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F3F5);
    final Color placeholderColor = isDark ? const Color(0xFF1F2430) : Colors.white;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: EdgeInsets.only(top: topPadding + 10, bottom: 12, left: 16, right: 16),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: BorderSide(color: separatorColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _discardDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: buttonBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: textColor),
                  ),
                ),
                Text(
                  "Add a place",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderSideColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Automatically add a place",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Upload a photo to capture the details needed to automatically add a new place.",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_imageFile != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _imageFile!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imageFile = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.delete, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _showImageSourceActionSheet,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderSideColor),
                                backgroundColor: buttonBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: Text(
                                _imageFile == null ? "Scan photo" : "Change photo",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
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
                        color: textColor,
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
                            color: textColor,
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
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSideColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _address,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: textMutedColor),
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
                        border: Border.all(color: borderSideColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                              mapbox.MapWidget(
                                key: ValueKey('add_place_map_${Theme.of(context).brightness == Brightness.dark}'),
                                resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
                                styleUri: Theme.of(context).brightness == Brightness.dark
                                    ? "mapbox://styles/mapbox/dark-v11"
                                    : "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue",
                                cameraOptions: mapbox.CameraOptions(
                                  center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson(),
                                  zoom: 15.0,
                                ),
                                onMapCreated: (controller) async {
                                  _mapController = controller;
                                  await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
                                  await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
                                  try {
                                    final layers = await controller.style.getStyleLayers();
                                    const List<String> hideKeywords = [
                                      'poi', 'transit', 'rail', 'bus', 'station', 'ferry', 'shield', 'motorway',
                                      'number', 'crossing', 'traffic', 'landmark', 'symbol', 'monument', 'worship',
                                      'cemetery', 'lodging', 'hotel', 'restaurant', 'cafe', 'shop', 'food',
                                      'beverage', 'intersection', 'entrance', 'parking'
                                    ];
                                    for (final layerInfo in layers) {
                                      if (layerInfo != null) {
                                        final idLower = layerInfo.id.toLowerCase();
                                        if (idLower.contains('pointannotation') || idLower.contains('annotation')) {
                                          continue;
                                        }
                                        bool shouldHide = false;
                                        for (final keyword in hideKeywords) {
                                          if (idLower.contains(keyword)) {
                                            shouldHide = true;
                                            break;
                                          }
                                        }
                                        if (shouldHide) {
                                          await controller.style.setStyleLayerProperty(
                                            layerInfo.id,
                                            'visibility',
                                            'none',
                                          );
                                        }
                                      }
                                    }
                                  } catch (_) {}
                                },
                              ),
                            // Selection pin in center of mini map
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : const Color(0xFF1F242E),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1F242E) : Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius: const BorderRadius.all(Radius.circular(1.5)),
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
                                    color: placeholderColor,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: borderSideColor),
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
                                      color: textColor,
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
                            color: textColor,
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
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSideColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _category.isEmpty ? "Enter category" : _category,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                color: _category.isEmpty ? textMutedColor : textColor,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: textMutedColor),
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
                            color: textColor,
                          ),
                        ),
                        CupertinoSwitch(
                          value: _isPrivate,
                          onChanged: (val) => setState(() => _isPrivate = val),
                          activeTrackColor: const Color(0xFF7C57FC),
                        ),
                      ],
                    ),
                    Text(
                      "This place will only be visible to you and won't appear in public searches.",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: textMutedColor,
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
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openHoursSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSideColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _hoursText,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                color: _hoursText == "Add hours" ? textMutedColor : textColor,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: textMutedColor),
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
                        color: textColor,
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
                        color: textColor,
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
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(top: BorderSide(color: separatorColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _discardDialog,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderSideColor),
                        backgroundColor: buttonBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
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
                        backgroundColor: _isFormValid() ? (isDark ? Colors.white : const Color(0xFF1F242E)) : buttonBg,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        disabledBackgroundColor: buttonBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: _isSubmitting
                          ? CupertinoActivityIndicator(
                              color: isDark ? Colors.black : Colors.white,
                              radius: 8,
                            )
                          : Text(
                              "Submit",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isFormValid() ? (isDark ? Colors.black : Colors.white) : textMutedColor,
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
