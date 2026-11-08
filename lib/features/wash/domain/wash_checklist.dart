/// The three ready-made cleaning checklists, each building on the last.
enum ChecklistKind {
  quick('Quick'),
  full('Full clean'),
  detail('Detail');

  const ChecklistKind(this.label);

  final String label;
}

enum ChecklistSection {
  outside('Outside'),
  inside('Inside');

  const ChecklistSection(this.label);

  final String label;
}

typedef ChecklistItem = ({ChecklistSection section, String label});

const _quick = <ChecklistItem>[
  (section: ChecklistSection.outside, label: 'Rinse off loose dirt'),
  (section: ChecklistSection.outside, label: 'Wheels and tyres'),
  (section: ChecklistSection.outside, label: 'Wash body, top down'),
  (section: ChecklistSection.outside, label: 'Dry with a microfibre'),
];

const _full = <ChecklistItem>[
  ..._quick,
  (section: ChecklistSection.outside, label: 'Outside glass and mirrors'),
  (section: ChecklistSection.inside, label: 'Bin rubbish, empty door pockets'),
  (section: ChecklistSection.inside, label: 'Vacuum seats and floor'),
  (section: ChecklistSection.inside, label: 'Mats shaken out'),
  (section: ChecklistSection.inside, label: 'Wipe dash and console'),
  (section: ChecklistSection.inside, label: 'Inside glass'),
];

const _detail = <ChecklistItem>[
  ..._full,
  (section: ChecklistSection.outside, label: 'Clay bar the paint'),
  (section: ChecklistSection.outside, label: 'Wax or sealant'),
  (section: ChecklistSection.outside, label: 'Tyre shine'),
  (section: ChecklistSection.inside, label: 'Clean or condition seats'),
  (section: ChecklistSection.inside, label: 'Air vents and door jambs'),
];

/// What each checklist holds until it's edited.
const defaultChecklists = <ChecklistKind, List<ChecklistItem>>{
  ChecklistKind.quick: _quick,
  ChecklistKind.full: _full,
  ChecklistKind.detail: _detail,
};
