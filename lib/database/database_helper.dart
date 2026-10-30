// =============================================================================
// database_helper.dart
// -----------------------------------------------------------------------------
// Point d'accès UNIQUE à la base SQLite locale de l'application « StockFacile ».
//
// Rôle de cette classe :
//   - ouvrir (ou créer) le fichier stock_facile.db sur l'appareil ;
//   - créer les tables au tout premier lancement ;
//   - fournir la même connexion à tout le reste de l'application ;
//   - permettre de fermer proprement la base.
//
// Utilisation typique ailleurs dans le code :
//   final db = await DatabaseHelper().database;
//   final produits = await db.query('produits');
// =============================================================================

// debugPrint : comme print(), mais n'inonde pas la console (messages limités)
// et reste pratique pour les logs de développement.
import 'package:flutter/foundation.dart';

// join() : construit un chemin de fichier correct quel que soit le système
// (Android, iOS...) sans se soucier des "/" ou "\".
import 'package:path/path.dart';

// sqflite : le plugin Flutter qui donne accès à SQLite.
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Nom du fichier de la base sur l'appareil.
  static const String nomBase = 'stock_facile.db';

  // Version du SCHÉMA (structure des tables), pas de l'application.
  // À incrémenter (2, 3...) chaque fois qu'on modifie les tables,
  // et à accompagner d'un onUpgrade (voir remarque en bas du fichier).
  static const int versionBase = 1;

  // ---------------------------------------------------------------------------
  // 1. SINGLETON : une seule instance de DatabaseHelper dans toute l'appli
  // ---------------------------------------------------------------------------
  // Constructeur privé (le "_" le rend inaccessible hors de ce fichier) :
  // personne ne peut faire "DatabaseHelper._interne()" ailleurs.
  DatabaseHelper._interne();

  // L'unique instance, créée une seule fois au chargement de la classe.
  static final DatabaseHelper _instance = DatabaseHelper._interne();

  // Constructeur "factory" : il ne crée PAS de nouvel objet,
  // il renvoie toujours la même instance.
  // => DatabaseHelper() == DatabaseHelper() est vrai partout dans l'appli.
  factory DatabaseHelper() => _instance;

  // La connexion SQLite elle-même. "?" = peut être null tant que la base
  // n'a pas encore été ouverte. "static" = partagée, une seule pour tous.
  static Database? _db;

  // ---------------------------------------------------------------------------
  // 2. OUVERTURE PARESSEUSE (lazy) : on n'ouvre la base qu'au premier besoin
  // ---------------------------------------------------------------------------
  // Getter asynchrone : on l'utilise avec "await DatabaseHelper().database".
  Future get database async {
    // "??=" : si _db est null, on ouvre la base et on stocke le résultat ;
    // sinon on ne fait rien et on garde la connexion existante.
    _db ??= await _ouvrirBase();

    // "!" : on affirme à Dart que _db n'est plus null à ce stade.
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // 3. OUVERTURE DU FICHIER (et création s'il n'existe pas encore)
  // ---------------------------------------------------------------------------
  Future _ouvrirBase() async {
    // Dossier standard prévu par le système pour les bases de données
    // (sur Android : /data/data/<package>/databases).
    final dossier = await getDatabasesPath();

    // Chemin complet du fichier : .../stock_facile.db
    final chemin = join(dossier, nomBase);

    // Affiche le chemin en console : utile pour retrouver le fichier
    // pendant le développement.
    debugPrint('Base SQLite : $chemin');

    return openDatabase(
      chemin,

      // sqflite compare cette version avec celle enregistrée dans le fichier
      // pour décider d'appeler onCreate, onUpgrade ou rien.
      version: versionBase,

      // onConfigure s'exécute à CHAQUE ouverture, avant tout le reste.
      // SQLite désactive les clés étrangères par défaut : sans cette ligne,
      // les contraintes FOREIGN KEY (et ON DELETE RESTRICT) seraient ignorées.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // onCreate n'est appelé QUE si le fichier .db n'existait pas.
      onCreate: _creerTables,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CRÉATION DES TABLES — exécutée UNE SEULE FOIS, au tout premier lancement
  // ---------------------------------------------------------------------------
  // Pour la relancer pendant le développement : désinstaller l'appli
  // (ou supprimer le fichier .db), sinon les modifications ne sont pas prises
  // en compte puisque le fichier existe déjà.
  Future _creerTables(Database db, int version) async {
    debugPrint('onCreate : création des tables (version $version)');

    // ---- Table categories ---------------------------------------------------
    // id          : identifiant auto-incrémenté (1, 2, 3...)
    // nom         : obligatoire (NOT NULL) et unique (pas deux catégories
    //               avec le même nom)
    // description : facultative (peut être NULL)
    await db.execute('''
      CREATE TABLE categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nom         TEXT    NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    // ---- Table produits -----------------------------------------------------
    // prix         : nombre décimal (REAL), interdit d'être négatif
    // quantite     : entier >= 0, vaut 0 si on ne le précise pas
    // disponible   : SQLite n'a pas de type booléen -> on stocke 1 (vrai)
    //                ou 0 (faux). Par défaut : 1 (disponible)
    // date_ajout   : SQLite n'a pas de type date -> on stocke du texte,
    //                idéalement au format ISO 8601
    //                (DateTime.now().toIso8601String()) pour pouvoir trier
    // categorie_id : clé étrangère vers categories.id (obligatoire)
    //
    // ON DELETE RESTRICT : impossible de supprimer une catégorie tant qu'au
    // moins un produit y est rattaché (la suppression lève une erreur).
    // Ne fonctionne que grâce au PRAGMA foreign_keys = ON plus haut.
    await db.execute('''
      CREATE TABLE produits (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nom          TEXT    NOT NULL,
        prix         REAL    NOT NULL CHECK (prix >= 0),
        quantite     INTEGER NOT NULL DEFAULT 0 CHECK (quantite >= 0),
        disponible   INTEGER NOT NULL DEFAULT 1,
        date_ajout   TEXT    NOT NULL,
        categorie_id INTEGER NOT NULL,
        FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    // ---- Données initiales --------------------------------------------------
    // Quelques catégories insérées d'office pour que l'appli ne soit pas vide
    // au premier lancement. Chaque Map = une ligne :
    // clé = nom de la colonne, valeur = contenu.
    const depart = [
      {'nom': 'Alimentation', 'description': 'Produits secs et conserves'},
      {'nom': 'Boissons', 'description': 'Eaux, jus et sodas'},
      {'nom': 'Hygiène', 'description': "Savons et produits d'entretien"},
      {'nom': 'Papeterie', 'description': 'Cahiers, stylos et fournitures'},
    ];

    // db.insert construit lui-même la requête INSERT (avec des paramètres "?",
    // donc sans risque d'injection SQL). L'id est généré automatiquement.
    for (final c in depart) {
      await db.insert('categories', c);
    }
  }

  // ---------------------------------------------------------------------------
  // 5. FERMETURE DE LA BASE
  // ---------------------------------------------------------------------------
  // Utile avant de copier/sauvegarder le fichier .db, ou de le remplacer
  // (restauration d'une sauvegarde). Après fermeture, _db repasse à null :
  // le prochain appel à "database" rouvrira automatiquement la base.
  Future fermer() async {
    // "?." : n'appelle close() que si _db n'est pas null.
    await _db?.close();
    _db = null;
  }
}

// =============================================================================
// REMARQUE — faire évoluer le schéma plus tard
// -----------------------------------------------------------------------------
// Si vous ajoutez une colonne ou une table dans une future version :
//   1. passer versionBase à 2 ;
//   2. ajouter dans openDatabase un paramètre :
//        onUpgrade: (db, ancienne, nouvelle) async {
//          if (ancienne < 2) {
//            await db.execute('ALTER TABLE produits ADD COLUMN code_barre TEXT');
//          }
//        },
//   3. reporter aussi la modification dans _creerTables pour les nouvelles
//      installations.
// Sans onUpgrade, les utilisateurs déjà installés garderaient l'ancien schéma.
// =============================================================================
