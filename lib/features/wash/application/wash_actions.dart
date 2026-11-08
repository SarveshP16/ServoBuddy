import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../expenses/domain/expense_category.dart';
import '../../garage/application/garage_provider.dart';
import '../domain/wash_checklist.dart';
import '../domain/wash_type.dart';

/// What the paid-wash sheet and the checklist's Finish collect.
class WashDraft {
  const WashDraft({
    required this.vehicleId,
    required this.date,
    required this.type,
    this.place,
    this.amountCents = 0,
    this.usedPass = false,
    this.checklist,
    this.itemsDone,
    this.itemsTotal,
    this.minutes,
  });

  final int vehicleId;
  final DateTime date;
  final WashType type;
  final String? place;
  final int amountCents;
  final bool usedPass;
  final ChecklistKind? checklist;
  final int? itemsDone;
  final int? itemsTotal;
  final int? minutes;
}

final washActionsProvider = Provider<WashActions>(WashActions.new);

class WashActions {
  WashActions(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);

  /// Saves the wash. A paid one with a price is also logged in Expenses as
  /// Car wash, linked to it, so it's counted once. Returns that expense's
  /// amount, or 0 if none was logged.
  Future<int> save(WashDraft d) => _db.transaction(() async {
    final place = d.place?.trim();
    final charged = d.type.paid && !d.usedPass && d.amountCents > 0;
    int? expenseId;
    if (charged) {
      expenseId = await _db
          .into(_db.expenses)
          .insert(
            ExpensesCompanion.insert(
              vehicleId: d.vehicleId,
              category: ExpenseCategory.carWash,
              amountCents: d.amountCents,
              date: d.date,
              title: Value(d.type.title),
              notes: Value(place == null || place.isEmpty ? null : place),
            ),
          );
    }
    await _db
        .into(_db.washes)
        .insert(
          WashesCompanion.insert(
            vehicleId: d.vehicleId,
            date: d.date,
            type: d.type,
            place: Value(place == null || place.isEmpty ? null : place),
            amountCents: Value(d.usedPass ? 0 : d.amountCents),
            usedPass: Value(d.usedPass),
            expenseId: Value(expenseId),
            checklist: Value(d.checklist?.name),
            itemsDone: Value(d.itemsDone),
            itemsTotal: Value(d.itemsTotal),
            minutes: Value(d.minutes),
          ),
        );
    return charged ? d.amountCents : 0;
  });

  /// Removes a wash, and its Car wash expense too when [withExpense].
  Future<void> delete(Wash w, {required bool withExpense}) =>
      _db.transaction(() async {
        await (_db.delete(_db.washes)..where((x) => x.id.equals(w.id))).go();
        if (withExpense && w.expenseId != null) {
          await (_db.delete(
            _db.expenses,
          )..where((e) => e.id.equals(w.expenseId!))).go();
        }
      });

  /// Wash reminder for one car: every [days] after the last wash, or off.
  Future<void> setWashEvery(int vehicleId, int? days) async {
    final v = _ref.read(garageProvider).vehicle(vehicleId);
    if (v == null) return;
    await _ref
        .read(vehicleRepositoryProvider)
        .save(v.copyWith(washEveryDays: Value(days)));
  }
}

/// Your own version of each checklist, kept with the other settings. A
/// checklist never edited uses [defaultChecklists].
final washChecklistsProvider =
    NotifierProvider<WashChecklists, Map<ChecklistKind, List<ChecklistItem>>>(
      WashChecklists.new,
    );

class WashChecklists extends Notifier<Map<ChecklistKind, List<ChecklistItem>>> {
  static String _key(ChecklistKind k) => 'washChecklist.${k.name}';

  @override
  Map<ChecklistKind, List<ChecklistItem>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final k in ChecklistKind.values)
        k: decodeChecklist(prefs.getString(_key(k))) ?? defaultChecklists[k]!,
    };
  }

  bool isCustom(ChecklistKind k) =>
      ref.read(sharedPreferencesProvider).containsKey(_key(k));

  Future<void> setItems(ChecklistKind k, List<ChecklistItem> items) async {
    state = {...state, k: List.unmodifiable(items)};
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key(k), encodeChecklist(items));
  }

  Future<void> reset(ChecklistKind k) async {
    state = {...state, k: defaultChecklists[k]!};
    await ref.read(sharedPreferencesProvider).remove(_key(k));
  }
}

String encodeChecklist(List<ChecklistItem> items) => jsonEncode([
  for (final i in items) {'section': i.section.name, 'label': i.label},
]);

/// Null for nothing saved, or something unreadable.
List<ChecklistItem>? decodeChecklist(String? raw) {
  if (raw == null) return null;
  try {
    return [
      for (final m in jsonDecode(raw) as List)
        (
          section: ChecklistSection.values.firstWhere(
            (s) => s.name == (m as Map)['section'],
            orElse: () => ChecklistSection.outside,
          ),
          label: (m as Map)['label'] as String,
        ),
    ];
  } on Object {
    return null;
  }
}
