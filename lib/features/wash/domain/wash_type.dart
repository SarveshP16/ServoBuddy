/// How a car was washed. Stored by name.
enum WashType {
  home('At home', 'Wash at home', paid: false),
  automatic('Automatic', 'Automatic wash'),
  hand('Hand wash', 'Hand wash'),
  detail('Detail', 'Detail');

  const WashType(this.label, this.title, {this.paid = true});

  /// The pill on the forms.
  final String label;

  /// The line in history, and the expense title for a paid one.
  final String title;

  /// Paid at a wash (logged in Expenses as Car wash) rather than done
  /// yourself.
  final bool paid;
}
