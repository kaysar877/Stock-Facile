-- ============================================================================
-- StockFacile — requêtes testées dans DB Browser for SQLite
-- ----------------------------------------------------------------------------
-- Chaque requête ci-dessous a été écrite et exécutée dans DB Browser
-- (onglet « Exécuter le SQL ») sur sql/brouillon.db AVANT d'être traduite
-- en Dart. Le commentaire au-dessus de chaque requête rappelle la question
-- du TP à laquelle elle répond, et le commentaire en dessous donne le
-- résultat observé.
-- ============================================================================


-- Q1.5.a — Tous les produits
SELECT * FROM produits;
-- => 6 lignes : Huile d'olive 1 L, Couscous moyen 1 kg, Eau minérale 1,5 L,
--    Jus d'orange 1 L, Savon de Marseille, Cahier 96 pages.


-- Q1.5.b — Les produits en rupture de stock
SELECT * FROM produits WHERE quantite = 0;
-- => 1 seule ligne : Jus d'orange 1 L (quantite 0, disponible 0).


-- Q1.5.c — Les produits triés du plus cher au moins cher
SELECT * FROM produits ORDER BY prix DESC;
-- => Huile d'olive 1 L (18,500), Jus d'orange 1 L (3,200),
--    Savon de Marseille (2,900), Couscous moyen 1 kg (2,300),
--    Cahier 96 pages (1,600), Eau minérale 1,5 L (0,850).


-- Q1.5.d — Le nom de chaque produit avec le nom de sa catégorie (INNER JOIN)
SELECT p.nom, p.prix, c.nom AS categorie
FROM produits p
INNER JOIN categories c ON c.id = p.categorie_id
ORDER BY p.nom;
-- => 6 lignes, par exemple : Cahier 96 pages | 1.6 | Papeterie.
--    L'alias AS categorie évite d'avoir deux colonnes nommées « nom »
--    dans le résultat.


-- Q1.5.e — Le nombre de produits par catégorie (COUNT + GROUP BY)
SELECT c.nom, COUNT(p.id) AS nb_produits
FROM categories c
LEFT JOIN produits p ON p.categorie_id = c.id
GROUP BY c.nom
ORDER BY c.nom;
-- => Alimentation 2, Boissons 2, Hygiène 1, Papeterie 1.
--    LEFT JOIN est utilisé pour qu'une catégorie vide s'affiche quand même
--    (avec 0 produit) : un INNER JOIN la ferait disparaître de la liste.


-- Q1.5.f — La valeur totale du stock (SUM)
SELECT SUM(prix * quantite) AS valeur_totale FROM produits;
-- => 777.5 DT
--    (444 + 92 + 102 + 0 + 43.5 + 96)


-- ============================================================================
-- Q1.6 — Test des contraintes
-- ----------------------------------------------------------------------------
-- Ces trois requêtes doivent être refusées par SQLite. Les messages
-- d'erreur exacts sont notés dans reponses.md.
-- ============================================================================

-- Q1.6.a — Un prix négatif : refusé par CHECK (prix >= 0)
INSERT INTO produits (nom, prix, quantite, date_ajout, categorie_id)
VALUES ('Test prix', -5, 1, '2026-10-05T08:00:00', 1);
-- => ERREUR : CHECK constraint failed: prix >= 0


-- Q1.6.b — Une catégorie qui n'existe pas : refusé par la clé étrangère
INSERT INTO produits (nom, prix, quantite, date_ajout, categorie_id)
VALUES ('Test catégorie', 1, 1, '2026-10-05T08:00:00', 99);
-- => ERREUR : FOREIGN KEY constraint failed


-- Q1.6.c — Supprimer une catégorie qui contient des produits
DELETE FROM categories WHERE id = 1;
-- => ERREUR : FOREIGN KEY constraint failed
--    (Alimentation est encore utilisée par 2 produits : ON DELETE RESTRICT)
