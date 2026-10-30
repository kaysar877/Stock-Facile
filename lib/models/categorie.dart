// Modèle de la table « categories ».
//
// Une catégorie est une ligne de la base : on la transforme en objet Dart
// avec fromMap(), et on la retransforme en ligne avec toMap().
// C'est le seul endroit où l'on connaît la forme de la table : si la base
// change, c'est ici qu'on ajuste.

class Categorie {
  // L'id est null tant que la catégorie n'a pas été enregistrée en base.
  // C'est ce qui permet de réutiliser le même modèle pour un ajout
  // (id ignoré) et pour une modification (id connu).
  final int? id;
  final String nom;
  final String? description;

  const Categorie({this.id, required this.nom, this.description});

  // Une ligne de la base (Map) devient un objet Dart.
  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
    );
  }

  // L'objet Dart devient une ligne de la base.
  // On n'écrit 'id' que s'il existe : lors d'un INSERT, SQLite génère
  // lui-même l'identifiant, et envoyer id = null serait une erreur.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'description': description,
    };
  }

  // Copie de la catégorie avec un ou plusieurs champs modifiés.
  // Les champs non précisés gardent leur valeur d'origine.
  Categorie copyWith({int? id, String? nom, String? description}) {
    return Categorie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Categorie(id: $id, nom: $nom)';
}
