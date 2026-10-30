// Modèle de la table « produits ».
//
// Attention aux types : SQLite ne connaît ni le booléen ni la date.
// - un booléen est stocké dans un INTEGER, 1 pour vrai et 0 pour faux ;
// - une date est stockée dans un TEXT au format ISO 8601, ce qui permet
//   de trier les lignes par date avec un simple ORDER BY.

class Produit {
  final int? id;
  final String nom;
  final double prix;
  final int quantite;
  final bool disponible;
  final DateTime dateAjout;
  final int categorieId;

  const Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.quantite = 0,
    this.disponible = true,
    required this.dateAjout,
    required this.categorieId,
  });

  // Une ligne de la base devient un objet Dart.
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      // SQLite renvoie un int quand la valeur stockée n'a pas de décimale :
      // on repasse donc par num avant de convertir en double.
      prix: (map['prix'] as num).toDouble(),
      quantite: map['quantite'] as int,
      // disponible est stocké sous forme de 1 / 0 : le widget attend un booléen.
      disponible: map['disponible'] == 1,
      // La date est stockée en texte ISO 8601, on la relit avec DateTime.parse.
      dateAjout: DateTime.parse(map['date_ajout'] as String),
      categorieId: map['categorie_id'] as int,
    );
  }

  // L'objet Dart devient une ligne de la base.
  // Les clés doivent être exactement les noms des colonnes : 'categorie_id'
  // et non 'categorieId', sinon SQLite refuse l'écriture.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'prix': prix,
      'quantite': quantite,
      'disponible': disponible ? 1 : 0,
      'date_ajout': dateAjout.toIso8601String(),
      'categorie_id': categorieId,
    };
  }

  // Copie du produit avec un ou plusieurs champs remplacés.
  // Indispensable pour une modification partielle : on garde l'id et la
  // date d'ajout d'origine, on ne change que ce qui a été demandé.
  Produit copyWith({
    int? id,
    String? nom,
    double? prix,
    int? quantite,
    bool? disponible,
    DateTime? dateAjout,
    int? categorieId,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      disponible: disponible ?? this.disponible,
      dateAjout: dateAjout ?? this.dateAjout,
      categorieId: categorieId ?? this.categorieId,
    );
  }

  @override
  String toString() => 'Produit(id: $id, nom: $nom, prix: $prix, quantite: $quantite)';
}
