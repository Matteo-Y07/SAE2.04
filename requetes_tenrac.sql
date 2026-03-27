-- Q1 : Tous les tenracs qui ont un titre
SELECT t.idTenrac, t.prenom, t.nom, ti.nomTitre
FROM Tenrac t
JOIN Titre ti ON ti.idTitre = t.idTitre;


-- Q2 : nom, prenom, avis des tenracs ayant laisse une note sur le repas "Tenrac Royal"
SELECT t.nom, t.prenom, n.avis
FROM Note n
JOIN Tenrac t ON t.idTenrac = n.idTenrac
JOIN Repas r ON r.idRepas = n.idRepas
WHERE r.libelle = 'Tenrac Royal';


-- Q3 : Libelle de tous les repas ayant une note moyenne >= 3.5
SELECT r.libelle, ROUND(AVG(n.note), 2) as moyenne
FROM Repas r
         JOIN Note n ON n.idRepas = r.idRepas
GROUP BY r.idRepas, r.libelle
HAVING AVG(n.note) >= 3.5
ORDER BY moyenne DESC;


-- Q4 : Tous les tenracs qui ont entretenu une machine
SELECT DISTINCT t.idTenrac, t.prenom, t.nom
FROM Tenrac t
JOIN Entretien e ON e.idTenrac = t.idTenrac;


-- Q6 : nombre Tenracs ayant participe a toutes les reunions organisés par leur club
SELECT count(distinct t.idTenrac)
FROM Tenrac t
WHERE NOT EXISTS (
    SELECT r.idReunion
    FROM Reunion r
             JOIN Tenrac org ON org.idTenrac = r.idTenrac
    WHERE org.idClub = t.idClub
      AND org.idTenrac != t.idTenrac
    MINUS
    SELECT p.idReunion
    FROM Participe p
    WHERE p.idTenrac = t.idTenrac
);


-- Q7 : Titre des tenracs ayant organise plus de 2 reunions
SELECT DISTINCT ti.nomTitre
FROM Titre ti
JOIN Tenrac t ON t.idTitre = ti.idTitre
WHERE t.idTenrac IN (
    SELECT r.idTenrac
    FROM Reunion r
    GROUP BY r.idTenrac
    HAVING COUNT(*) > 2
);


-- Q8 : Desserts constitues d'aliments ne contenant pas d'allergenes
SELECT d.idConstituantPlat, d.nomDessert
FROM Dessert d
WHERE NOT EXISTS (
    SELECT 1
    FROM EstConstitue ec
             JOIN PEUT_PROVOQUER p ON p.idAliment = ec.idAliment
    WHERE ec.idConstituantPlat = d.idConstituantPlat
);


-- Q9 : Toutes les reunions en 2022 sans dessert
SELECT r.idReunion, r.dateReunion, r.adresseReunion
FROM Reunion r
WHERE EXTRACT(YEAR FROM r.dateReunion) = 2022
  AND NOT EXISTS (
    SELECT 1
    FROM ComposeDe cd
    JOIN Dessert d ON d.idConstituantPlat = cd.idConstituantPlat
    WHERE cd.idRepas = r.idRepas
);


-- Q10 : Clubs rattaches directement a l'ordre des tenracs (fils directs)
SELECT tc.idClub, tc.nomClub
FROM TenracClub tc
WHERE tc.idClub_1 = (
    SELECT idClub
    FROM TenracClub
    WHERE idClub_1 IS NULL
);


-- Q11 : Les aliments qui heurtent toutes les croyances possibles
SELECT a.idAliment, a.nomAliment
FROM ALIMENT a
WHERE NOT EXISTS (
    SELECT c.idCroyances
    FROM Croyances c
    MINUS
    SELECT h.idCroyances
    FROM Peut_heurter h
    WHERE h.idAliment = a.idAliment
);


-- Q12 : Toutes les machines entretenues par Thomas Nguyen pendant tout le mois de mai 2025
SELECT DISTINCT m.nomMachine, m.modeleMachine
FROM Machine m
         JOIN Entretien e ON e.idMachine = m.idMachine
         JOIN Tenrac t ON t.idTenrac = e.idTenrac
WHERE t.prenom = 'Thomas'
  AND t.nom = 'Nguyen'
  AND EXTRACT(MONTH FROM e.date_) = 5
  AND EXTRACT(YEAR FROM e.date_) = 2025;


-- Q13 : Afficher la hierarchie complete des clubs
SELECT lpad('>', 2*level, ' ') || tc.NOMCLUB AS hierarchie
FROM TenracClub tc
START WITH tc.idClub_1 IS NULL
CONNECT BY PRIOR tc.idClub = tc.idClub_1;


