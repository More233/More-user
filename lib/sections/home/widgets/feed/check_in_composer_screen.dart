import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../../../../config/secrets.dart';
import '../../models/timeline_post.dart';
import '../../../explore/services/explore_data_service.dart';
import '../../gallery_picker_screen.dart';
import '../bottom_sheets/add_friends_bottom_sheet.dart';
import '../bottom_sheets/intro_bottom_sheet.dart';
import 'posting_loading_screen.dart';
import '../bottom_sheets/location_search_sheet.dart';
import '../common/die_cut_sticker.dart';

class CheckInComposerScreen extends StatefulWidget {
  final bool isFirstCheckIn;
  final TimelinePost? editPost;
  final Map<String, dynamic>? prefilledPlace;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;
  final String? initialLocationAddress;

  const CheckInComposerScreen({
    super.key,
    this.isFirstCheckIn = false,
    this.editPost,
    this.prefilledPlace,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
    this.initialLocationAddress,
  });

  @override
  State<CheckInComposerScreen> createState() => _CheckInComposerScreenState();
}

class _CheckInComposerScreenState extends State<CheckInComposerScreen> {
  static String? _cachedUserAvatarUrl;


  final TextEditingController _captionController = TextEditingController();
  String _locationName = "Helnan Auberge El Fayoum Hotel";
  String _locationAddress = "Muhafazat al Fayyūm, Egypt";
  String _categoryName = "Hotel";
  
  List<String> _selectedImages = [];
  List<Map<String, dynamic>> _taggedFriends = [];
  bool _isPrivate = false;
  int _selectedStickerIndex = -1; // -1 means none selected
  bool _isStickerTrayOpen = false;
  String? _currentUserAvatarUrl;
  bool _isSaving = false;

