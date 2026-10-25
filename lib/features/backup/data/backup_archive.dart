import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/files/image_store.dart';

/// The settings that travel with a backup. Reminder-permission state stays
/// with the phone it was granted on.
typedef BackupSettings = ({String themeChoice, String garageTitle});

/// What a restore brought in, for the confirmation message.
typedef RestoreSummary = ({
  int vehicles,
  int expenses,
  int photos,
  BackupSettings? settings,
});

/// A backup is one zip: `servobuddy.json` with every row and the settings,
/// plus `photos/` with each car photo and receipt it refers to.
///
/// Rows keep their ids, so expenses still point at their car and service
/// schedule after a restore.
class BackupArchive {
  BackupArchive(this._db, this._images);

  final AppDatabase _db;
  final ImageStore _images;

  static const format = 'servobuddy-backup';
  static const formatVersion = 1;
  static const _dataFile = 'servobuddy.json';
  static const _photosDir = 'photos';

  Future<Uint8List> create({
    required BackupSettings settings,
    required DateTime now,
  }) async {
    final vehicles = await _db.select(_db.vehicles).get();
    final expenses = await _db.select(_db.expenses).get();
    final archive = Archive();
    final photos = <String, String>{};

    /// Adds the file once and returns its name inside the zip, or null if
    /// it's gone from the phone (the row is kept, minus the photo).
    String? addPhoto(String? path) {
      if (path == null) return null;
      if (photos[path] case final name?) return name;
      final file = File(path);
      if (!file.existsSync()) return null;
      final name = '$_photosDir/${photos.length}${p.extension(path)}';
      archive.addFile(ArchiveFile.bytes(name, file.readAsBytesSync()));
      return photos[path] = name;
    }

    final data = {
      'format': format,
      'formatVersion': formatVersion,
      'schemaVersion': _db.schemaVersion,
      'createdAt': now.toIso8601String(),
      'settings': {
        'themeChoice': settings.themeChoice,
        'garageTitle': settings.garageTitle,
      },
      'vehicles': [
        for (final v in vehicles)
          {...v.toJson(), 'photoPath': addPhoto(v.photoPath)},
      ],
      'odometerReadings': [
        for (final r in await _db.select(_db.odometerReadings).get())
          r.toJson(),
      ],
      'serviceSchedules': [
        for (final s in await _db.select(_db.serviceSchedules).get())
          s.toJson(),
      ],
      'expenses': [
        for (final e in expenses)
          {...e.toJson(), 'receiptPath': addPhoto(e.receiptPath)},
      ],
      'recurringExpenses': [
        for (final r in await _db.select(_db.recurringExpenses).get())
          r.toJson(),
      ],
    };
    archive.addFile(
      ArchiveFile.bytes(_dataFile, utf8.encode(jsonEncode(data))),
    );
    return ZipEncoder().encodeBytes(archive);
  }

  /// Replaces everything in the database with the backup's contents.
  ///
  /// Throws [FormatException] for a file that isn't a ServoBuddy backup, or
  /// one made by a newer version of the app. Nothing is changed then.
  Future<RestoreSummary> restore(Uint8List bytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const FormatException('Not a ServoBuddy backup');
    }
    final dataFile = archive.findFile(_dataFile);
    if (dataFile == null) {
      throw const FormatException('Not a ServoBuddy backup');
    }
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(dataFile.content)) as Map<String, dynamic>;
    } on Object {
      throw const FormatException('Not a ServoBuddy backup');
    }
    if (data['format'] != format) {
      throw const FormatException('Not a ServoBuddy backup');
    }
    if ((data['formatVersion'] as int? ?? 0) > formatVersion ||
        (data['schemaVersion'] as int? ?? 0) > _db.schemaVersion) {
      throw const FormatException('Made by a newer version of ServoBuddy');
    }

    List<Map<String, dynamic>> rows(String key) => [
      for (final row in data[key] as List? ?? const [])
        Map<String, dynamic>.from(row as Map),
    ];

    // Photos are copied in first: if anything below fails, the worst left
    // behind is a few unused files, never rows pointing at missing ones.
    final restored = <String, String>{};
    Future<String?> restorePhoto(Object? name, String folder) async {
      if (name is! String) return null;
      if (restored[name] case final path?) return path;
      final file = archive.findFile(name);
      if (file == null) return null;
      return restored[name] = await _images.save(
        file.content,
        folder: folder,
        extension: p.extension(name),
      );
    }

    final vehicles = [
      for (final row in rows('vehicles'))
        Vehicle.fromJson({
          ...row,
          'photoPath': await restorePhoto(row['photoPath'], 'vehicles'),
        }),
    ];
    final expenses = [
      for (final row in rows('expenses'))
        Expense.fromJson({
          ...row,
          'receiptPath': await restorePhoto(row['receiptPath'], 'receipts'),
        }),
    ];
    final readings = rows('odometerReadings').map(OdometerReading.fromJson);
    final schedules = rows('serviceSchedules').map(ServiceSchedule.fromJson);
    final recurring = rows('recurringExpenses').map(RecurringExpense.fromJson);

    final oldPhotos = [
      for (final v in await _db.select(_db.vehicles).get()) v.photoPath,
      for (final e in await _db.select(_db.expenses).get()) e.receiptPath,
    ];

    await _db.transaction(() async {
      // Children first, though deleting cars would cascade anyway.
      await _db.delete(_db.recurringExpenses).go();
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.serviceSchedules).go();
      await _db.delete(_db.odometerReadings).go();
      await _db.delete(_db.vehicles).go();
      await _db.batch((b) {
        b.insertAll(_db.vehicles, vehicles);
        b.insertAll(_db.odometerReadings, readings);
        b.insertAll(_db.serviceSchedules, schedules);
        b.insertAll(_db.expenses, expenses);
        b.insertAll(_db.recurringExpenses, recurring);
      });
    });
    for (final path in oldPhotos) {
      await _images.delete(path);
    }

    final settings = data['settings'];
    return (
      vehicles: vehicles.length,
      expenses: expenses.length,
      photos: restored.length,
      settings: settings is Map
          ? (
              themeChoice: settings['themeChoice'] as String? ?? 'system',
              garageTitle: settings['garageTitle'] as String? ?? '',
            )
          : null,
    );
  }
}
