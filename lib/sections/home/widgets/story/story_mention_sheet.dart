import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/friends_list_view_model.dart';

class StoryMentionSheetContent extends ConsumerWidget {
  final VoidCallback onDismissed;
  const StoryMentionSheetContent({super.key, required this.onDismissed});

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return CachedNetworkImageProvider(avatarUrl);
      } else {
        return AssetImage(avatarUrl);
      }
    }
    return const AssetImage('assets/home/images/avatar_female.png');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    final state = ref.watch(storyMentionFriendsProvider);
    final notifier = ref.read(storyMentionFriendsProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131722),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + keyboardPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mentions",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: notifier.searchFriends,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white30,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: Color(0xFF7C57FC),
                    radius: 12,
                  ),
                ),
              )
            else if (state.filteredFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No friends found",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white30),
                ),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.filteredFriends.length,
                    itemBuilder: (context, index) {
                      final f = state.filteredFriends[index];
                      final username = f['username']!;
                      final name = f['name']!;
                      final avatar = f['avatar'];
                      final isSelected = state.selectedUsernames.contains(username);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white10,
                              backgroundImage: _getAvatarProvider(avatar),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "@$username",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF7C57FC),
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (bool? val) {
                                notifier.toggleSelection(username);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: state.selectedUsernames.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  disabledBackgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Add",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: state.selectedUsernames.isEmpty ? Colors.white24 : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
