import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../app/router.dart';
import '../../../app/routes.dart';
import '../../garage/application/garage_provider.dart';
import '../domain/widget_snapshot.dart';

/// Talks to the Android home screen widget. Swapped for a fake in tests,
/// where there's no platform side.
class HomeWidgetBridge {
  const HomeWidgetBridge();

  /// Matches `ServoBuddyWidget.kt`.
  static const _provider = 'com.servobuddy.app.ServoBuddyWidget';

  Future<void> show(WidgetSnapshot s) async {
    await HomeWidget.saveWidgetData('due_title', s.dueTitle);
    await HomeWidget.saveWidgetData('due_detail', s.dueDetail);
    await HomeWidget.saveWidgetData('month_spend', s.monthSpend);
    await HomeWidget.saveWidgetData('month_label', s.monthLabel);
    await HomeWidget.saveWidgetData(
      'link',
      s.vehicleId == null
          ? 'servobuddy://home'
          : 'servobuddy://vehicle/${s.vehicleId}',
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
  }

  /// The widget tap that opened the app, if it was one.
  Future<Uri?> initialLaunch() => HomeWidget.initiallyLaunchedFromHomeWidget();

  /// Taps while the app is already running.
  Stream<Uri?> get launches => HomeWidget.widgetClicked;
}

final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (ref) => const HomeWidgetBridge(),
);

/// Keeps the home screen widget current (after every change, debounced like
/// reminders) and opens the right page when it's tapped.
final homeWidgetSyncProvider = Provider<HomeWidgetSync>((ref) {
  final sync = HomeWidgetSync(ref);
  ref.listen(garageStreamProvider, (_, next) {
    if (next.hasValue) sync.schedule();
  }, fireImmediately: true);
  sync.listenForTaps();
  ref.onDispose(sync.dispose);
  return sync;
});

class HomeWidgetSync {
  HomeWidgetSync(this._ref);

  final Ref _ref;
  Timer? _debounce;
  StreamSubscription<Uri?>? _taps;

  HomeWidgetBridge get _bridge => _ref.read(homeWidgetBridgeProvider);

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        await _bridge.show(widgetSnapshot(_ref.read(garageProvider)));
      } on PlatformException {
        // The widget is a nicety; never let it break the app.
      } on MissingPluginException {
        // No widget support on this platform.
      }
    });
  }

  Future<void> listenForTaps() async {
    try {
      _taps = _bridge.launches.listen(_open);
      _open(await _bridge.initialLaunch());
    } on PlatformException {
      // As above.
    } on MissingPluginException {
      // As above.
    }
  }

  /// "servobuddy://vehicle/3" opens that car over Home, so Back returns to
  /// Home rather than leaving the app.
  void _open(Uri? uri) {
    if (uri == null) return;
    final router = _ref.read(routerProvider);
    router.go(AppRoutes.home);
    final id = uri.host == 'vehicle' && uri.pathSegments.isNotEmpty
        ? int.tryParse(uri.pathSegments.first)
        : null;
    if (id != null && _ref.read(garageProvider).vehicle(id) != null) {
      router.push(AppRoutes.vehicle(id));
    }
  }

  void dispose() {
    _debounce?.cancel();
    _taps?.cancel();
  }
}
