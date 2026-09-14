import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../explore/view_models/explore_view_model.dart';
import '../explore/services/explore_data_service.dart';
import '../auth/account_manager.dart';
import 'models/timeline_state.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/notifications_view_model.dart';
import 'view_models/messages_view_model.dart';
import 'widgets/common/bottom_nav_bar.dart';
import 'widgets/common/custom_loading_indicator.dart';
import '../../services/notification_service.dart';
import 'widgets/common/user_drawer.dart';
import '../orders/orders_screen.dart';
import '../orders/screens/my_orders_screen.dart';
import '../orders/screens/wallet_screen.dart';
import '../orders/screens/account_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isHeaderVisible = true;

  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  bool _isMenuOpen = false;
  bool _canDrag = false;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
    
    Future.microtask(() async {
      ref.read(timelineViewModelProvider.notifier).init();
      ref.read(notificationsViewModelProvider.notifier).init();
      await AccountManager.saveCurrentAccount();
    });
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }



  void _onHorizontalDragStart(DragStartDetails details, int selectedNavIndex) {
    if (_isMenuOpen || selectedNavIndex == 0 || details.globalPosition.dx < 45.0) {
      _canDrag = true;
    } else {
      _canDrag = false;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_canDrag) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.76;
    _menuAnimationController.value += details.delta.dx / menuWidth;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_canDrag) return;
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity < -200) {
      // Swiped left quickly -> close
      _menuAnimationController.reverse();
      setState(() {
        _isMenuOpen = false;
      });
      return;
    } else if (velocity > 200) {
      // Swiped right quickly -> open
      _menuAnimationController.forward();
      setState(() {
        _isMenuOpen = true;
      });
      return;
    }

    if (_isMenuOpen) {
      // If it was already open, if they dragged it left at all (value < 0.85), close it
      if (_menuAnimationController.value < 0.85) {
        _menuAnimationController.reverse();
        setState(() {
          _isMenuOpen = false;
        });
      } else {
        _menuAnimationController.forward();
      }
    } else {
      // If it was closed, if they dragged it right past 0.25, open it
      if (_menuAnimationController.value > 0.25) {
        _menuAnimationController.forward();
        setState(() {
          _isMenuOpen = true;
        });
      } else {
        _menuAnimationController.reverse();
      }
    }
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
    final isPlaceSelected = ref.watch(exploreViewModelProvider.select((s) => s.selectedPlace != null));
    final bool isPlaceSelectedOnMap = isPlaceSelected && state.selectedNavIndex == 1;
    debugPrint("HomeScreen: build() called, isLoading=${state.isLoading}, selectedNavIndex=${state.selectedNavIndex}, isPlaceSelectedOnMap=$isPlaceSelectedOnMap");
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.76;

    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        final slide = menuWidth * _menuAnimation.value;
        const scale = 1.0; // No scaling per user request

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF131722) // Matches dark drawer background to fill corner gaps
              : const Color(0xFFF7F9FA), // Matches light drawer background to fill corner gaps
          body: Stack(
            children: [
              // Under Layer: The Drawer Menu
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: menuWidth,
                child: Transform.translate(
                  offset: Offset((_menuAnimation.value - 1.0) * 80.0, 0.0), // Parallax effect
                  child: UserDrawer(
                    onProfileUpdated: () {
                      ref.read(timelineViewModelProvider.notifier).refreshAll();
                      ExploreDataService.clearSupabaseCache();
                      final exploreState = ref.read(exploreViewModelProvider);
                      final lat = exploreState.userLocation?.latitude ?? exploreState.lastFetchedLocation?.latitude ?? 24.7136;
                      final lng = exploreState.userLocation?.longitude ?? exploreState.lastFetchedLocation?.longitude ?? 46.6753;
                      ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);
                    },
                    onCloseMenu: () {
                      _menuAnimationController.reverse();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                  ),
                ),
              ),
              // Top Layer: The Main Content
              Transform.translate(
                offset: Offset(slide, 0.0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(_menuAnimation.value * 64.0),
                      boxShadow: _menuAnimation.value > 0 ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: (Theme.of(context).brightness == Brightness.dark ? 0.8 : 0.15) * _menuAnimation.value,
                          ), // deep outer shadow
                          blurRadius: 24,
                          spreadRadius: Theme.of(context).brightness == Brightness.dark ? 2.0 : 0.0,
                          offset: const Offset(-6, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: (Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.08) * _menuAnimation.value,
                          ), // soft inner shadow
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(-2, 0),
                        ),
                      ] : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_menuAnimation.value * 64.0), // 64px rounded corners
                      child: Stack(
                        children: [
                          GestureDetector(
                            onHorizontalDragStart: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? (details) => _onHorizontalDragStart(details, state.selectedNavIndex)
                                : null,
                            onHorizontalDragUpdate: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? (details) => _onHorizontalDragUpdate(details)
                                : null,
                            onHorizontalDragEnd: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? _onHorizontalDragEnd
                                : null,
                            child: Scaffold(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              extendBody: true,
                              bottomNavigationBar: BottomNavBar(
                                borderRadius: BorderRadius.circular(_menuAnimation.value * 64.0),
                                selectedIndex: state.selectedNavIndex,
                                userAvatarUrl: state.currentUserAvatarUrl,
                                unreadNotificationsCount: ref.watch(notificationsViewModelProvider).unreadCount,
                                unreadMessagesCount: ref.watch(messagesViewModelProvider).threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0)),
                                onItemTapped: (index) {
                                  debugPrint('HomeScreen: onItemTapped called with index $index');
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
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Invisible gesture overlay on the right when menu is open to close menu on tap
              if (_isMenuOpen)
                Positioned(
                  left: slide,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _menuAnimationController.reverse();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                    onHorizontalDragStart: (details) => _onHorizontalDragStart(details, state.selectedNavIndex),
                    onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details),
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      color: Colors.transparent,
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
