import 'package:flutter/material.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final RouteObserver<ModalRoute<void>> appRouteObserver = routeObserver;

/// Centralized registry for tab and screen ScrollControllers.
class ScrollResetRegistry {
  ScrollResetRegistry._();

  static final Map<int, ScrollController> _tabControllers = {};

  static void register(int tabIndex, ScrollController controller) {
    _tabControllers[tabIndex] = controller;
  }

  static void unregister(int tabIndex) {
    _tabControllers.remove(tabIndex);
  }

  static void resetTab(int tabIndex) {
    final controller = _tabControllers[tabIndex];
    if (controller != null && controller.hasClients) {
      controller.jumpTo(0);
    }
  }

  static void resetController(ScrollController controller) {
    if (controller.hasClients) {
      controller.jumpTo(0);
    }
  }
}

/// Reusable mixin for State classes with a ScrollController.
/// Implements RouteAware to automatically reset scroll position to 0 (top)
/// whenever the screen is re-entered or navigated back to via push/pop.
mixin ScrollResetMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  late final ScrollController scrollController = ScrollController(keepScrollOffset: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  void resetScroll() {
    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void didPush() {
    resetScroll();
  }

  @override
  void didPopNext() {
    resetScroll();
  }

  @override
  void didPushNext() {}

  @override
  void didPop() {}

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    scrollController.dispose();
    super.dispose();
  }
}
