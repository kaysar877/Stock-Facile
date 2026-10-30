-- ============================================================================
-- StockFacile — structure de la base de données
-- ----------------------------------------------------------------------------
-- Ce fichier est la référence du schéma : il est créé dans DB Browser
-- (Fichier → Exporter → Base de données vers fichier SQL, "exporter uniquement
-- le schéma") et il est recopié tel quel dans le CREATE TABLE de
-- lib/database/database_helper.dart.
--
-- Les deux tables sont liées par une clé étrangère : chaque produit
-- appartient à une catégorie, et une catégorie peut contenir plusieurs
-- produits.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Table categories : les rayons de l'épicerie.
-- ---------------------------------------------------------------------------
CREATE TABLE categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nom         TEXT    NOT NULL UNIQUE,
  description TEXT
);

-- ---------------------------------------------------------------------------
-- Table produits : le stock de l'épicerie.
--
-- disponible : SQLite n'a pas de type booléen, on stocke 1 (vrai) ou 0 (faux).
-- date_ajout : SQLite n'a pas de type date, on stocke du texte ISO 8601.
-- ---------------------------------------------------------------------------
CREATE TABLE produits (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  nom          TEXT    NOT NULL,
  prix         REAL    NOT NULL CHECK (prix >= 0),
  quantite     INTEGER NOT NULL DEFAULT 0 CHECK (quantite >= 0),
  disponible   INTEGER NOT NULL DEFAULT 1,
  date_ajout   TEXT    NOT NULL,
  categorie_id INTEGER NOT NULL,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE RESTRICT
);
