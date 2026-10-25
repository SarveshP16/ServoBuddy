/// Where a car is in its life with you. Stored by name.
enum VehicleStatus {
  /// On the road: shown everywhere, reminders on.
  active,

  /// Sold or not in use: listed separately, no reminders, history kept.
  retired,

  /// Deleted but its expense history kept. Never listed; its row only
  /// survives so old expenses still carry its name.
  deleted,
}
