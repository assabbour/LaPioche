import Fluent
import Vapor

struct GameController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let games = routes.grouped("games")
        games.get(use: index)
        games.post(use: create)
        games.get(":gameID", use: show)
        // FEAT-01 : Modifier un jeu existant.
        games.put(":gameID", use: update)
        // FEAT-01 : Supprimer un jeu existant.
        games.delete(":gameID", use: delete)
    }

    // FEAT-06 : Rechercher un jeu par son titre.
    @Sendable
    func index(req: Request) async throws -> [GameDTO] {
        let search = try req.query.get(String?.self, at: "search")

        var query = Game.query(on: req.db)
            .with(\.$loans)

        if let search, !search.isEmpty {
            query = query.filter(\.$title ~~ "%\(search)%")
        }

        let games = try await query.all()
        return games.map { $0.toDTO() }
    }

    // BUG-01 : Retourner HTTP 201 Created au lieu de 200 OK après la création d'un jeu.
    @Sendable
    func create(req: Request) async throws -> Response {
        try CreateGameDTO.validate(content: req)
        let dto = try req.content.decode(CreateGameDTO.self)
        try dto.ensureConsistentPlayerCount()

        let game = dto.toModel()
        try await game.save(on: req.db)

        let response = try await game.toDTO().encodeResponse(for: req)
        response.status = .created
        return response
    }

    @Sendable
    func show(req: Request) async throws -> GameDTO {
        try await findGame(req).toDTO()
    }

    // FEAT-01 : Modifier les informations d'un jeu existant.
    @Sendable
    func update(req: Request) async throws -> GameDTO {
        try CreateGameDTO.validate(content: req)
        let dto = try req.content.decode(CreateGameDTO.self)
        try dto.ensureConsistentPlayerCount()
        let game = try await findGame(req)
        game.title = dto.title
        game.minPlayers = dto.minPlayers
        game.maxPlayers = dto.maxPlayers
        game.durationMinutes = dto.durationMinutes
        try await game.save(on: req.db)
        return game.toDTO()
    }

    // FEAT-01 : Supprimer un jeu sans historique d'emprunts.
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let game = try await findGame(req)
        guard game.loans.isEmpty else {
            throw Abort(.conflict, reason: "Game has loan history")
        }
        try await game.delete(on: req.db)
        return .noContent
    }

    private func findGame(_ req: Request) async throws -> Game {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game id")
        }
        guard let game = try await Game.query(on: req.db)
            .filter(\.$id == gameID)
            .with(\.$loans)
            .first()
        else {
            // BUG-04 : Retourner HTTP 404 si le jeu n'existe pas.
            throw Abort(.notFound, reason: "Game not found")
        }
        return game
    }
}
