# Journal de développement — La Pioche

## BUG-01 — Création d'un jeu (HTTP 201)

**Fichier :** `GameController.swift`

**Problème :** La création d'un jeu retournait `200 OK` au lieu de `201 Created`.

**Correction :** J'ai modifié `create()` pour retourner le bon statut HTTP.

**Test :** `testCreateGameReturnsCreated` — Réussi.

**Commit :** `fix: return 201 when creating a game`