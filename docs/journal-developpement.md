# Journal de développement — La Pioche

## Suivi du backlog officiel

Ticket	Fonctionnalité	Statut
BUG-01	Création d'un jeu — HTTP 201	Terminé
BUG-02	Durée d'emprunt — 14 jours	Terminé
BUG-03	Empêcher le double emprunt	Terminé
BUG-04	Jeu introuvable — HTTP 404	Terminé
FEAT-01	Modifier et supprimer un jeu	Terminé
FEAT-02	Modifier et supprimer un adhérent	Terminé
FEAT-03	Rendre un jeu	Terminé
FEAT-04	Consulter les emprunts d'un adhérent	Terminé
FEAT-05	Consulter les emprunts en retard	Terminé
FEAT-06	Rechercher un jeu	Terminé
FEAT-07	Filtrer les jeux disponibles	À faire
BONUS-01	Authentification JWT	Facultatif
BONUS-02	Intégration Bootstrap 5	Facultatif

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

## FEAT-05 — Emprunts en retard

*Ancienne référence interne : BUG-08*

**Fichiers :** `back/Sources/App/Controllers/LoanController.swift`, `back/Tests/AppTests/LoanTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`.

**Besoin :** Identifier les emprunts non rendus dont la date limite est dépassée.

**Développement réalisé :**
- Création de la route `GET /loans/overdue`.
- Filtrage des emprunts non rendus dont la date limite est dépassée.
- Tri des emprunts en retard par date limite croissante.
- Ajout du bouton « Emprunts en retard » dans l'historique.
- Affichage du nombre de jours de retard.
- Ajout du compteur « Historique (N) » dans la navigation.
- Conservation des états « En cours », « En retard » et « Rendu ».
- Ajout du bouton « Tous les emprunts » pour revenir à l'historique complet.
- Affichage du message « Aucun emprunt en retard » lorsque la liste est vide.

**Tests :**
- Backend : 32 tests réussis, 0 échec.
- Frontend : 2 fichiers de tests réussis, 0 échec.
- Vérification manuelle du compteur et du nombre de jours de retard.
- Vérification du filtre avec un emprunt réellement en retard.
- Vérification de l'exclusion des emprunts déjà rendus.
- Vérification de l'affichage lorsque la liste des retards est vide.

**Statut :** Terminé.

## FEAT-06 — Rechercher un jeu par titre

**Fichiers :** `GameController.swift`, `GameTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`, `front/style.css`.

**Besoin :** Permettre de retrouver rapidement un jeu en saisissant son titre.

**Développement réalisé :**

- Ajout du paramètre optionnel `search` à la route `GET /games`.
- Recherche des jeux par titre, sans distinction entre majuscules et minuscules.
- Ajout d'un champ de recherche dans la page « Jeux ».
- Actualisation de la liste lors de la saisie.
- Affichage du message « Aucun jeu ne correspond à votre recherche » lorsqu'aucun résultat n'est trouvé.
- Ajout d'un espacement entre le champ de recherche et les cartes.

**Tests :**

- Backend : 35 tests réussis, 0 échec.
- Frontend : vérification des tests à confirmer.
- Validation manuelle : recherche avec résultat et recherche sans résultat.
- Vérification de l'affichage et de l'espacement dans Safari.

**Statut :** Développement terminé, validation finale avant commit.

## FEAT-07 — Filtrer les jeux disponibles

**Fichiers :** `front/index.html`, `front/app.js`, `front/tests/app.test.js`.

**Besoin :** Afficher uniquement les jeux disponibles à l'emprunt.

**Développement réalisé :**

- Ajout de la case « Jeux disponibles uniquement ».
- Filtrage des jeux avec `isAvailable`.
- Conservation de la recherche par titre FEAT-06.
- Actualisation automatique de la liste.
- Affichage d'un message lorsqu'aucun jeu disponible ne correspond aux critères.

**Tests :**

- Frontend : 2 fichiers de tests réussis, 0 échec.
- Test automatisé du filtre activé et désactivé.
- Validation manuelle avec un jeu disponible et un jeu emprunté.
- Vérification du fonctionnement avec la recherche par titre.

**Statut :** Terminé.