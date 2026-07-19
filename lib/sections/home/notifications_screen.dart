import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'view_models/notifications_view_model.dart';
import 'profile_screen.dart';
import 'widgets/common/custom_loading_indicator.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const NotificationsScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsViewModelProvider.notifier).init();
      ref.read(notificationsViewModelProvider.notifier).markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsViewModelProvider);
    final activities = state.activities;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SvgPicture.asset(
                    'assets/home/icons/arrow_left_01.svg',
                    width: 24,
                    height: 24,
                    colorFilter: isDark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
                  ),
                ),
              )
            : null,
        title: Text(
          'Notifications',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8)),
          Expanded(
            child: state.isLoading
                ? const CustomLoadingIndicator()
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () => ref.read(notificationsViewModelProvider.notifier).loadNotifications(),
                      ),
                      if (activities.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index.isOdd) {
                                  return const SizedBox(height: 16);
                                }
                                final itemIndex = index ~/ 2;
                                final activity = activities[itemIndex];
                                return _buildActivityItem(activity);
                              },
                              childCount: activities.length * 2 - 1,
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x335D5D5D), // rgba(93, 93, 93, 0.2)
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/home/icons/notificationlg_02.svg',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> act) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0D111C);
    final Color textMutedColor = isDark ? const Color(0xFF82858C) : const Color(0xFF545763);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userPosts: const [],
                    userId: act['sender_id'] as String,
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? const Color(0xFF131722) : Colors.grey[200],
                  backgroundImage: act['avatar_url'] != null && (act['avatar_url'] as String).isNotEmpty
                      ? CachedNetworkImageProvider(act['avatar_url'] as String) as ImageProvider
                      : const AssetImage(
                          'assets/home/images/element.png',
                        ),
                ),
                const SizedBox(width: 12),
                // Content Text
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: textColor,
                      ),
                      children: [
                        TextSpan(
                          text: act['username'],
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: act['text'],
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: textMutedColor,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: act['time'],
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: const Color(0xFF82858C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Action: Either Photo Preview or Follow button
        if (act['type'] == 'follow')
          SizedBox(
            height: 32,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: act['isFollowing']
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181C26) : Colors.white)
                    : const Color(0xFF7C57FC),
                side: BorderSide(
                  color: act['isFollowing']
                      ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B404E) : const Color(0xFFC8C8C8))
                      : const Color(0xFF7C57FC),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => ref
                  .read(notificationsViewModelProvider.notifier)
                  .toggleFollowBack(act['sender_id'] as String, act['isFollowing'] as bool),
              child: Text(
                act['isFollowing'] ? 'Following' : 'Follow back',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: act['isFollowing'] ? const Color(0xFF82858C) : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
