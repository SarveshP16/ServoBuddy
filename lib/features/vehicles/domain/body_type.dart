enum BodyType {
  sedan('Sedan'),
  hatch('Hatch'),
  suv('SUV'),
  wagon('Wagon'),
  ute('Ute'),
  van('Van'),
  coupe('Coupe'),
  motorbike('Motorbike'),
  other('Other');

  const BodyType(this.label);

  final String label;
}
