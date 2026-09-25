/// Eine Werkstatt, die für ein oder mehrere Fahrzeuge zuständig ist -
/// z. B. für Service, Reifenwechsel oder die §57a-Begutachtung.
class Workshop {
  final String id;
  String name;
  String? telefon;
  String? adresse;
  bool pruefstelle57a;
  String? notizen;

  Workshop({
    required this.id,
    required this.name,
    this.telefon,
    this.adresse,
    this.pruefstelle57a = false,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'telefon': telefon,
      'adresse': adresse,
      'pruefstelle_57a': pruefstelle57a ? 1 : 0,
      'notizen': notizen,
    };
  }

  factory Workshop.fromMap(Map<String, Object?> map) {
    return Workshop(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      telefon: map['telefon'] as String?,
      adresse: map['adresse'] as String?,
      pruefstelle57a: (map['pruefstelle_57a'] as int? ?? 0) == 1,
      notizen: map['notizen'] as String?,
    );
  }
}