  mapbox.MapboxMap? _mapController;
  double _latitude = 29.378033;
  double _longitude = 30.697478;
  String? _placeId;
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    _currentUserAvatarUrl = _cachedUserAvatarUrl;
    _fetchUserProfile();
    if (widget.editPost != null) {
      final post = widget.editPost!;
      _locationName = post.title;
      _locationAddress = post.locationAddress;
      _categoryName = post.categoryName;
      final match = LocationSearchSheet.locations.firstWhere(
        (loc) => loc['name'] == post.title || loc['address'] == post.locationAddress,
        orElse: () => LocationSearchSheet.locations.first,
      );
      _latitude = match['latitude'] as double;
      _longitude = match['longitude'] as double;
      _captionController.text = post.description;
      _isPrivate = post.isPrivate;
      _selectedStickerIndex = post.stickerIndex;
      _isStickerTrayOpen = post.stickerIndex != -1;
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        _selectedImages = List<String>.from(post.imageUrls);
      }
      _taggedFriends = post.taggedFriends.map((name) => {'name': name}).toList();
    } else if (widget.prefilledPlace != null) {
      final place = widget.prefilledPlace!;
      _locationName = place['name'] as String? ?? '';
      _locationAddress = place['address'] as String? ?? '';
      _latitude = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
      _longitude = (place['longitude'] as num?)?.toDouble() ?? 30.697478;
      _placeId = place['id'] as String?;
      _categoryName = place['type'] as String? ?? 'Hotel';
    } else if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitude = widget.initialLatitude!;
      _longitude = widget.initialLongitude!;
      _locationName = widget.initialLocationName ?? "Loading location...";
      _locationAddress = widget.initialLocationAddress ?? "";
      _loadLocationFromCoordinates(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _loadCurrentGPSLocationAndNearestPlace();
      if (widget.isFirstCheckIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIntroBottomSheet();
        });
      }
    }
  }

  Future<void> _loadCurrentGPSLocationAndNearestPlace() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        
        final double lat = position.latitude;
        final double lng = position.longitude;
        
        if (mounted) {
          setState(() {
            _latitude = lat;
            _longitude = lng;
            _locationName = "Loading location...";
            _locationAddress = "";
          });
        }

        await _fetchPlaceOrGeocode(lat, lng);
      }
    } catch (e) {
      debugPrint("Error loading current GPS and nearest place: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final data = await client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['avatar_url'] != null && mounted) {
          setState(() {
            _currentUserAvatarUrl = data['avatar_url'] as String?;
            _cachedUserAvatarUrl = _currentUserAvatarUrl;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  Future<void> _loadLocationFromCoordinates(double lat, double lng) async {
    await _fetchPlaceOrGeocode(lat, lng);
  }

  Future<void> _fetchPlaceOrGeocode(double lat, double lng) async {
    try {
      final results = await ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng, radius: 1000);
      
      Map<String, dynamic>? bestPlace;
      if (results.isNotEmpty) {
        for (final res in results) {
          final type = res['type'] as String? ?? '';
          if (type != 'Other') {
            bestPlace = res;
            break;
          }
        }
        bestPlace ??= results.first;
      }

      if (bestPlace != null) {
        final name = bestPlace['name'] as String? ?? 'My Location';
        final address = bestPlace['address'] as String? ?? '';
        final plat = bestPlace['latitude'] as double;
        final plng = bestPlace['longitude'] as double;
        final category = bestPlace['type'] as String? ?? 'Hotel';

        if (mounted) {
          setState(() {
            _locationName = name;
            _locationAddress = address;
            _latitude = plat;
            _longitude = plng;
            _placeId = bestPlace!['id'] as String?;
            _categoryName = category;
          });
          
          _mapController?.easeTo(
            mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson(),
              zoom: 15.0,
            ),
            mapbox.MapAnimationOptions(duration: 500),
          );
        }
        return;
      }

      // Fallback to coordinates
      if (mounted) {
        setState(() {
          _locationName = "My Location";
          _locationAddress = "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
          _latitude = lat;
          _longitude = lng;
        });
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  void _showIntroBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return IntroBottomSheet(
          onStartTap: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Sticker assets
  final List<Map<String, dynamic>> _stickers = [
    {
      'type': 'svg',
      'path': 'assets/home/icons/smile_outline.svg',
      'name': 'Smile',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/heart.png',
      'name': 'Heart',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/beer.png',
      'name': 'Beer',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/hands_face.png',
      'name': 'Shy/Clap',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/thumbs_up.png',
      'name': 'Thumbs Up',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/fire.png',
      'name': 'Fire',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/heart_eyes.png',
      'name': 'Heart Eyes',
    },
    {
      'type': 'image',
      'path': 'assets/home/images/plus_one.png',
      'name': '+1',
    },
  ];

  // Master list of custom stickers with Zenly-style illustrated concepts represented by emojis
  final List<Map<String, String>> _allStickers = [
    {'name': 'Newbie', 'emoji': '🥳'},
    {'name': 'Sunny', 'emoji': '😎'},
    {'name': 'Stormy', 'emoji': '⛈️'},
    {'name': 'Heart Container', 'emoji': '❤️'},
    {'name': 'Leap Day William', 'emoji': '🐸'},
    {'name': 'Fiery', 'emoji': '🔥'},
    {'name': 'Oh Hey', 'emoji': '👋'},
    {'name': 'Yea', 'emoji': '👍'},
    {'name': 'Beer?', 'emoji': '🍺'},
    {'name': 'ETA?', 'emoji': '⏰'},
    {'name': 'Vroom Vroom', 'emoji': '🚗'},
    {'name': 'Cabbie', 'emoji': '🚕'},
    {'name': 'Rouge', 'emoji': '💄'},
    {'name': 'T. P. Rolls', 'emoji': '🧻'},
    {'name': 'Lisa', 'emoji': '🖼️'},
    {'name': 'Side Effects', 'emoji': '💊'},
    {'name': 'Slugger', 'emoji': '⚾'},
    {'name': 'Do Not Disturb', 'emoji': '🚫'},
    {'name': 'Victory Lap', 'emoji': '🏁'},
    {'name': 'Old Glory', 'emoji': '🥧'},
    {'name': 'Sticky Situation', 'emoji': '🩹'},
    {'name': 'Baggs', 'emoji': '🛍️'},
    {'name': 'Prost!', 'emoji': '🍻'},
    {'name': 'The Great Outdoors', 'emoji': '🌲'},
    {'name': 'Retail Therapy', 'emoji': '🛒'},
    {'name': 'Spike', 'emoji': '🌵'},
    {'name': 'Parker', 'emoji': '👮'},
    {'name': 'Swimmies', 'emoji': '🛟'},
    {'name': 'iScream', 'emoji': '🍦'},
    {'name': 'Schmear', 'emoji': '🥯'},
    {'name': 'Dog\'s Best Friend', 'emoji': '🐶'},
    {'name': 'Manny Quin', 'emoji': '🕴️'},
    {'name': 'Sole Mate', 'emoji': '👠'},
    {'name': 'Trailblazer', 'emoji': '🥾'},
    {'name': 'Nessie', 'emoji': '🦕'},
    {'name': 'Opa', 'emoji': '🏛️'},
  ];

  Widget _buildStickerContainer(Map<String, dynamic> sticker, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF7C57FC) : (isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: sticker['type'] == 'svg'
          ? SvgPicture.asset(
              sticker['path'],
              fit: BoxFit.contain,
            )
          : sticker['type'] == 'emoji'
              ? Center(
                  child: DieCutSticker(
                    emoji: sticker['emoji'] ?? '',
                    size: 22,
                    strokeWidth: 5,
                  ),
                )
              : Image.asset(
                  sticker['path'],
                  fit: BoxFit.contain,
                ),
    );
  }

  void _showSearchStickersBottomSheet() {
    FocusScope.of(context).unfocus();
    String searchQuery = "";
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filtered = _allStickers.where((s) {
              final query = searchQuery.toLowerCase();
              return s['name']!.toLowerCase().contains(query);
            }).toList();
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131722) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C354A) : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Stickers",
                            style: GoogleFonts.ibmPlexSansArabic(
                              color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C354A) : const Color(0xFFF2F2F7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setSheetState(() {
                                searchQuery = val;
                              });
                            },
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: "Search stickers",
                              hintStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 15),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No stickers found",
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final name = item['name']!;
                              final emoji = item['emoji']!;
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _selectStickerFromSearch(name, emoji);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                        child: DieCutSticker(
                                          emoji: emoji,
                                          size: 42,
                                          strokeWidth: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        color: isDark ? Colors.white70 : const Color(0xFF5A5D67),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
            );
          },
        );
      },
    );
  }

  void _selectStickerFromSearch(String name, String emoji) {
    final masterIndex = _allStickers.indexWhere((s) => s['name'] == name);
    if (masterIndex != -1) {
      final dbIndex = 8 + masterIndex;
      setState(() {
        _selectedStickerIndex = dbIndex;
        _isStickerTrayOpen = true;
      });
    }
  }

  void _openGallery() async {
    final List<String>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPickerScreen(previouslySelected: _selectedImages),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedImages = result;
      });
    }
  }

  void _openAddFriends() async {
    final List<Map<String, dynamic>>? result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFriendsBottomSheet(previouslySelected: _taggedFriends),
    );

    if (result != null) {
      setState(() {
        _taggedFriends = result;
      });
    }
  }

  void _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    CategoryIconType iconType = CategoryIconType.building;
    if (_categoryName == 'Coffee') {
      iconType = CategoryIconType.coffee;
    }

    final newPost = TimelinePost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _locationName,
      categoryName: _categoryName,
      locationAddress: _locationAddress,
      visitorCount: 1,
      postTime: 'Today • Just now',
      description: caption,
      imageUrl: _selectedImages.isNotEmpty ? _selectedImages.join(',') : null,
      likesCount: 0,
      commentsCount: 0,
      categoryIcon: iconType,
      comments: [],
      isPrivate: _isPrivate,
      stickerIndex: _selectedStickerIndex,
      taggedFriends: _taggedFriends.map((f) => f['name'] as String).toList(),
      latitude: _latitude,
      longitude: _longitude,
      placeId: _placeId,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PostingLoadingScreen(
          newPost: newPost,
          selectedImages: _selectedImages,
          currentUserAvatarUrl: _currentUserAvatarUrl,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _saveChanges() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final client = Supabase.instance.client;
      final List<String> uploadedUrls = [];

      for (final imgPath in _selectedImages) {
        if (imgPath.startsWith('http://') || imgPath.startsWith('https://') || imgPath.startsWith('assets/')) {
          uploadedUrls.add(imgPath);
        } else if (imgPath.startsWith('/') || imgPath.startsWith('file:')) {
          final user = client.auth.currentUser;
          if (user != null) {
            final file = File(imgPath);
            final fileName = 'posts/${user.id}_${DateTime.now().millisecondsSinceEpoch}_${imgPath.split('/').last}';
            await client.storage.from('post-images').upload(
              fileName,
              file,
              fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
            );
            final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);
            uploadedUrls.add(publicUrl);
          }
        }
      }

      final String? finalImageUrl = uploadedUrls.isNotEmpty ? uploadedUrls.join(',') : null;

      await client.from('posts').update({
        'description': caption,
        'image_url': finalImageUrl,
        'is_private': _isPrivate,
        'sticker_index': _selectedStickerIndex,
        'tagged_friends': _taggedFriends.map((f) => f['name'] as String).toList(),
      }).eq('id', widget.editPost!.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error updating post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save changes: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_lastIsDark != null && _lastIsDark != isDark) {
      _lastIsDark = isDark;
      if (_mapController != null) {
        final newStyle = isDark
            ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
            : "mapbox://styles/mapbox/streets-v12";
        _mapController!.style.setStyleURI(newStyle);
      }
    } else {
      _lastIsDark = isDark;
    }

    final bool hasCaption = _captionController.text.trim().isNotEmpty;
    final int remainingChars = 160 - _captionController.text.length;
    final double topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
        children: [
          // Top Map Header Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Interactive Google Map Background
              SizedBox(
                width: double.infinity,
                height: 220 + topPadding,
                child: mapbox.MapWidget(
                  key: const ValueKey('check_in_composer_map_key'),
                  resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
                  styleUri: isDark
                      ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
                      : "mapbox://styles/mapbox/streets-v12",
                  cameraOptions: mapbox.CameraOptions(
                    center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson(),
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
                    await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
                  },
                  onStyleLoadedListener: (styleLoaded) async {
                    if (_mapController != null) {
                      try {
                        final layers = await _mapController!.style.getStyleLayers();
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
                              await _mapController!.style.setStyleLayerProperty(
                                layerInfo.id,
                                'visibility',
                                'none',
                              );
                            }
                          }
                        }
                      } catch (_) {}
                    }
                  },
                ),
              ),

              // 2. Map pin with user avatar in center
              Positioned(
                top: topPadding + 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/home/icons/location_pin.svg',
                        width: 80,
                        height: 80,
                      ),
                      Positioned(
                        top: 12,
                        child: Container(
                          width: 47,
                          height: 47,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF945CF6), width: 1.5),
                          ),
                          child: ClipOval(
                            child: _currentUserAvatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _currentUserAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Image.asset(
                                      'assets/home/images/element.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/home/images/element.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating Close Button at top-right
              Positioned(
                top: topPadding + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2433).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/home/icons/close.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : const Color(0xFF333333),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Horizontal Stickers Row overlapping the map bottom
              Positioned(
                bottom: -20,
                left: 16,
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Toggle Button (purple circle with white smiley face matching story viewer)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isStickerTrayOpen = !_isStickerTrayOpen;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC), // Solid purple matching story
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE8E8E8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/home/icons/smile.svg',
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    
                    // Sliding Animated Tray containing remaining stickers
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: _isStickerTrayOpen ? Curves.easeOutBack : Curves.easeOut,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      width: _isStickerTrayOpen
                          ? ((40.0 + 8.0) * (8 + (_selectedStickerIndex >= 8 ? 1 : 0)) - 8.0).clamp(
                              0.0,
                              MediaQuery.of(context).size.width - 80.0,
                            )
                          : 0,
                      height: 40,
                      margin: EdgeInsets.only(left: _isStickerTrayOpen ? 8 : 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isStickerTrayOpen ? 1.0 : 0.0,
                          child: Row(
                            children: () {
                              final List<Widget> trayItems = [];
                              
                              // 1. Default stickers (indices 1 to 7)
                              for (int i = 1; i <= 7; i++) {
                                final sticker = _stickers[i];
                                final bool isSelected = _selectedStickerIndex == i;
                                trayItems.add(
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedStickerIndex = isSelected ? -1 : i;
                                        });
                                      },
                                      child: _buildStickerContainer(sticker, isSelected),
                                    ),
                                  ),
                                );
                              }
                              
                              // 2. Custom sticker (index >= 8) if selected
                              if (_selectedStickerIndex >= 8) {
                                final customIndex = _selectedStickerIndex - 8;
                                if (customIndex >= 0 && customIndex < _allStickers.length) {
                                  final customSticker = _allStickers[customIndex];
                                  final stickerMap = {
                                    'type': 'emoji',
                                    'emoji': customSticker['emoji'],
                                    'name': customSticker['name'],
                                  };
                                  trayItems.add(
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedStickerIndex = -1;
                                          });
                                        },
                                        child: _buildStickerContainer(stickerMap, true),
                                      ),
                                    ),
                                  );
                                }
                              }
                              
                              // 3. Search button
                              trayItems.add(
                                GestureDetector(
                                  onTap: () {
                                    _showSearchStickersBottomSheet();
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2433) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.search,
                                      color: isDark ? Colors.white : const Color(0xFF5A5D67),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                              
                              return trayItems;
                            }(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Scrollable Card Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Hotel Info Header
                  Center(
                    child: GestureDetector(
                      onTap: _openChangeLocation,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          Text(
                            _locationName,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF303030),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.editPost != null ? _locationAddress : "Change location",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C57FC).withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text Area Caption Input
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2433) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF2C354A) : const Color(0xFFD4D4D4)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _captionController,
                          maxLength: 160,
                          maxLines: null,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF303030),
                          ),
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: "What're you up to?",
                            hintStyle: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                        // Character counter overlay in the bottom right corner
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            '$remainingChars',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional Add Photos dashed button
                  if (_selectedImages.isEmpty) ...[
                    GestureDetector(
                      onTap: _openGallery,
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.7),
                          borderRadius: 12,
                        ),
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2433) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : const Color(0xFF7C57FC).withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/home/icons/add_photos.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Add photos (Optional)",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7C57FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Selected Images Previews Grid
                  if (_selectedImages.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(_selectedImages.length, (index) {
                            final imgPath = _selectedImages[index];
                            final isNetwork = imgPath.startsWith('http://') || imgPath.startsWith('https://');
                            final isAsset = !isNetwork && !imgPath.startsWith('/') && !imgPath.startsWith('file:');
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2433) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black26 : const Color(0xFF7C57FC).withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isNetwork
                                        ? CachedNetworkImage(
                                            imageUrl: imgPath,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: CupertinoActivityIndicator(
                                                  color: Color(0xFF7C57FC),
                                                  radius: 8,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          )
                                        : isAsset
                                            ? Image.asset(
                                                imgPath,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(imgPath),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          // Add Photos dashed card
                          GestureDetector(
                            onTap: _openGallery,
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: const Color(0xFF7C57FC).withValues(alpha: 0.7),
                                borderRadius: 12,
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C57FC).withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/home/icons/add_photos.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF7C57FC),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Check-in With Friends tag widgets
                  Text(
                    "Check-in with",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF121212),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_taggedFriends.isEmpty)
                    GestureDetector(
                      onTap: _openAddFriends,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2541) : const Color(0xFFEDE6FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/home/icons/add_friends.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                isDark ? const Color(0xFF9F85FF) : const Color(0xFF7C57FC),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Add friends",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF9F85FF) : const Color(0xFF7C57FC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _openAddFriends,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF8F6FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2C354A) : const Color(0xFFEDE6FC)),
                        ),
                        child: Row(
                          children: [
                            // Overlapping Avatars Group
                            SizedBox(
                              height: 44,
                              child: Builder(
                                builder: (context) {
                                  final int total = _taggedFriends.length;
                                  final List<Widget> children = [];
                                  
                                  // Show up to 2 avatars
                                  final int displayAvatars = total > 2 ? 2 : total;
                                  for (int i = 0; i < displayAvatars; i++) {
                                    final friend = _taggedFriends[i];
                                    final avatarUrl = friend['avatar_url'] as String?;
                                    children.add(
                                      Positioned(
                                        left: i * 24.0, // 44px size, overlaps by 20px
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isDark ? const Color(0xFF1E2433) : Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: avatarUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl: avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, url, error) => Image.asset(
                                                      'assets/home/images/element.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/home/images/element.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Show +X indicator if total > 2
                                  if (total > 2) {
                                    children.add(
                                      Positioned(
                                        left: 2 * 24.0,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2C2541) : const Color(0xFFEDE6FC),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isDark ? const Color(0xFF1E2433) : Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '+${total - 2}',
                                            style: GoogleFonts.ibmPlexSansArabic(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFF9F85FF) : const Color(0xFF7C57FC),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final double width = (displayAvatars * 24.0) + (total > 2 ? 44.0 : 20.0);
                                  return SizedBox(
                                    width: width,
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: children,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tagged friends names list text
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final int total = _taggedFriends.length;
                                  String namesText = '';
                                  if (total == 1) {
                                    namesText = _taggedFriends[0]['name'] as String;
                                  } else if (total == 2) {
                                    namesText = '${_taggedFriends[0]['name']}, ${_taggedFriends[1]['name']}';
                                  } else {
                                    namesText = '${_taggedFriends[0]['name']}, ${_taggedFriends[1]['name']} +${total - 2}';
                                  }
                                  return Text(
                                    namesText,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : const Color(0xFF666666),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Small add friends square button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2541) : const Color(0xFFEDE6FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                'assets/home/icons/add_friends.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Private Check-in Switch Row
                  Row(
                    children: [
                      Text(
                        "Private check-in",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/home/icons/info_circle_small.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white60 : const Color(0xFF82858C),
                          BlendMode.srcIn,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPrivate = !_isPrivate;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 51,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _isPrivate ? const Color(0xFF7C57FC) : (isDark ? const Color(0xFF2C354A) : const Color(0xFFD1D1D1)),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isPrivate ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white70 : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Info Banner Card (Add caption to continue)
                  if (!hasCaption)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2541).withValues(alpha: 0.7) : const Color(0xFFEDE6FC).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/home/icons/info_circle_large.svg',
                            width: 28,
                            height: 28,
                            colorFilter: ColorFilter.mode(
                              isDark ? const Color(0xFF9F85FF) : const Color(0xFF7C57FC),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Add caption to continue.\nPhotos and friends are optional.",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF9F85FF) : const Color(0xFF7C57FC),
                                fontWeight: FontWeight.normal,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
             ),
            ),
          ),

          // Bottom Action Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasCaption && !_isSaving
                      ? (widget.editPost != null ? _saveChanges : _submitPost)
                      : null,
                  child: Opacity(
                    opacity: hasCaption && !_isSaving ? 1.0 : 0.6,
                    child: _isSaving
                        ? CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 10,
                          )
                        : Text(
                            widget.editPost != null ? 'Save changes' : 'Continue',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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

  void _openChangeLocation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, dynamic>? selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const LocationSearchSheet();
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _locationName = selected['name'] as String;
        _locationAddress = selected['address'] as String;
        _latitude = selected['latitude'] as double;
        _longitude = selected['longitude'] as double;
        _placeId = selected['placeId'] as String?;
      });
      _mapController?.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(_longitude, _latitude)).toJson(),
          zoom: 15.0,
        ),
        mapbox.MapAnimationOptions(duration: 500),
      );
    }
  }


}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFF7C57FC),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.borderRadius != borderRadius;
}

