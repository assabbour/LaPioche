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