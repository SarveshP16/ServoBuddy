import '../../../core/database/app_database.dart';

class ScheduleRepository {
  ScheduleRepository(this._db);

  final AppDatabase _db;

  Future<int> add(ServiceSchedulesCompanion schedule) =>
      _db.into(_db.serviceSchedules).insert(schedule);

  Future<void> save(ServiceSchedule schedule) =>
      _db.update(_db.serviceSchedules).replace(schedule);

  /// Past service records keep their cost but lose the link.
  Future<void> delete(int id) =>
      (_db.delete(_db.serviceSchedules)..where((s) => s.id.equals(id))).go();
}
