# Journal de développement — La Pioche

## Suivi du backlog officiel

| Ticket | Fonctionnalité | Statut |
|---|---|---|
| BUG-01 | Création d'un jeu — HTTP 201 | Terminé |
| BUG-02 | Durée d'emprunt — 14 jours | Terminé |
| BUG-03 | Empêcher le double emprunt | Terminé |
| BUG-04 | Jeu introuvable — HTTP 404 | Terminé |
| FEAT-01 | Modifier et supprimer un jeu | Terminé |
| FEAT-02 | Modifier et supprimer un adhérent | Développé — tests frontend à vérifier |
| FEAT-03 | Rendre un jeu | Développé — critères à vérifier |
| FEAT-04 | Consulter les emprunts d'un adhérent | À faire |
| FEAT-05 | Consulter les emprunts en retard | Partiellement développé |
| FEAT-06 | Rechercher un jeu | À faire |
| FEAT-07 | Filtrer les jeux disponibles | À faire |
| BONUS-01 | Authentification JWT | Facultatif |
| BONUS-02 | Intégration Bootstrap 5 | Facultatif |

## Corrections des anomalies officielles

### BUG-01 — Création d'un jeu (HTTP 201)

**Fichier :** `GameController.swift`

**Problème :** La création d'un jeu retournait `200 OK` au lieu de `201 Created`.

**Correction :** Modification de `create()` pour retourner le bon statut HTTP.

**Test :** `testCreateGameReturnsCreated` — Réussi.

**Commit :** `fix: return 201 when creating a game`

### BUG-02 — Durée d'emprunt (14 jours)

**Fichier :** `Loan.swift`

**Problème :** La durée d'emprunt était de 13 jours au lieu de 14.

**Correction :** Modification de la constante `durationInDays` de 13 à 14.

**Test :** `testDueDateIsFourteenDaysAfterBorrowDate` — Réussi.

**Commit :** `fix: set loan duration to 14 days`

### BUG-03 — Empêcher le double emprunt

**Fichier :** `LoanController.swift`

**Problème :** Un jeu déjà emprunté pouvait être emprunté une deuxième fois.

**Correction :** Vérification des emprunts actifs avant de créer un nouvel emprunt. Si le jeu n'est pas rendu, l'API retourne `409 Conflict`.

**Test :** `testBorrowingAGameAlreadyOnLoanReturnsConflict` — Réussi.

**Commit :** `fix: prevent duplicate game loans`

### BUG-04 — Jeu introuvable (HTTP 404)

**Fichier :** `GameController.swift`

**Problème :** Un jeu inexistant retournait `500` au lieu de `404`.

**Correction :** Remplacement de `.internalServerError` par `.notFound`.

**Test :** `testShowUnknownGameReturnsNotFound` — Réussi.

**Commit :** `fix: return 404 for unknown games`

## Fonctionnalités officielles développées

### FEAT-01 — Modifier et supprimer un jeu

**Fichiers :** `GameController.swift`, `GameTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`.

**Besoin :** Permettre de modifier et supprimer un jeu.

**Développement :**
- Ajout de `PUT /games/:gameID`.
- Ajout de `DELETE /games/:gameID`.
- Vérification des contraintes liées aux emprunts.
- Ajout des boutons « Modifier » et « Supprimer » dans le frontend.
- Réutilisation du formulaire pour la modification.

**Tests :**
- Tests backend validés.
- Modification et suppression vérifiées manuellement.

**Commit :** `aa43760` — Fusionné dans `main`.

**Statut :** Terminé.

### FEAT-02 — Modifier et supprimer un adhérent

**Fichiers :** `MemberController.swift`, `MemberTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`.

**Besoin :** Modifier les informations d'un adhérent et permettre sa suppression sans perdre l'historique des emprunts.

**Développement :**
- Ajout de `PUT /members/:memberID`.
- Vérification de l'unicité de l'adresse e-mail (`409 Conflict`).
- Ajout de `DELETE /members/:memberID`.
- Refus de suppression si l'adhérent possède un historique d'emprunts (`409 Conflict`).
- Ajout des boutons « Modifier » et « Supprimer ».
- Réutilisation du formulaire d'ajout pour la modification.
- Affichage des erreurs en français.

**Tests :**
- `testUpdateMember` — Réussi.
- `testUpdateMemberWithDuplicateEmailReturnsConflict` — Réussi.
- `testDeleteMember` — Réussi.
- `testDeleteMemberWithLoanHistoryReturnsConflict` — Réussi.
- Backend : 30 tests réussis, 0 échec.
- Frontend : modification et refus de suppression avec historique vérifiés manuellement.

**Statut :** Développé — tests frontend à vérifier.

### FEAT-03 — Retour d'un jeu emprunté

*Ancienne référence interne : BUG-06*

