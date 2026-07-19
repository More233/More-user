import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateCollectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> profilesList;
  final bool isLoadingProfiles;
  final Function(String name, List<String> sharedUserIds) onCreated;

  const CreateCollectionBottomSheet({
    super.key,
    required this.profilesList,
    required this.isLoadingProfiles,
    required this.onCreated,
  });

  @override
  State<CreateCollectionBottomSheet> createState() => _CreateCollectionBottomSheetState();
}

class _CreateCollectionBottomSheetState extends State<CreateCollectionBottomSheet> {
  bool _isAddPeopleView = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isSaveEnabled = false;
  final Set<String> _selectedSharedUserIds = {};
  String _searchQuery = "";
  List<Map<String, dynamic>> _localProfilesList = [];
  bool _isLoadingLocal = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _localProfilesList = List<Map<String, dynamic>>.from(widget.profilesList);
    _isLoadingLocal = widget.isLoadingProfiles;
    _nameController.addListener(() {
      setState(() {
        _isSaveEnabled = _nameController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProfilesForSearch() async {
    if (_localProfilesList.length > 20) return;
    setState(() => _isLoadingLocal = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url')
          .limit(100);
      if (mounted) {
        setState(() {
          final existingIds = _localProfilesList.map((p) => p['id']).toSet();
          for (final p in res) {
            if (!existingIds.contains(p['id'])) {
              _localProfilesList.add(p);
            }
          }
          _isLoadingLocal = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profiles for search: $e");
      if (mounted) {
        setState(() => _isLoadingLocal = false);
      }
    }
  }

  void _onSearchQueryChanged(String val) {
    setState(() {
      _searchQuery = val;
    });

    if (val.trim().isEmpty) return;

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .or('username.ilike.%$val%,first_name.ilike.%$val%,last_name.ilike.%$val%')
            .limit(50);
        if (mounted) {
          setState(() {
            final existingIds = _localProfilesList.map((p) => p['id']).toSet();
            for (final p in res) {
              if (!existingIds.contains(p['id'])) {
                _localProfilesList.add(p);
              }
            }
          });
        }
      } catch (e) {
        debugPrint("Error searching profiles: $e");
      }
    });
  }

  Widget _buildOverlappingSharedAvatars(List<String> userIds, {double size = 16}) {
    if (userIds.isEmpty) return const SizedBox.shrink();
    
    final List<Map<String, dynamic>> matchingProfiles = [];
    for (final id in userIds) {
      final profile = _localProfilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        matchingProfiles.add(profile);
      }
    }
    
    if (matchingProfiles.isEmpty) return const SizedBox.shrink();
    
    final displayProfiles = matchingProfiles.take(3).toList();
    return SizedBox(
      width: size + (displayProfiles.length - 1) * (size * 0.5),
      height: size,
      child: Stack(
        children: List.generate(displayProfiles.length, (index) {
          final p = displayProfiles[index];
          final avatarUrl = p['avatar_url'] as String?;
          
          return Positioned(
            left: index * (size * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover))
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatSharedNames(List<String> userIds) {
    if (userIds.isEmpty) return "Private";
    
    final List<String> names = [];
    for (final id in userIds) {
      final profile = _localProfilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        final fName = profile['first_name'] as String? ?? '';
        final name = fName.isNotEmpty ? fName : (profile['username'] as String? ?? 'User');
        names.add(name);
      }
    }
    
    if (names.isEmpty) return "Shared";
    if (names.length == 1) return "with ${names[0]}";
    if (names.length == 2) return "with ${names[0]} and ${names[1]}";
    return "with ${names[0]} and ${names.length - 1} others";
  }

  Widget _buildMainView() {
    final isShared = _selectedSharedUserIds.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF82858C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'New Collection',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _isSaveEnabled
                    ? () async {
                        final name = _nameController.text.trim();
                        widget.onCreated(name, _selectedSharedUserIds.toList());
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Save',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaveEnabled
                        ? const Color(0xFF7C57FC)
                        : const Color(0xFF82858C).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Collection name',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a collection name',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: const Color(0xFF82858C),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: Color(0xFF5A5D67)),
            title: Text(
              'Add people to collection',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Row(
              children: [
                if (isShared) ...[
                  _buildOverlappingSharedAvatars(_selectedSharedUserIds.toList(), size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  isShared
                      ? _formatSharedNames(_selectedSharedUserIds.toList())
                      : 'Save to a collection together',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF82858C)),
            onTap: () {
              setState(() {
                _isAddPeopleView = true;
                _searchQuery = "";
              });
              _loadAllProfilesForSearch();
            },
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAddPeopleView() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final otherProfiles = _localProfilesList.where((p) => p['id'] != currentUser?.id).toList();
    final filteredProfiles = otherProfiles.where((p) {
      final query = _searchQuery.toLowerCase();
      final username = (p['username'] as String? ?? '').toLowerCase();
      final firstName = (p['first_name'] as String? ?? '').toLowerCase();
      final lastName = (p['last_name'] as String? ?? '').toLowerCase();
      return username.contains(query) || firstName.contains(query) || lastName.contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddPeopleView = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF82858C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Add people',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddPeopleView = false;
                  });
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF7C57FC),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: _onSearchQueryChanged,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingLocal
                ? const Center(child: CupertinoActivityIndicator())
                : filteredProfiles.isEmpty
                    ? Center(
                        child: Text(
                          "No friends found",
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProfiles.length,
                        itemBuilder: (context, index) {
                          final p = filteredProfiles[index];
                          final pId = p['id'] as String;
                          final username = p['username'] as String? ?? '';
                          final fName = p['first_name'] as String? ?? '';
                          final lName = p['last_name'] as String? ?? '';
                          final fullName = fName.isNotEmpty ? '$fName $lName' : username;
                          final avatarUrl = p['avatar_url'] as String?;
                          final isSelected = _selectedSharedUserIds.contains(pId);
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? (avatarUrl.startsWith('http')
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : AssetImage(avatarUrl) as ImageProvider)
                                  : const AssetImage('assets/home/images/avatar_placeholder.png'),
                            ),
                            title: Text(
                              fullName,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '@$username',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                            trailing: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFD1D1D6),
                                  width: 2,
                                ),
                                color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSharedUserIds.remove(pId);
                                } else {
                                  _selectedSharedUserIds.add(pId);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isAddPeopleView ? _buildAddPeopleView() : _buildMainView(),
        ),
      ),
    );
  }
}
