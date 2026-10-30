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

