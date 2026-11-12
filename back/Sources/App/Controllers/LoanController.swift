import Fluent
import Vapor

struct LoanController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let loans = routes.grouped("loans")
        loans.post(use: create)
        // BUG-06 : Ajouter la route permettant de rendre un jeu emprunté.
        loans.post(":loanID", "return", use: returnGame)
        // BUG-07 : Consulter l'historique des emprunts.
        loans.get(use: index)
    }

    // BUG-07 : Récupérer tous les emprunts, du plus récent au plus ancien.
    @Sendable
    func index(req: Request) async throws -> [LoanDTO] {
        let loans = try await Loan.query(on: req.db)
            .sort(\.$borrowedAt, .descending)
            .all()

        return loans.map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        let dto = try req.content.decode(CreateLoanDTO.self)

        guard let game = try await Game.find(dto.gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        guard let member = try await Member.find(dto.memberID, on: req.db) else {
            throw Abort(.notFound, reason: "Member not found")
        }

        // BUG-03 : Empêcher un nouvel emprunt si le jeu est déjà emprunté.
        let activeLoan = try await Loan.query(on: req.db)
            .filter(\.$game.$id == dto.gameID)
            .filter(\.$returnedAt == nil)
            .first()

        guard activeLoan == nil else {
            throw Abort(.conflict, reason: "Game already on loan")
        }

        let now = Date()
        let loan = Loan(
            gameID: try game.requireID(),
            memberID: try member.requireID(),
            borrowedAt: now,
            dueAt: try Loan.dueDate(from: now)
        )
        try await loan.save(on: req.db)
        return try await loan.toDTO().encodeResponse(status: .created, for: req)
    }
    // BUG-06 : Enregistrer le retour d'un jeu et le rendre disponible.
    @Sendable
    func returnGame(req: Request) async throws -> LoanDTO {
        guard let loanID = req.parameters.get("loanID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid loan id")
        }
        guard let loan = try await Loan.find(loanID, on: req.db) else {
            throw Abort(.notFound, reason: "Loan not found")
        }
        guard loan.returnedAt == nil else {
            throw Abort(.conflict, reason: "Loan is already returned")
        }
        loan.returnedAt = Date()
        try await loan.save(on: req.db)
        return loan.toDTO()
    }
}