-- Q14 : Les entrees sans allergenes servies dans la meme reunion qu'un plat contenant de la sauce barbecue
SELECT DISTINCT en.idConstituantRepas, en.nomEntree
FROM Entree en
WHERE NOT EXISTS (
    SELECT 1
    FROM EstConsitute ec
    JOIN Provoque p ON p.idAliment = ec.idAliment
    WHERE ec.idConstituantRepas = en.idConstituantRepas
)
AND en.idConstituantRepas IN (
    SELECT cd.idConstituantRepas
    FROM ComposeDe cd
    WHERE cd.idRepas IN (
        SELECT r.idRepas
        FROM Reunion r
        WHERE r.idReunion IN (
            SELECT r2.idReunion
            FROM Reunion r2
            JOIN ComposeDe cd2 ON cd2.idRepas = r2.idRepas
            JOIN Plats pl ON pl.idConstituantRepas = cd2.idConstituantRepas
            JOIN AccompagneDe ad ON ad.idConstituantRepas = pl.idConstituantRepas
            JOIN Sauces s ON s.idSauce = ad.idSauce
            WHERE LOWER(s.nomSauce) LIKE '%barbecue%'
        )
    )
);


-- Q15 : Les tenracs ayant participe a toutes les reunions organisees par Daphnee Gouin
SELECT t.idTenrac, t.prenom, t.nom
FROM Tenrac t
WHERE NOT EXISTS (
    SELECT r.idReunion
    FROM Reunion r
    JOIN Tenrac org ON org.idTenrac = r.idTenrac
    WHERE org.prenom = 'Daphnee'
      AND org.nom = 'Gouin'
      AND NOT EXISTS (
        SELECT *
        FROM Participe p
        WHERE p.idTenrac = t.idTenrac
        AND p.IDREUNION = r.IDREUNION
    )
);


-- Q16 : Les plats qui ont besoin d'une machine entretenue il y a moins de 6 mois
SELECT DISTINCT pl.idConstituantPlat, pl.nomPlat
FROM Plat pl
         JOIN Recquiert req ON req.idConstituantPlat = pl.idConstituantPlat
WHERE req.idMachine IN (
    SELECT e.idMachine
    FROM Entretien e
    WHERE e.date_ >= ADD_MONTHS(SYSDATE, -6)
);


-- Q17 : Toutes les reunions ou ont ete servis precisement une entree, un plat et un dessert
SELECT r.idReunion, r.dateReunion, r.adresseReunion
FROM Reunion r
JOIN Repas rep ON rep.idRepas = r.idRepas
WHERE (
    SELECT COUNT(*)
    FROM ComposeDe cd
    JOIN Entree en ON en.idConstituantRepas = cd.idConstituantRepas
    WHERE cd.idRepas = rep.idRepas
) = 1
AND (
    SELECT COUNT(*)
    FROM ComposeDe cd
    JOIN Plats pl ON pl.idConstituantRepas = cd.idConstituantRepas
    WHERE cd.idRepas = rep.idRepas
) = 1
AND (
    SELECT COUNT(*)
    FROM ComposeDe cd
    JOIN Dessert d ON d.idConstituantRepas = cd.idConstituantRepas
    WHERE cd.idRepas = rep.idRepas
) = 1;


-- Q18 : Toutes les reunions qui
-- contenaient au moins un des allergenes ou s'opposait a l'une des croyances du tenrac d'id 330
SELECT * FROM Reunion r
WHERE EXISTS (
    SELECT *
    FROM ComposeDe cd
             JOIN estconstitue ec ON ec.idConstituantRepas = cd.idConstituantRepas
             JOIN Peut_provoquer p ON p.idAliment = ec.idAliment
             JOIN Possede po ON po.idAllergene = p.idAllergene
             JOIN Tenrac t ON t.idTenrac = po.idTenrac
    WHERE t.idTenrac = 330
      AND cd.idRepas = r.idRepas
)
   OR EXISTS (
    SELECT *
    FROM ComposeDe cd
             JOIN estconstitue ec ON ec.idConstituantRepas = cd.idConstituantRepas
             JOIN Peut_heurter h ON h.idAliment = ec.idAliment
             JOIN Croit cr ON cr.idCroyances = h.idCroyances
             JOIN Tenrac t ON t.idTenrac = cr.idTenrac
    WHERE t.prenom = 'Jean '
      AND t.nom = 'Louis'
      AND cd.idRepas = r.idRepas
);
