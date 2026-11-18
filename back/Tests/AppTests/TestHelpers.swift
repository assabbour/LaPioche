
@testable import App
import XCTVapor

// Initialise l'application pour les tests, puis ferme ses ressources.
func withApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

// Crée un jeu de test en utilisant un JWT valide.
func createGame(
    _ app: Application,
    title: String = "Catan",
    minPlayers: Int = 3,
    maxPlayers: Int = 4,
    durationMinutes: Int = 90
) async throws -> GameDTO {
    let token = try await getTestToken(app)
    var game: GameDTO?
    try await app.test(.POST, "games", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: token)
        try req.content.encode(CreateGameDTO(
            title: title,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            durationMinutes: durationMinutes
        ))
    }, afterResponse: { res async throws in
        game = try res.content.decode(GameDTO.self)
    })
    return try XCTUnwrap(game)
}

// Crée un adhérent de test en utilisant un JWT valide.
func createMember(
    _ app: Application,
    name: String = "Camille",
    email: String = "camille@example.com"
) async throws -> MemberDTO {
    let token = try await getTestToken(app)
    var member: MemberDTO?
    try await app.test(.POST, "members", beforeRequest: { req in
        req.headers.bearerAuthorization = .init(token: token)
        try req.content.encode(CreateMemberDTO(name: name, email: email))
    }, afterResponse: { res async throws in
        member = try res.content.decode(MemberDTO.self)
    })
    return try XCTUnwrap(member)
}

// The API cannot create a loan that is already late, so tests insert it directly.
func insertLoan(
    _ app: Application,
    gameID: UUID,
    memberID: UUID,
    borrowedAt: Date,
    dueAt: Date,
    returnedAt: Date? = nil
) async throws {
    let loan = Loan(gameID: gameID, memberID: memberID, borrowedAt: borrowedAt, dueAt: dueAt)
    loan.returnedAt = returnedAt
    try await loan.save(on: app.db)
}

// Inscrit un utilisateur de test et récupère son JWT pour authentifier les requêtes.
func getTestToken(_ app: Application) async throws -> String {
    var token: String?

    try await app.test(.POST, "auth/register", beforeRequest: { req in
        try req.content.encode(CredentialsDTO(
            email: "\(UUID().uuidString)@test.com",
            password: "TestPassword123"
        ))
    }, afterResponse: { res async throws in
        XCTAssertEqual(res.status, .created)
        let auth = try res.content.decode(AuthResponseDTO.self)
        token = auth.token
    })

    return try XCTUnwrap(token)
}
