import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:servobuddy/app/app.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/core/files/image_store.dart';
import 'package:servobuddy/core/notifications/notification_service.dart';
import 'package:servobuddy/core/providers.dart';
import 'package:servobuddy/features/backup/application/backup_actions.dart';
import 'package:servobuddy/features/expenses/presentation/widgets/amount_field.dart';
import 'package:servobuddy/features/expenses/presentation/widgets/fuel_fill_fields.dart';
import 'package:servobuddy/features/expenses/presentation/widgets/title_field.dart';
import 'package:servobuddy/features/home_widget/application/home_widget_sync.dart';
import 'package:servobuddy/features/home_widget/domain/widget_snapshot.dart';
import 'package:servobuddy/features/settings/data/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The expense form's fields, found by what they are rather than their order
/// (the title field sits above the amount for every category).
final amountField = find.descendant(
  of: find.byType(AmountField),
  matching: find.byType(TextFormField),
);
final litresField = find
    .descendant(
      of: find.byType(FuelFillFields),
      matching: find.byType(TextFormField),
    )
    .first;
final titleField = find.descendant(
  of: find.byType(TitleField),
  matching: find.byType(TextFormField),
);

/// The app's fixed "now" in tests: a Wednesday afternoon.
final testNow = DateTime(2026, 9, 23, 14, 30);

class FakeNotificationService extends NotificationService {
  List<PlannedNotification> scheduled = [];
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermissions() async => permissionRequests++;

  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async =>
      scheduled = plan;
}

/// Stands in for the save and open dialogs: keeps what was saved, and hands
/// back [toOpen] when a backup is chosen.
class FakeBackupFiles extends BackupFiles {
  String? savedName;
  Uint8List? saved;
  Uint8List? toOpen;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<Uint8List?> open() async => toOpen;
}

/// Stands in for the home screen widget: keeps the last thing it was told to
/// show, and lets a test fake a tap.
class FakeHomeWidgetBridge extends HomeWidgetBridge {
  WidgetSnapshot? shown;
  final taps = StreamController<Uri?>.broadcast();

  @override
  Future<void> show(WidgetSnapshot s) async => shown = s;

  @override
  Future<Uri?> initialLaunch() async => null;

  @override
  Stream<Uri?> get launches => taps.stream;
}

bool _fontsLoaded = false;

/// flutter_test draws every font as the fixed-width "Ahem" test font unless
/// real ones are registered, which invents overflows that don't exist on a
/// phone. Icon fonts from packages aren't loaded either.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  for (final (family, path) in [
    ('Archivo', 'assets/fonts/Archivo.ttf'),
    ('packages/lucide_icons_flutter/Lucide', _lucidePath()),
    // Material icons.
    if (_materialIconsPath() case final path?) ('MaterialIcons', path),
  ]) {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

/// Ships in the Flutter SDK's cache; flutter_test runs with FLUTTER_ROOT set.
String? _materialIconsPath() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return null;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  return file.existsSync() ? file.path : null;
}

String _lucidePath() {
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final root = RegExp(r'"name": "lucide_icons_flutter",\s*"rootUri": "([^"]+)"')
      .firstMatch(config)!
      .group(1)!;
  var uri = Uri.parse(root);
  if (!uri.isAbsolute) {
    uri = Uri.file('${Directory.current.path}/.dart_tool/').resolveUri(uri);
  }
  return '${uri.toFilePath()}/assets/lucide.ttf';
}

class TestApp {
  TestApp._(this.db, this.notifications);

  final AppDatabase db;
  final FakeNotificationService notifications;
  final backupFiles = FakeBackupFiles();
  final homeWidget = FakeHomeWidgetBridge();

  /// Boots the whole app on a phone-sized screen against an in-memory
  /// database. Pass [seed] to insert data before the first frame.
  static Future<TestApp> start(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
    ThemeChoice theme = ThemeChoice.light,
    Map<String, Object> prefs = const {},
    Size physicalSize = const Size(1080, 2340),
    double devicePixelRatio = 2.75,
  }) async {
    await loadAppFonts();
    await initializeDateFormatting('en_AU');
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'themeChoice': theme.name,
      ...prefs,
    });
    final sharedPrefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    if (seed != null) await tester.runAsync(() => seed(db));

    final app = TestApp._(db, FakeNotificationService());
    final tmp = Directory.systemTemp.createTempSync('servobuddy_test');
    addTearDown(() => tmp.deleteSync(recursive: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => testNow),
          notificationServiceProvider.overrideWithValue(app.notifications),
          backupFilesProvider.overrideWithValue(app.backupFiles),
          homeWidgetBridgeProvider.overrideWithValue(app.homeWidget),
          imageStoreProvider.overrideWithValue(
            ImageStore(root: () async => tmp),
          ),
        ],
        child: const ServoBuddyApp(),
      ),
    );
    await app.settle(tester);
    addTearDown(() async {
      // Unmount first so Drift's stream listeners are cancelled, then close.
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
    return app;
  }

  /// Lets database streams and async providers deliver. Real async work
  /// (sqlite) needs runAsync; pumps then render the results. Avoids
  /// pumpAndSettle, which never settles while a progress spinner animates.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Let route transitions, dismiss animations, the snackbars they trigger,
    // and the reminder debounce all run frame by frame to completion.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
}
