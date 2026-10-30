# StockFacile — réponses aux questions du TP

Journal de travail du TP « Base de données SQLite ». Les réponses sont notées
au fur et à mesure des parties, dans l'ordre du TP.

---

## Partie 00 — Mise en place du projet

### Q0.5 — Pourquoi ne pas envoyer les fichiers .db sur GitHub alors qu'on envoie schema.sql ?

Les deux fichiers ne racontent pas la même chose. `schema.sql` contient la
**structure** de la base : les tables, les colonnes, les types, les clés
étrangères et les contraintes. C'est du texte, on peut le lire, le relire, le
commenter, et Git sait afficher « cette ligne a changé » quand on le modifie.

Le fichier `.db`, lui, contient les **données** : ici les prix, les quantités
et les produits de l'épicerie. Trois raisons de ne pas le pousser :

1. **C'est une donnée privée.** Les prix de vente et le stock du gérant ne
   regardent personne. Sur un dépôt public, tout le monde (et des robots qui
   collectent automatiquement les fichiers) peut le lire, et un dépôt n'est plus
   jamais vraiment privé : on peut le cloner, le forker, le mettre en cache.
2. **Git ne sait pas comparer deux fichiers binaires.** Il ne peut pas dire
   « tu as changé le prix du stylo de 0,5 à 0,6 ». Il voit seulement « le
   fichier a changé, je le stocke encore une fois ». Au bout de quelques
   commits, le dépôt devient lourd et illisible.
3. **La base se régénère toute seule.** Le fichier `.db` n'est que le résultat
   de l'exécution du `CREATE TABLE` et des `INSERT` de départ. Il n'apporte
   aucune information que `schema.sql` ne donne pas déjà.

J'ajoute qu'un `.db` versionné serait vite périmé : le fichier sur GitHub ne
saurait pas que la base de l'ordinateur du gérant a changé depuis. Le
`.gitignore` avec `*.db`, `*.db-wal` et `*.db-shm` évite d'avoir à y penser à
chaque `git add .`.

---

## Partie 01 — Concevoir la base dans DB Browser

### Q1.3 — Les types que SQLite ne connaît pas, et le rôle des contraintes

**Comment on stocke `disponible` et `date_ajout` ?**

SQLite n'a que cinq types de stockage : `INTEGER`, `REAL`, `TEXT`, `BLOB` et
`NULL`. Il n'a ni `BOOLEAN` ni `DATE`.

- `disponible` est donc une colonne `INTEGER` qui contient `1` quand le produit
  est disponible et `0` quand il ne l'est pas. SQLite applique même la règle
  générale « 0 = faux, toute autre valeur = vrai », mais on se limite à 0 et 1
  pour rester explicite. C'est ce que le modèle Dart convertit dans les deux
  sens : `disponible ? 1 : 0` en écriture, `map['disponible'] == 1` en lecture.
- `date_ajout` est une colonne `TEXT` qui contient une date au format
  **ISO 8601**, par exemple `2026-10-01T09:00:00`. Ce format a une propriété
  très pratique : il se trie lexicographiquement dans le même ordre que
  chronologiquement. Un `ORDER BY date_ajout` donne donc directement les
  produits du plus ancien au plus récent, sans calcul particulier.

**Le rôle de AUTOINCREMENT ?**

`AUTOINCREMENT` demande à SQLite de générer lui-même la valeur de la colonne
`id` : 1, 2, 3... Il y a deux différences avec un simple `INTEGER PRIMARY KEY`
(sans AUTOINCREMENT) :

- avec AUTOINCREMENT, un identifiant supprimé n'est **jamais réutilisé**. Le
  produit n° 4 supprimé ne reprendra pas le numéro 4. C'est
  important quand on parle d'un historique ou de captures d'écran : « le
  produit 4 » reste « le produit 4 ».
- sans AUTOINCREMENT, SQLite reprendrait le plus grand identifiant + 1, ce qui
  peut faire réapparaître un numéro déjà utilisé.

**Le rôle de UNIQUE sur `nom` ?**

`UNIQUE` interdit d'avoir deux catégories avec le même nom. C'est une règle
métier : on ne veut pas deux rayons « Boissons ». Concrètement, l'insertion
d'un doublon est refusée par SQLite avec une erreur de type
`UNIQUE constraint failed: categories.nom`, et c'est cette erreur que l'on
attrape en partie 04 pour afficher « Cette catégorie existe déjà ». UNIQUE a
aussi un effet secondaire utile : SQLite crée automatiquement un index sur la
colonne, donc les recherches par nom sont rapides.

**Le rôle de CHECK (prix >= 0) ?**

`CHECK` est une contrainte qui fait vérifier à la base elle-même qu'une valeur
respecte une condition. `CHECK (prix >= 0)` interdit d'enregistrer un prix
négatif, même si le code Dart a un bug, même si quelqu'un écrit directement
du SQL dans la base. La règle est appliquée au plus bas niveau, ce qui est
toujours plus sûr qu'une vérification faite uniquement dans l'interface.

