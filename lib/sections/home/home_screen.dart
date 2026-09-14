import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/account_manager.dart';
import 'models/timeline_state.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/notifications_view_model.dart';
import 'view_models/messages_view_model.dart';
import 'widgets/common/bottom_nav_bar.dart';
import 'widgets/common/custom_loading_indicator.dart';
import '../../services/notification_service.dart';
import '../orders/orders_screen.dart';
import '../orders/screens/my_orders_screen.dart';
import '../orders/screens/wallet_screen.dart';
import '../orders/screens/account_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(timelineViewModelProvider.notifier).init();
      ref.read(notificationsViewModelProvider.notifier).init();
      await AccountManager.saveCurrentAccount();
    });
  }

  Widget _buildBody(TimelineState state) {
    return IndexedStack(
      index: state.selectedNavIndex.clamp(0, 3),
      children: [
        OrdersScreen(
          onExploreTapped: () {},
        ),
        const MyOrdersScreen(),
        const WalletScreen(),
        const AccountScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      notificationsViewModelProvider.select((s) => s.unreadCount),
      (previous, next) {
        final unreadMsgs = ref.read(messagesViewModelProvider).threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0));
        NotificationService.updateBadgeCount(next + unreadMsgs);
      },
    );

    ref.listen<int>(
      messagesViewModelProvider.select((s) => s.threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0))),
      (previous, next) {
        final unreadNotifs = ref.read(notificationsViewModelProvider).unreadCount;
        NotificationService.updateBadgeCount(unreadNotifs + next);
      },
    );

    final state = ref.watch(timelineViewModelProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: state.selectedNavIndex,
        userAvatarUrl: state.currentUserAvatarUrl,
        unreadNotificationsCount: ref.watch(notificationsViewModelProvider).unreadCount,
        unreadMessagesCount: ref.watch(messagesViewModelProvider).threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0)),
        onItemTapped: (index) {
          setState(() {
            _isHeaderVisible = true;
          });
          ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(index);
        },
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (state.selectedNavIndex == 0) {
            if (notification is ScrollUpdateNotification) {
              final delta = notification.scrollDelta;
              if (delta != null) {
                if (delta > 0.5) {
                  if (_isHeaderVisible) {
                    setState(() {
                      _isHeaderVisible = false;
                    });
                  }
                } else if (delta < -0.5) {
                  if (!_isHeaderVisible) {
                    setState(() {
                      _isHeaderVisible = true;
                    });
                  }
                }
              }
              if (notification.metrics.pixels <= 0) {
                if (!_isHeaderVisible) {
                  setState(() {
                    _isHeaderVisible = true;
                  });
                }
              }
            } else if (notification is ScrollEndNotification) {
              if (notification.metrics.pixels <= 0) {
                if (!_isHeaderVisible) {
                  setState(() {
                    _isHeaderVisible = true;
                  });
                }
              }
            }
          }
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: state.isLoading
                  ? const CustomLoadingIndicator()
                  : _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }


}
