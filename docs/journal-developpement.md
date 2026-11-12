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

Fichiers : LoanController.swift, GameDTO.swift, LoanTests.swift, front/api.js, front/app.js

Problème : Un jeu emprunté restait indisponible sans possibilité de le rendre depuis l'interface.

Correction : Ajout de la route POST /loans/{loanID}/return, de l'identifiant activeLoanID dans GameDTO et du bouton Rendre dans le frontend.

Test : testReturnedGameBecomesAvailable — Réussi. 20 tests backend réussis, 0 échec.

Résultat : Le bouton Rendre apparaît pour les jeux empruntés.