**Que signifie ON DELETE RESTRICT ?**

`ON DELETE RESTRICT` est le comportement de la clé étrangère
`categorie_id → categories.id` : on ne peut pas supprimer une catégorie tant
qu'au moins un produit y est rattaché. SQLite refuse la suppression et renvoie
`FOREIGN KEY constraint failed`. C'est exactement ce qu'on veut pour une
épicerie : effacer la catégorie « Alimentation » ferait disparaître le lien de
ses 2 produits, qui se retrouveraient orphelins.

Une nuance importante : ce comportement n'existe que si les clés étrangères
sont activées. Par défaut SQLite les ignore, il faut écrire
`PRAGMA foreign_keys = ON` à chaque ouverture — c'est justement ce que fait
`onConfigure` dans `database_helper.dart` (partie 03).

### Q1.4 — Pourquoi `'Huile d''olive'` avec deux apostrophes ?

En SQL, une chaîne de caractères est entourée de simples quotes. L'apostrophe
de « d'olive » fermerait donc la chaîne prématurément et la compréhension de la
requête par SQLite deviendrait fausse :

```sql
-- ❌ la chaîne s'arrête à "Huile d" et le reste est interprété comme du SQL
INSERT INTO produits (nom, ...) VALUES ('Huile d'olive 1 L', ...);
```

Pour écrire une apostrophe à l'intérieur d'une chaîne, on la double :
`'Huile d''olive 1 L'`. SQLite lit les deux quotes comme un seul caractère
d'échappement et la chaîne contient bien `Huile d'olive 1 L`.

C'est le même principe que le `\'` de Dart, mais avec deux quotes au lieu
d'une barre oblique inverse — parce qu'en SQL, la barre oblique n'a pas de
signification spéciale dans une chaîne.

### Q1.6 — Les messages d'erreur des trois tests de contraintes

Les trois requêtes ont bien été refusées par SQLite. Les messages affichés
dans DB Browser :

| Test | Requête | Message d'erreur |
|---|---|---|
| a) prix négatif | `INSERT INTO produits ... (-5, ...)` | `CHECK constraint failed: prix >= 0` |
| b) catégorie inexistante | `INSERT INTO produits ... categorie_id = 99` | `FOREIGN KEY constraint failed` |
| c) suppression d'une catégorie utilisée | `DELETE FROM categories WHERE id = 1` | `FOREIGN KEY constraint failed` |

Ce que ça montre :

- **a)** c'est la contrainte `CHECK (prix >= 0)` qui bloque. Le message cite
  précisément la condition, ce qui aide à retrouver la faute.
- **b)** le produit référence la catégorie 99, qui n'existe pas : c'est la clé
  étrangère qui refuse. Si cette requête avait réussi, c'est que les clés
  étrangères étaient désactivées (DB Browser les active par défaut dans
  Préférences → Base de données → Clés étrangères).
- **c)** « Alimentation » est encore utilisée par 2 produits :
  `ON DELETE RESTRICT` refuse la suppression. Le message est le même qu'en b),
  c'est normal : dans les deux cas c'est la même contrainte qui intervient.

J'ai fait « Annuler les modifications » après chaque test pour retrouver
l'état enregistré de la base.

### Q1.7 — Que contient `sql/schema.sql` ?

Le fichier contient **uniquement la structure** de la base, pas les données :
les instructions `CREATE TABLE` des deux tables, avec le détail des colonnes,
des types, de la clé primaire, des contraintes `NOT NULL` / `UNIQUE` /
`CHECK` et de la clé étrangère. C'est la version texte de l'onglet « Structure
de la base de données ».

C'est utile pour trois choses : recréer la base à l'identique sur n'importe
quel poste, comparer d'un coup d'œil l'état du schéma pendant le
développement, et servir de source de vérité pour le `CREATE TABLE` écrit dans
`database_helper.dart`. En partie 10, on le ré-exporte après l'ajout de la
colonne `seuil_alerte` : il représente alors la version 2 du schéma.

### Q1.8 — Pourquoi fermer DB Browser avant qu'un autre programme écrase dans le fichier ?

SQLite est un fichier, pas un serveur : il n'y a pas de serveur qui arbitre
les accès. Quand un programme écrit dans la base, il pose un **verrou
exclusif** sur le fichier. Si un second programme (notre application Flutter)
essaie d'écrire pendant ce temps-là, il reçoit une erreur
`database is locked` et l'écriture échoue.

Il y a aussi un risque de corruption : deux programmes qui écrivent en même
temps dans le même fichier peuvent détruire le travail l'un de l'autre. Enfin,
DB Browser garde en mémoire l'état qu'il a affiché : si l'application modifie
la base derrière son dos, l'affichage devient faux, et une « écriture des
modifications » faite depuis DB Browser écrase alors des données fraichement
ajoutées par l'app.

La règle est donc simple : **une seule écriture à la fois**. On ferme DB
Browser (ou au moins la base) avant de lancer l'application ou de copier le
fichier `.db`.

---

