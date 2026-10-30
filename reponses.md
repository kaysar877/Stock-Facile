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

## Partie 02 — Packages et classes modèles

### Q2.3 — Pourquoi `id` est-il un `int?`, et pourquoi `toMap()` n'écrit `id` que s'il n'est pas null ?

**Pourquoi `int?` (nullable) ?**

Parce qu'un objet `Categorie` peut exister en dehors de la base : celui que
l'on construit dans le formulaire avant de l'enregistrer. Tant qu'il n'est pas
enregistré, il n'a pas d'identifiant — il n'a pas de « numéro de ligne ». Le
modèle doit donc pouvoir représenter les deux situations :

- une catégorie **nouvelle** → `id == null` ;
- une catégorie ** déjà enregistrée** → `id == 5`.

Le typage le rend explicite : impossible d'écrire du code qui suppose qu'un id
existe alors qu'il n'est pas encore attribué.

**Pourquoi n'écrire `id` que s'il n'est pas null ?**

Parce que `toMap()` sert à deux moments très différents :

- lors d'un **INSERT**, on ne connaît pas encore l'id : c'est SQLite qui
  l'attribue (`AUTOINCREMENT`). Si on écrivait `'id': null` dans la Map,
  SQLite essaierait d'insérer un NULL dans une colonne `INTEGER PRIMARY KEY`,
  ce qui est interdit (et l'auto-incrémentation ne se déclencherait pas) ;
- lors d'un **UPDATE**, on a besoin de l'id pour construire le `WHERE id = ?`.

La ligne `if (id != null) 'id': id` règle le problème une fois pour toutes :
la clé n'apparaît dans la Map que si elle a une valeur à donner.

### Question de réflexion — `factory` et conversions de types

**Pourquoi un constructeur `factory` plutôt qu'un constructeur classique ?**

Un constructeur classique (génératif) a une seule mission : **créer un nouvel
objet**. À chaque appel, on obtient une instance neuve.

Un constructeur `factory` peut faire autre chose : il peut **renvoyer un objet
existant** au lieu d'en fabriquer un nouveau. C'est exactement ce dont on a
besoin dans deux cas :

- `Categorie.fromMap(map)` : le nom dit déjà tout — on construit une
  catégorie *à partir d'une ligne*. On pourrait l'écrire avec un constructeur
  classique, mais `fromMap` est plus lisible à l'appel
  (`Categorie.fromMap(ligne)` contre `Categorie(ligne.id, ligne.nom, ...)`),
  et surtout la signature devient impossible à confondre avec le constructeur
  normal ;
- `DatabaseHelper()` : la factory renvoie toujours la même instance (le
  singleton, voir la réponse à la Q3.2).

**Pourquoi `(map['prix'] as num).toDouble()` plutôt que `map['prix'] as double` ?**

Parce que SQLite est à **typage dynamique** : une colonne `REAL` peut très
bien contenir la valeur `5` (stockée sans décimale), et SQLite renverra alors
un `int` à Dart, pas un `double`. Avec `as double`, le programme planterait sur
une erreur de cast alors que la donnée est parfaitement correcte.

En passant par `num` puis `toDouble()`, on accepte les deux cas : un `double`
reste un `double`, un `int` devient `1.0` proprement. Le même piège existe
pour les colonnes `INTEGER` et pour les dates.

---

## Partie 03 — Ouvrir et créer la base depuis Flutter

### Q3.2 — Les quatre questions sur `DatabaseHelper`

**(1) Que se passe-t-il si on écrit deux fois `DatabaseHelper()` dans le code ? Combien d'objets sont créés ?**

Il ne se crée **aucun objet supplémentaire** : les deux appels renvoient
exactement le même objet, la même instance.

```dart
DatabaseHelper() == DatabaseHelper()  // => true
identical(DatabaseHelper(), DatabaseHelper())  // => true
```

Le mécanisme est le constructeur `factory` (commentaire 1) : au lieu de
créer un objet, il renvoie `_instance`, une instance unique créée au
chargement de la classe. Un constructeur génératif aurait créé deux objets
différents, et donc deux connexions potentiellement différentes à la même
base — c'est exactement le piège du « singleton mal fait ».

Un objet `DatabaseHelper` pour toute l'application, ça veut dire :

- une seule connexion SQLite ouverte (donc un seul verrou sur le fichier) ;
- une seule base, donc pas de risque de divergence entre deux « vues » des
  données ;
- un seul endroit qui connaît le chemin du fichier et la version du schéma.

C'est le motif **singleton** : on garantit qu'une ressource coûteuse ou
dangereuse à dupliquer (fichier, connexion, cache) n'existe qu'en un seul
exemplaire. Le mot-clé `factory` est ce qui rend le singleton possible en
Dart, parce qu'un constructeur classique ne peut pas refuser de créer un
objet.

**(2) Que fait l'opérateur `??=` ?**

`??=` est l'**affectation si nulle** (null-aware assignment). C'est le
raccourci pour « si la variable vaut `null`, on lui donne la valeur de
l'expression de droite ; sinon on ne touche à rien ».

```dart
// ces deux lignes font la même chose
_db ??= await _ouvrirBase();
if (_db == null) _db = await _ouvrirBase();
```

Appliqué ici (commentaire 2), il rend l'ouverture **paresseuse** (lazy) :

- au premier appel à `DatabaseHelper().database`, `_db` vaut `null` : la base
  est ouverte, puis le résultat est mémorisé ;
- à tous les appels suivants, `_db` n'est plus `null` : la ligne ne fait
  rien, et la connexion existante est réutilisée.

Sans `??=`, il faudrait écrire la condition à chaque fois, et surtout on
risquerait d'ouvrir la base deux fois si deux écrans demandaient la connexion
en même temps.

**(3) Pourquoi le `PRAGMA foreign_keys = ON` est-il dans `onConfigure` et pas dans `onCreate` ?**

Parce que l'activation des clés étrangères est un **réglage de la connexion**,
pas une propriété du fichier. `PRAGMA foreign_keys` ne s'enregistre pas dans la
base : il vaut 0 (désactivé) à chaque nouvelle connexion, et il faut le
reactiver à chaque ouverture. La preuve : si on ouvre la même base avec DB
Browser puis avec l'application, chacune a sa propre connexion et son propre
réglage.

Donc :

- `onCreate` n'est appelé qu'**une fois**, quand le fichier `.db` n'existe
  encore. Y mettre le PRAGMA reviendrait à n'activer les clés étrangères que
  sur la toute première ouverture. À la deuxième exécution de l'application,
  le fichier existe déjà, `onCreate` n'est pas appelé, et les contraintes
  `FOREIGN KEY` et `ON DELETE RESTRICT` seraient **silencieusement ignorées** ;
- `onConfigure` est appelé à **chaque ouverture**, avant `onCreate` et avant
  `onUpgrade`. Le PRAGMA est donc toujours appliqué, et les tables sont même
  créées avec les clés étrangères déjà actives.

Autrement dit : `onCreate` sert à créer le contenu, `onConfigure` sert à
configurer la connexion. C'est la bonne place pour tout ce qui doit être vrai
à chaque fois, `PRAGMA foreign_keys = ON` en premier.

**(4) Combien de fois `onCreate` est-il appelé dans toute la vie de l'application ?**

**Une fois**, la première fois que l'application tourne sur un poste donné.

`onCreate` n'est appelé que si le fichier `.db` n'existe pas encore. Au
premier lancement, sqflite crée le fichier et appelle `onCreate`, qui crée
les tables et insère les 4 catégories de départ. Ensuite, à chaque
relancement, le fichier existe déjà : sqflite compare la version du fichier
avec `versionBase` et n'appelle plus `onCreate`.

C'est exactement ce que montre la question suivante (Q3.5) : au second
lancement, le message « onCreate : création des tables » ne s'affiche plus.

Le schéma évolue alors par un autre chemin :

- si la version du code est **supérieure** à celle du fichier → `onUpgrade`
  est appelé (partie 10, ajout de la colonne `seuil_alerte`) ;
- `onCreate` ne reviendrait que si le fichier disparaissait : désinstallation
  de l'application, suppression du `.db`, ou « Réinitialiser la base » de la
  partie 11.

C'est pour ça que `onCreate` et `onUpgrade` doivent être maintenus en
parallèle : `onCreate` sert les nouvelles installations, `onUpgrade` sert les
installations existantes.
