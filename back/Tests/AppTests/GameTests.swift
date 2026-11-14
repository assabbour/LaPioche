@testable import App
import XCTVapor

final class GameTests: XCTestCase {
    func testCreateGameReturnsCreated() async throws {
        try await withApp { app in
            try await app.test(.POST, "games", beforeRequest: { req in
                try req.content.encode(CreateGameDTO(
                    title: "Catan", minPlayers: 3, maxPlayers: 4, durationMinutes: 90
                ))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
                let game = try res.content.decode(GameDTO.self)
                XCTAssertEqual(game.title, "Catan")
                XCTAssertTrue(game.isAvailable)
            })
        }
    }

    func testCreateGameWithEmptyTitleIsRejected() async throws {
        try await withApp { app in
            try await app.test(.POST, "games", beforeRequest: { req in
                try req.content.encode(CreateGameDTO(
                    title: "", minPlayers: 3, maxPlayers: 4, durationMinutes: 90
                ))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testCreateGameWithInvertedPlayerBoundsIsRejected() async throws {
        try await withApp { app in
            try await app.test(.POST, "games", beforeRequest: { req in
                try req.content.encode(CreateGameDTO(
                    title: "Catan", minPlayers: 5, maxPlayers: 2, durationMinutes: 90
                ))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testListGames() async throws {
        try await withApp { app in
            _ = try await createGame(app, title: "Catan")
            _ = try await createGame(app, title: "Dixit")

            try await app.test(.GET, "games", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(try res.content.decode([GameDTO].self).count, 2)
            })
        }
    }

    func testShowGame() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let id = try XCTUnwrap(game.id)

            try await app.test(.GET, "games/\(id)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(try res.content.decode(GameDTO.self).id, id)
            })
        }
    }

    func testShowUnknownGameReturnsNotFound() async throws {
        try await withApp { app in
            try await app.test(.GET, "games/\(UUID())", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    func testShowGameWithMalformedIDReturnsBadRequest() async throws {
        try await withApp { app in
            try await app.test(.GET, "games/not-a-uuid", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testPreflightRequestFromAnotherOriginIsAllowed() async throws {
        try await withApp { app in
            try await app.test(.OPTIONS, "games", beforeRequest: { req in
                req.headers.replaceOrAdd(name: .origin, value: "http://localhost:8080")
                req.headers.replaceOrAdd(name: .accessControlRequestMethod, value: "POST")
                req.headers.replaceOrAdd(name: .accessControlRequestHeaders, value: "content-type")
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
                XCTAssertTrue(res.headers[.accessControlAllowMethods].joined(separator: ",").contains("POST"))
            })
        }
    }

    func testErrorResponsesCarryTheCorsHeaders() async throws {
        try await withApp { app in
            try await app.test(.GET, "games/not-a-uuid", beforeRequest: { req in
                req.headers.replaceOrAdd(name: .origin, value: "http://localhost:8080")
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
            })
        }
    }

    // FEAT-01 : Vérifier qu'un jeu peut être modifié.
    func testUpdateGame() async throws {
        try await withApp { app in

            let game = try await createGame(app, title: "Catan")
            let id = try XCTUnwrap(game.id)

            try await app.test(.PUT, "games/\(id)", beforeRequest: { req in
                try req.content.encode(CreateGameDTO(
                    title: "Catan Nouvelle Édition",
                    minPlayers: 2,
                    maxPlayers: 6,
                    durationMinutes: 120
                ))
            }, afterResponse: { res async throws in

                XCTAssertEqual(res.status, .ok)

                let updatedGame = try res.content.decode(GameDTO.self)
                XCTAssertEqual(updatedGame.id, id)
                XCTAssertEqual(updatedGame.title, "Catan Nouvelle Édition")
                XCTAssertEqual(updatedGame.minPlayers, 2)
                XCTAssertEqual(updatedGame.maxPlayers, 6)
                XCTAssertEqual(updatedGame.durationMinutes, 120)
            })

            try await app.test(.GET, "games/\(id)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)

                let savedGame = try res.content.decode(GameDTO.self)
                XCTAssertEqual(savedGame.title, "Catan Nouvelle Édition")
                XCTAssertEqual(savedGame.maxPlayers, 6)
            })
        }
    }

    // FEAT-01 : Retourner HTTP 404 si le jeu à modifier n'existe pas.
    func testUpdateUnknownGameReturnsNotFound() async throws {
        try await withApp { app in
            try await app.test(.PUT, "games/\(UUID())", beforeRequest: { req in
                try req.content.encode(CreateGameDTO(
                    title: "Catan",
                    minPlayers: 2,
                    maxPlayers: 4,
                    durationMinutes: 90
                ))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    // FEAT-01 : Vérifier qu'un jeu peut être supprimé.
    func testDeleteGame() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let id = try XCTUnwrap(game.id)

            try await app.test(.DELETE, "games/\(id)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .noContent)
            })

            try await app.test(.GET, "games/\(id)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    func testDeleteUnknownGameReturnsNotFound() async throws {
        try await withApp { app in
            try await app.test(.DELETE, "games/\(UUID())", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    // FEAT-01 : Empêcher la suppression d'un jeu ayant un historique d'emprunts.
    func testDeleteGameWithLoanHistoryReturnsConflict() async throws {
        try await withApp { app in

            let game = try await createGame(app)
            let member = try await createMember(app)
            let gameID = try XCTUnwrap(game.id)
            let memberID = try XCTUnwrap(member.id)

            try await app.test(.POST, "loans", beforeRequest: { req in
                try req.content.encode(CreateLoanDTO(
                    gameID: gameID,
                    memberID: memberID
                ))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })

            try await app.test(.DELETE, "games/\(gameID)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })

            try await app.test(.GET, "games/\(gameID)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
            })
        }
    }

    // FEAT-06 : Rechercher un jeu avec une partie de son titre.
    func testSearchGamesByTitle() async throws {
        try await withApp { app in
            _ = try await createGame(app, title: "Les Aventuriers du Rail")
            _ = try await createGame(app, title: "Catan")
            _ = try await createGame(app, title: "Dixit")
            try await app.test(.GET, "games?search=Aventuriers", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let games = try res.content.decode([GameDTO].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games.first?.title, "Les Aventuriers du Rail")
            })
        }
    }

    // FEAT-06 : Une recherche sans correspondance retourne une liste vide.
    func testSearchGamesWithoutResults() async throws {
        try await withApp { app in
            _ = try await createGame(app, title: "Catan")
            try await app.test(.GET, "games?search=Monopoly", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let games = try res.content.decode([GameDTO].self)
                XCTAssertTrue(games.isEmpty)
            })
        }
    }

    // FEAT-06 : Sans recherche, tous les jeux restent accessibles.
    func testSearchGamesWithoutFilter() async throws {
        try await withApp { app in
            _ = try await createGame(app, title: "Catan")
            _ = try await createGame(app, title: "Dixit")
            try await app.test(.GET, "games", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let games = try res.content.decode([GameDTO].self)
                XCTAssertEqual(games.count, 2)
            })
        }
    }

}
