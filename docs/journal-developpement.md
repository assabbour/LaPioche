# Journal de développement — La Pioche

## BUG-01 — Correction du statut HTTP lors de la création d'un jeu

**Fichier :** `back/Sources/App/Controllers/GameController.swift`

**Problème identifié :**  
La route `POST /games` renvoyait `200 OK` au lieu de `201 Created`.

**Cause :**  
La méthode `encodeResponse(for: req)` renvoyait le statut `200` par défaut.

**Correction apportée :**  
J'ai modifié la méthode `create()` pour définir explicitement le statut HTTP `201 Created`, tout en conservant le contenu de la réponse.

**Test associé :**  
`testCreateGameReturnsCreated`

**Résultat :**  
À confirmer après exécution du test.

**Commit Git :**  
`fix: return 201 when creating a game`