import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/core/files/image_store.dart';
import 'package:servobuddy/features/backup/data/backup_archive.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_labels.dart';

import '../support/seed.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 10, 26, 9);
  const settings = (themeChoice: 'dark', garageTitle: "Sam's Garage");

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('servobuddy_backup'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// A fresh in-memory database with its own photo folder.
  (AppDatabase, BackupArchive, Directory) phone(String name) {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final photos = Directory('${tmp.path}/$name')..createSync();
    return (
      db,
      BackupArchive(db, ImageStore(root: () async => photos)),
      photos,
    );
  }

  Future<Uint8List> backupOfMockupGarage() async {
    final (db, archive, photos) = phone('old');
    await seedMockupGarage(db);
    // A car photo and a receipt, so files travel too.
    final photo = File('${photos.path}/corolla.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final receipt = File('${photos.path}/receipt.png')
      ..writeAsBytesSync([4, 5]);
    await (db.update(db.vehicles)..where((v) => v.id.equals(1))).write(
      VehiclesCompanion(photoPath: Value(photo.path)),
    );
    final firstExpense = (await db.select(db.expenses).get()).first;
    await (db.update(db.expenses)..where((e) => e.id.equals(firstExpense.id)))
        .write(ExpensesCompanion(receiptPath: Value(receipt.path)));
    return archive.create(settings: settings, now: now);
  }

  test('a backup restores every row, with ids, photos and settings', () async {
    final bytes = await backupOfMockupGarage();
    final (db, archive, photos) = phone('new');
    final summary = await archive.restore(bytes);

    expect(summary.vehicles, 3);
    expect(summary.photos, 2);
    expect(summary.settings, settings);
    final cars = await db.select(db.vehicles).get();
    expect(cars.map((v) => v.displayName), [
      'Toyota Corolla',
      'Mazda CX-5',
      'Ford Ranger',
    ]);
    expect(summary.expenses, (await db.select(db.expenses).get()).length);
    expect(await db.select(db.serviceSchedules).get(), isNotEmpty);
    expect(await db.select(db.odometerReadings).get(), isNotEmpty);

    // Ids are kept, so everything still belongs to the same car.
    final carIds = cars.map((v) => v.id).toSet();
    final expenses = await db.select(db.expenses).get();
    expect(
      expenses.map((e) => e.vehicleId).toSet().difference(carIds),
      isEmpty,
    );
    expect(
      expenses.where((e) => e.category == ExpenseCategory.service),
      isNotEmpty,
    );
    final schedules = await db.select(db.serviceSchedules).get();
    expect(
      schedules.map((s) => s.vehicleId).toSet().difference(carIds),
      isEmpty,
    );

    // Photos land in this phone's storage, not at the old paths.
    final photo = cars.first.photoPath!;
    expect(photo, startsWith(photos.path));
    expect(File(photo).readAsBytesSync(), [1, 2, 3]);
  });

  test('restoring replaces what was there', () async {
    final bytes = await backupOfMockupGarage();
    final (db, archive, _) = phone('new');
    await seedMockupGarage(db);
    await seedMockupGarage(db); // Six cars now.
    await archive.restore(bytes);
    expect(await db.select(db.vehicles).get(), hasLength(3));
  });

  test('anything else is refused, and nothing changes', () async {
    final (db, archive, _) = phone('new');
    await seedMockupGarage(db);

    Future<void> refuses(List<int> bytes, String why) => expectLater(
      archive.restore(Uint8List.fromList(bytes)),
      throwsA(isA<FormatException>().having((e) => e.message, 'why', why)),
    );
    Uint8List zip(Map<String, Object> data) => ZipEncoder().encodeBytes(
      Archive()..addFile(
        ArchiveFile.bytes('servobuddy.json', utf8.encode(jsonEncode(data))),
      ),
    );

    await refuses(utf8.encode('just some text'), 'Not a ServoBuddy backup');
    await refuses(zip({'format': 'something-else'}), 'Not a ServoBuddy backup');
    await refuses(
      zip({
        'format': BackupArchive.format,
        'formatVersion': 1,
        'schemaVersion': db.schemaVersion + 1,
      }),
      'Made by a newer version of ServoBuddy',
    );
    expect(await db.select(db.vehicles).get(), hasLength(3));
  });
}