**Fichiers :** `LoanController.swift`, `GameDTO.swift`, `LoanTests.swift`, `front/api.js`, `front/app.js`, `front/tests/app.test.js`.

**Besoin :** Permettre de rendre un jeu emprunté et de le rendre à nouveau disponible.

**Développement :**
- Ajout de `POST /loans/:id/return`.
- Ajout du champ `activeLoanID` dans `GameDTO`.
- Ajout du bouton « Rendre » dans le frontend.
- Actualisation de la disponibilité après le retour.

**Tests :**
- Backend : `testReturnedGameBecomesAvailable` — 20 tests réussis.
- Frontend : `returning a game makes it available again` — 21 tests réussis.
- Validation manuelle : Rendre → Disponible → Emprunter.

**Commit :** `0752fd6` — Fusionné dans `main`.

**Statut :** Fonctionnalité développée. Vérifier la couverture des erreurs `404`, `409` et du refus affiché en français.

### FEAT-04 — Consulter les emprunts d'un adhérent

**Fichiers :** `MemberController.swift`, `MemberTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`.

**Besoin :** Permettre de consulter l'historique des emprunts d'un adhérent, y compris les jeux déjà rendus.

**Développement :**
- Ajout de `GET /members/:memberID/loans`.
- Récupération des emprunts par ordre chronologique.
- Gestion des erreurs `400` (identifiant invalide) et `404` (adhérent inexistant).
- Ajout du bouton « Voir les emprunts » dans la liste des adhérents.
- Réutilisation de l'affichage de l'historique existant.
- Ajout du bouton « Tous les emprunts » pour revenir à l'historique global.

**Tests :**
- Backend : `testGetMemberLoans` — réussi.
- Backend : 31 tests réussis, 0 échec.
- Frontend : 2 fichiers de tests réussis, 0 échec.
- Validation manuelle : affichage de l'historique d'un adhérent et retour à l'historique global.

**Statut :** Terminé.


### FEAT-05 — Emprunts en retard

*Ancienne référence interne : BUG-08*

**Fichiers :** `front/app.js`, `front/tests/app.test.js`.

**Besoin :** Identifier les emprunts non rendus dont la date limite est dépassée.

**Développement réalisé :**
- Comparaison de `dueAt` avec la date actuelle.
- Affichage des états « En cours », « En retard » et « Rendu » dans l'historique.

**Tests :**
- Emprunt en retard : « En retard ».
- Emprunt actif : « En cours ».
- Emprunt rendu : « Rendu ».
- 24 tests frontend réussis.

**Travail restant pour respecter le backlog :**
- Backend : créer `GET /loans/overdue`.
- Frontend : ajouter une vue dédiée aux retards.
- Afficher le nombre de jours de retard.
- Ajouter un compteur visible sans ouvrir la vue.
- Prévoir un message lorsque la liste est vide.
- Ajouter les tests correspondants.

**Statut :** Partiellement développé.

## Travaux supplémentaires

### TECH-01 — Démarrage du frontend et tests JavaScript

*Ancienne référence interne : BUG-05*

**Fichiers :** `front/api.js`, `front/tests/api.test.js`.

**Problème :** Le message HTTP `409` renvoyé par l'API ne correspondait pas à celui attendu par le frontend.

**Correction :** Harmonisation du message `Game already on loan` entre l'API, le frontend et les tests.

**Tests :** 20 tests frontend réussis, 0 échec.

### EXTRA-01 — Historique général des emprunts

*Ancienne référence interne : BUG-07*

**Fichiers :** `LoanController.swift`, `LoanTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`, `front/tests/app.test.js`.

**Besoin :** Permettre de consulter l'historique général des emprunts.

**Développement :**
- Ajout de `GET /loans`.
- Ajout de l'onglet « Historique ».
- Affichage du jeu, de l'adhérent, des dates et de l'état de l'emprunt.

**Tests :**
- Backend : `testLoanHistoryReturnsNewestFirst` — 21 tests réussis.
- Frontend : `loan history shows game, member, dates and return status` — 22 tests réussis.
- Validation manuelle : consultation d'un emprunt rendu.

**Statut :** Développé.

**Remarque :** Cette fonctionnalité supplémentaire ne remplace pas FEAT-04, qui demande une consultation des emprunts depuis chaque adhérent.

## Conventions de développement

- Utiliser les références officielles `BUG-01` à `BUG-04` et `FEAT-01` à `FEAT-07`.
- Utiliser `TECH` pour les corrections techniques supplémentaires et `EXTRA` pour les fonctionnalités hors backlog.
- Conserver les anciens commits Git.
- Développer les fonctionnalités restantes dans l'ordre du backlog.
- Ajouter les tests dans le même commit que le code.
- Vérifier les tests backend et frontend avant chaque push.