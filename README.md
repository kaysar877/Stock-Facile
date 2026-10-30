# StockFacile

Application Flutter de gestion de stock pour une épicerie de quartier,
réalisée dans le cadre du TP « Base de données SQLite ».

Les données restent sur l'appareil : tout passe par une base SQLite locale
(`stock_facile.db`), accessible hors connexion.

## Fonctionnalités

*(à compléter au fil du TP — voir la partie 11 pour la version finale)*

## Base de données

- `categories` (id, nom, description)
- `produits` (id, nom, prix, quantite, disponible, date_ajout, categorie_id)

Le schéma complet est dans [`sql/schema.sql`](sql/schema.sql), et les requêtes
testées dans DB Browser sont dans [`sql/requetes.sql`](sql/requetes.sql).

## Lancer le projet

```bash
flutter pub get
flutter run -d windows   # desktop Windows (SQLite via FFI)
```

## Structure du projet

```
lib/
├── models/       # Categorie, Produit (fromMap / toMap)
├── database/     # DatabaseHelper, DAOs
├── screens/      # écrans de l'application
├── widgets/      # composants réutilisables
└── main.dart
sql/              # schema.sql, requetes.sql
captures/         # captures d'écran du TP
reponses.md       # réponses aux questions du TP
```

## Auteur

Prénom Nom – Groupe
