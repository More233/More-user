import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) async {
    final notifier = ref.read(settingsProvider.notifier);
    setState(() {
      _query = val;
    });

    if (val.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
    });

    final results = await notifier.searchUsersToBlock(val);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    }
  }

  ImageProvider _getAvatarProvider(String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return NetworkImage(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    return const AssetImage('assets/home/images/element.png');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = settings.preferredLanguage == 'ar';

    final blockedIds = settings.blockedUsers.map((u) => u['id'] as String).toSet();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'الأشخاص المحظورين' : 'Blocked People',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            // Top banner tip row - Figma
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECE7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/setting/icons/idea_01.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7C57FC),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'يمكنك البحث عن الأشخاص بالاسم أو اسم المستخدم لحظرهم مباشرة من هنا.'
                            : 'You can search for people by name or username to block them directly from here.',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4C30A0),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Search Input box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث بالاسم أو اسم المستخدم' : 'Search by name or username',
                  hintStyle: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFFBBBBBB)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/setting/icons/search_01.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF888888),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Body results
            Expanded(
              child: _searching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C57FC),
                      ),
                    )
                  : (_query.trim().isNotEmpty
                      ? _buildSearchResultsList(blockedIds, notifier, isAr)
                      : _buildBlockedUsersList(settings.blockedUsers, notifier, isAr)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(
    Set<String> blockedIds,
    SettingsNotifier notifier,
    bool isAr,
  ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا يوجد نتائج مطابقة' : 'No matching results',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 15,
            color: const Color(0xFF888888),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE8E8E8)),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final userId = user['id'] as String;
        final isBlocked = blockedIds.contains(userId);
        final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF2F2F2),
                backgroundImage: _getAvatarProvider(user['avatar_url']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : (isAr ? 'مستخدم بدون اسم' : 'No name user'),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user['username'] ?? ''}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: const Color(0xFF707070),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? const Color(0xFFEEEEEE) : const Color(0xFFFFECEC),
                  foregroundColor: isBlocked ? Colors.black : const Color(0xFFD80000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isBlocked ? const Color(0xFFDDDDDD) : const Color(0xFFFFCCCC),
                    ),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () async {
                  if (isBlocked) {
                    await notifier.unblockUser(userId);
                  } else {
                    await notifier.blockUser(userId);
                  }
                },
                child: Text(
                  isBlocked
                      ? (isAr ? 'إلغاء الحظر' : 'Unblock')
                      : (isAr ? 'حظر' : 'Block'),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedUsersList(
    List<Map<String, dynamic>> blockedUsers,
    SettingsNotifier notifier,
    bool isAr,
  ) {
    if (blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_flipped, color: Color(0xFFBBBBBB), size: 48),
            const SizedBox(height: 16),
            Text(
              isAr ? 'قائمة الحظر فارغة' : 'No blocked people',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: blockedUsers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE8E8E8)),
      itemBuilder: (context, index) {
        final user = blockedUsers[index];
        final userId = user['id'] as String;
        final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF2F2F2),
                backgroundImage: _getAvatarProvider(user['avatar_url']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : (isAr ? 'مستخدم بدون اسم' : 'No name user'),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user['username'] ?? ''}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: const Color(0xFF707070),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEEEEE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () async {
                  await notifier.unblockUser(userId);
                },
                child: Text(
                  isAr ? 'إلغاء الحظر' : 'Unblock',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
