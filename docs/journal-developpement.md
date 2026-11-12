# Journal de développement — La Pioche

## BUG-01 — Création d'un jeu (HTTP 201)

**Fichier :** `GameController.swift`

**Problème :** La création d'un jeu retournait `200 OK` au lieu de `201 Created`.

**Correction :** J'ai modifié `create()` pour retourner le bon statut HTTP.

**Test :** `testCreateGameReturnsCreated` — Réussi.

**Commit :** `fix: return 201 when creating a game`

## BUG-02 — Durée d'emprunt (14 jours)

**Fichier :** `Loan.swift`

**Problème :** La durée d'emprunt était de 13 jours au lieu de 14.

**Correction :** J'ai modifié la constante `durationInDays` de 13 à 14.

**Test :** `testDueDateIsFourteenDaysAfterBorrowDate` — Réussi.

**Commit :** `fix: set loan duration to 14 days`

## BUG-03 — Empêcher le double emprunt

**Fichier :** `LoanController.swift`

**Problème :** Un jeu déjà emprunté pouvait être emprunté une deuxième fois.

**Correction :** J'ai ajouté une vérification des emprunts actifs avant de créer un nouvel emprunt. Si le jeu n'est pas rendu, l'API retourne `409 Conflict`.

**Test :** `testBorrowingAGameAlreadyOnLoanReturnsConflict` — Réussi.

**Commit :** `fix: prevent duplicate game loans`

## BUG-04 — Jeu introuvable (HTTP 404)

**Fichier :** `GameController.swift`

**Problème :** Un jeu inexistant retournait `500` au lieu de `404`.

**Correction :** J'ai remplacé `.internalServerError` par `.notFound`.

**Test :** `testShowUnknownGameReturnsNotFound` — Réussi.

**Commit :** `fix: return 404 for unknown games`

## BUG-05 — Démarrage du frontend et tests JavaScript

Fichiers : front/api.js, front/tests/api.test.js

Problème : Le message d'erreur HTTP 409 renvoyé par l'API ne correspondait pas à celui attendu par le frontend.

Correction : Harmonisation du message Game already on loan entre l'API, le frontend et les tests.

Test : 20 tests frontend réussis, 0 échec.

## BUG-06 — Retour d'un jeu emprunté

**Fichiers :** `LoanController.swift`, `GameDTO.swift`, `LoanTests.swift`, `front/api.js`, `front/app.js`, `front/tests/app.test.js`.

**Problème :** Un jeu emprunté restait indisponible sans possibilité de le rendre depuis l'interface.

**Correction :** Ajout de la route `POST /loans/{loanID}/return`, du champ `activeLoanID` dans `GameDTO` et du bouton **Rendre** dans le frontend. Après le retour, le jeu redevient disponible et peut être emprunté à nouveau.

**Tests :**
- Backend : `testReturnedGameBecomesAvailable` — 20 tests réussis, 0 échec.
- Frontend : `returning a game makes it available again` — 21 tests réussis, 0 échec.
- Validation manuelle : bouton **Rendre** → **Disponible** → **Emprunter**.

**Résultat :** Le retour d'un jeu fonctionne de bout en bout. Le BUG-06 est fusionné dans `main` et synchronisé sur GitHub (commit `0752fd6`).

## BUG-07 — Historique des emprunts

**Fichiers :** `LoanController.swift`, `LoanTests.swift`, `front/api.js`, `front/app.js`, `front/index.html`, `front/tests/app.test.js`.

**Problème :** L'application ne permettait pas de consulter l'historique des emprunts.

**Correction :** Ajout de la route `GET /loans` et d'un onglet **Historique** affichant le jeu, l'adhérent, les dates d'emprunt et de retour, ainsi que l'état de l'emprunt.

**Tests :**
- Backend : `testLoanHistoryReturnsNewestFirst` — 21 tests réussis, 0 échec.
- Frontend : `loan history shows game, member, dates and return status` — 22 tests réussis, 0 échec.
- Validation manuelle : affichage d'un emprunt rendu depuis l'interface.

**Résultat :** L'historique des emprunts fonctionne de bout en bout.

## BUG-08 — Gestion des retards d'emprunt

**Fichiers :** `front/app.js`, `front/tests/app.test.js`.

**Problème :** L'historique ne distinguait pas les emprunts en retard des emprunts en cours.

**Correction :** Comparaison de `dueAt` avec la date actuelle pour afficher automatiquement le statut "En retard" si le jeu n'a pas été rendu.

**Tests :**
- Emprunt en retard : "En retard".
- Emprunt actif : "En cours".
- Emprunt rendu : "Rendu" (test BUG-07).
- Frontend : 24 tests réussis, 0 échec.

**Résultat :** Les retards sont détectés automatiquement, sans modification de l'API ni de la base de données.

