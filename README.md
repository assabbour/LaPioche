# La Pioche

API de gestion d'une ludothèque, écrite avec Vapor 4, et son application web. Elle permet de gérer des jeux de société, des adhérent·es et les emprunts associés.

Ce dépôt est le point de départ de votre projet individuel d'une semaine. **Lisez ce `README` en entier avant de lancer quoi que ce soit** : il explique comment lancer l'API, le front et les tests, et comment vérifier son travail avant de pousser. Lisez ensuite le sujet dans [`docs/sujet.md`](docs/sujet.md), puis le backlog dans [`docs/backlog.md`](docs/backlog.md).

## Récupérer le projet

Ne travaillez pas directement sur le dépôt : vous n'avez pas le droit d'y pousser, et votre travail doit rester le vôtre. Vous partez d'un **fork**, c'est-à-dire votre propre copie du dépôt sur GitHub.

1. Sur la page GitHub du dépôt fourni (<https://github.com/cmandine2/LaPioche>), cliquez sur **Fork** (en haut à droite), puis sur **Create fork**. Le dépôt apparaît dans votre compte GitHub.
2. Clonez **votre fork** (et non le dépôt d'origine) :

```bash
git clone git@github.com:<votre-identifiant>/LaPioche.git
```

3. Placez-vous dans le dossier cloné :

```bash
cd LaPioche
```

Le projet contient `back/` (l'API) et `front/` (l'application web) : les commandes de ce `README` se lancent depuis ces dossiers.

4. Vérifiez que `origin` pointe bien vers votre fork :

```bash
git remote -v
```

Ensuite, travaillez et commitez normalement. Chaque `git push` envoie votre travail sur votre fork. Les consignes de commit sont dans le sujet (« Historique git »).

Pour rendre votre projet, communiquez l'adresse de votre fork.

## Domaine

- **Jeu** : titre, nombre de joueur·ses minimum et maximum, durée en minutes
- **Adhérent·e** : nom, adresse e-mail
- **Emprunt** : jeu, adhérent·e, date d'emprunt, date de retour prévue, date de retour effective (optionnelle)

Les règles métier à respecter sont décrites dans le sujet.

## Organisation du code

Le projet est séparé en deux : `back/` (l'API Vapor) et `front/` (l'application web).

| Dossier | Contenu |
| --- | --- |
| `back/Sources/App/Models/` | Modèles Fluent, un par table |
| `back/Sources/App/Migrations/` | Création des tables |
| `back/Sources/App/DTOs/` | Corps des requêtes et des réponses |
| `back/Sources/App/Controllers/` | Les routes, regroupées par ressource |
| `back/Tests/AppTests/` | Tests unitaires |
| `back/Public/` | Documentation Swagger de l'API (`openapi.yaml`) |
| `front/` | Application web qui appelle l'API (voir « Lancer le projet ») |
| `front/tests/` | Tests du front, exécutés dans le navigateur |
| `docs/` | Sujet et backlog |

## Prérequis

- macOS avec Xcode 27
- Swift 6 ou supérieur

## Lancer le projet

Le projet se compose de deux serveurs qui tournent en même temps, chacun dans son terminal : l'API, puis le front.

### 1. L'API (back)

**Démarrage avec authentification JWT (BONUS-01)**

Pour démarrer l'API avec l'authentification JWT, utilisez :

```bash
cd back
sh start.sh
```

Le script génère automatiquement une clé JWT locale lors du premier lancement et la conserve dans `back/.env` (ignoré par Git).

Aucune configuration manuelle n'est nécessaire. Vous pouvez ensuite ouvrir le frontend pour tester l'inscription et la connexion.

```bash
cd back
swift run
```

L'API écoute sur `http://127.0.0.1:8081` (port fixé dans `configure.swift`). La base SQLite est stockée dans le fichier `db.sqlite`, créé automatiquement et ignoré par git. Pour repartir d'une base vide, supprimez ce fichier.

Si la compilation échoue sur une étape `CodeSign` (même cause que pour les tests : dossier synchronisé par iCloud ou `Documents`), supprimez d'abord le dossier de build puis compilez hors du dossier du projet :

```bash
rm -rf .build
swift run --scratch-path /tmp/lapioche-build
```

### 2. Le front

Le front est une application web (HTML, CSS et JavaScript, sans outil de build) **séparée du back** : elle est dans `front/` et appelle l'API par HTTP. Elle a besoin que l'API tourne : lancez-la d'abord (étape 1), puis ouvrez un second terminal :

```bash
cd front
sh serve.sh
```

Ouvrez ensuite `http://localhost:8080`. `Ctrl+C` arrête Apache. Le script `serve.sh` copie le front dans un dossier temporaire puis lance Apache, le serveur web déjà installé sur macOS, avec `httpd.conf`, une configuration minimale propre au projet : elle ne modifie rien sur votre machine et ne demande pas `sudo`. La copie est nécessaire car macOS interdit à Apache de lire `Documents` et les dossiers iCloud (erreur `Operation not permitted`). Après une modification du front, arrêtez le script (`Ctrl+C`), relancez-le et rechargez la page.

Les deux serveurs ont des ports différents : ce sont deux origines, d'où le CORS configuré côté Vapor (voir plus bas).

| Serveur | Dossier | Commande | Adresse |
| --- | --- | --- | --- |
| API Vapor | `back/` | `swift run` | `http://localhost:8081` |
| Front, servi par Apache | `front/` | `sh serve.sh` | `http://localhost:8080` |

| Fichier du front | Rôle |
| --- | --- |
| `config.js` | Adresse de l'API (`http://localhost:8081`) |
| `api.js` | Client de l'API : une fonction par route, et traduction des erreurs en français |
| `app.js` | Écrans et formulaires |
| `index.html`, `style.css` | Structure et mise en page |
| `httpd.conf`, `serve.sh` | Configuration d'Apache et script qui le lance |


## Bonus

Une fois le backlog terminé, `docs/backlog.md` propose deux bonus facultatifs : `BONUS-01`, une authentification (les routes `/auth/...` figurent déjà dans le Swagger) et `BONUS-02`, une bibliothèque de design pour le front. Rien n'est à faire dans le code avant d'avoir fini le reste.

## Documentation de l'API

Une fois l'API lancée, ouvrez `http://localhost:8081` dans un navigateur : la page Swagger liste les routes, leurs corps de requête et de réponse, et les codes d'erreur. Le bouton « Try it out » permet d'appeler l'API directement depuis la page.

La description de l'API est écrite à la main dans `back/Public/openapi.yaml`. Elle décrit **toutes** les routes, y compris celles que vous devez encore ajouter côté back : elle sert de référence pour leur comportement (corps, codes de réponse). Les routes pas encore implémentées y figurent, mais répondent `404` tant qu'elles n'existent pas. Si vous modifiez le comportement d'une route, mettez la description à jour. La page charge l'interface Swagger depuis un CDN : une connexion Internet est nécessaire pour l'afficher.

## Lancer les tests

### Les tests du back

Depuis le dossier `back/` :

```bash
swift test
```

Au départ, 4 tests échouent : ce sont les anomalies à corriger (voir le sujet). L'objectif est que la suite entière passe, soit `0 failures` en fin de sortie. La base de données est créée en mémoire pour chaque test : lancer les tests ne modifie jamais `db.sqlite`.

Le message `Test run with 0 tests in 0 suites` qui s'affiche à la toute fin est normal : il concerne un autre framework de test, qui n'est pas utilisé dans ce projet. Les résultats qui comptent sont ceux de la ligne `Executed ... tests`.

Si la signature du bundle de tests échoue avec le message `resource fork, Finder information, or similar detritus not allowed`, c'est souvent lié à un dossier synchronisé (iCloud, Documents). Compilez alors hors du dossier du projet :

```bash
swift test --scratch-path /tmp/lapioche-build
```

### Les tests du front

Les tests du front s'exécutent dans le navigateur, sans installation et sans lancer l'API (une fausse API la remplace). Ils couvrent le client d'API (`api.js`) et les écrans (`app.js`).

1. Lancez le front : dans `front/`, `sh serve.sh`.
2. Ouvrez `http://localhost:8080/tests/` dans le navigateur.
3. Chaque test s'affiche en vert (réussi) ou en rouge (échec, avec la raison), et un bilan s'affiche en haut de la page. L'onglet du navigateur indique `OK` ou `ÉCHEC` avec le nombre de tests.
4. Après une modification du code ou des tests, arrêtez `serve.sh` (`Ctrl+C`), relancez-le, puis rechargez la page.

### Écrire un test du front

Les tests sont dans `front/tests/` : `api.test.js` pour le client d'API, `app.test.js` pour les écrans. Un test se déclare avec `test("nom", async () => { ... })`. Le nom est en anglais et décrit le comportement, comme pour les tests Vapor (par exemple `borrowing a game sends the game and the chosen member`). Deux outils de `tests/helpers.js` suffisent à la plupart des cas :

- `mountApp(routes)` charge la vraie page branchée sur une fausse API. `routes` associe `"MÉTHODE /chemin"` à la réponse voulue : `"GET /games": [{ ... }]` pour un succès, `"POST /games": [400, { error: true, reason: "title is empty" }]` pour une erreur, une fonction pour une réponse qui dépend de la requête. Il renvoie des raccourcis (`$`, `$$`, `click`, `type`, `calls`) pour agir sur la page et lire les requêtes envoyées ;
- `fakeApi(routes)` fait de même pour tester `api.js` seul, avec `withFakeFetch` ; `calls` liste les requêtes envoyées (méthode, chemin, paramètres, corps).

`waitFor(condition)` attend qu'un élément de la page change. Lisez les tests existants avant d'écrire les vôtres : ils montrent chaque cas.

## Vérifier son travail avant de pousser

Avant chaque `git push`, on vérifie cinq choses, dans cet ordre.

1. **Le projet compile** : `swift build`, depuis `back/`.
2. **Les tests du back passent** : `swift test`, sans aucun échec une fois les anomalies corrigées.
3. **L'API répond comme prévu** : lancez-la avec `swift run` et essayez vos routes avec la page Swagger ou avec `curl`.
4. **Les tests du front passent** : `sh serve.sh` dans `front/`, puis `http://localhost:8080/tests/` : l'onglet doit indiquer `OK`. Faites aussi un essai à la main dans le front, avec les deux serveurs lancés.
5. **Le dépôt est propre** : `git status` et `git diff` ne montrent que les fichiers que vous avez voulu modifier.

Ensuite seulement : `git push`.

## Accès depuis un front web (CORS)

Un navigateur interdit à une page d'appeler une API située sur une autre origine (autre adresse ou autre port) tant que celle-ci ne l'autorise pas. Un front servi par un autre serveur, par exemple Apache sur `http://localhost:8080`, qui appelle l'API sur `http://localhost:8081`, est dans ce cas.

L'API est déjà configurée pour cela dans `configure.swift` : un `CORSMiddleware` autorise toutes les origines, les méthodes `GET`, `POST`, `PUT`, `DELETE` et `OPTIONS`, et les en-têtes `Accept`, `Content-Type` et `Origin`. Il est placé avant le gestionnaire d'erreurs, de sorte que les réponses d'erreur (400, 404, 409...) portent elles aussi ces en-têtes et que le front peut lire leur message.

Cette configuration large convient à un projet de formation lancé en local. Dans une application déployée, on limiterait `allowedOrigin` à l'adresse du front.

## Pile technique

- Vapor 4, `async`/`await`
- Fluent et FluentSQLiteDriver
- XCTest et XCTVapor
- Front : HTML, CSS et JavaScript (modules ES), sans dépendance
