import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/garage.dart';

/// The whole garage, live. Every screen reads from this.
final garageStreamProvider = StreamProvider<Garage>(
  (ref) => ref.watch(garageRepositoryProvider).watch(),
);

/// The latest garage, or an empty one for the instant before the first load.
/// Screens use this so they never flash a spinner for a local database read.
final garageProvider = Provider<Garage>(
  (ref) => ref.watch(garageStreamProvider).value ?? Garage.empty,
);

/// True once the first snapshot has arrived (so "no vehicles yet" can be told
/// apart from "not loaded yet").
final garageLoadedProvider = Provider<bool>(
  (ref) => ref.watch(garageStreamProvider).hasValue,
);
