
@testable import App
import XCTVapor

final class MemberTests: XCTestCase {

    // Vérifie qu'un adhérent peut être créé.
    func testCreateMemberReturnsCreated() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            try await app.test(.POST, "members", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(CreateMemberDTO(name: "Jaouad Assabbour", email: "jaouad@gmail.com"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
                XCTAssertEqual(try res.content.decode(MemberDTO.self).name, "Jaouad Assabbour")
            })
        }
    }

    // Vérifie qu'une adresse e-mail invalide est refusée.
    func testCreateMemberWithInvalidEmailIsRejected() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            try await app.test(.POST, "members", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(CreateMemberDTO(name: "José", email: "not-an-email"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    // Vérifie qu'une adresse e-mail déjà utilisée est refusée.
    func testCreateMemberWithDuplicateEmailReturnsConflict() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            _ = try await createMember(app, name: "Jaouad Assabbour", email: "jaouad@gmail.com")

            try await app.test(.POST, "members", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(CreateMemberDTO(name: "Amandine", email: "jaouad@gmail.com"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })
        }
    }

    // Vérifie qu'un adhérent inexistant renvoie 404.
    func testShowUnknownMemberReturnsNotFound() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            try await app.test(.GET, "members/\(UUID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    // FEAT-02 : Modifier un adhérent et vérifier l'enregistrement.
    func testUpdateMember() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            let member = try await createMember(app, name: "Jaouad", email: "jaouad@gmail.com")
            let id = try XCTUnwrap(member.id)
            try await app.test(.PUT, "members/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(
                    CreateMemberDTO(
                        name: "Jaouad Assabbour",
                        email: "jaouad.assabbour@gmail.com"
                    )
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let updated = try res.content.decode(MemberDTO.self)
                XCTAssertEqual(updated.name, "Jaouad Assabbour")
                XCTAssertEqual(updated.email, "jaouad.assabbour@gmail.com")
            })
            try await app.test(.GET, "members/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                let member = try res.content.decode(MemberDTO.self)
                XCTAssertEqual(member.name, "Jaouad Assabbour")
                XCTAssertEqual(member.email, "jaouad.assabbour@gmail.com")
            })
        }
    }

    // FEAT-02 : Refuser un e-mail déjà utilisé par un autre adhérent.
    func testUpdateMemberWithDuplicateEmailReturnsConflict() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            let first = try await createMember(app, name: "Jaouad Assabbour", email: "jaouad@gmail.com")
            _ = try await createMember(
                app,
                name: "José",
                email: "jose@gmail.com"
            )
            let id = try XCTUnwrap(first.id)
            try await app.test(.PUT, "members/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(
                    CreateMemberDTO(
                        name: "Jaouad Assabbour",
                        email: "jose@gmail.com"
                    )
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })
        }
    }

    // FEAT-02 : Supprimer un adhérent sans historique d'emprunts.
    func testDeleteMember() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            let member = try await createMember(app, name: "Amandine", email: "amandine@gmail.com")
            let id = try XCTUnwrap(member.id)
            try await app.test(.DELETE, "members/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .noContent)
            })
            try await app.test(.GET, "members/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    // FEAT-02 : Refuser la suppression d'un adhérent ayant des emprunts.
    func testDeleteMemberWithLoanHistoryReturnsConflict() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            let game = try await createGame(app)
            let member = try await createMember(app, name: "José", email: "jose@gmail.com")

            let gameID = try XCTUnwrap(game.id)
            let memberID = try XCTUnwrap(member.id)
            try await app.test(.POST, "loans", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(
                    CreateLoanDTO(gameID: gameID, memberID: memberID)
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })
            try await app.test(.DELETE, "members/\(memberID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })
            try await app.test(.GET, "members/\(memberID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
            })
        }
    }

    // FEAT-04 : Consulter les emprunts en cours et rendus d'un adhérent.
    func testGetMemberLoans() async throws {
        try await withApp { app in
            let token = try await getTestToken(app)
            let member = try await createMember(app, name: "Amandine", email: "amandine@gmail.com")
            let memberID = try XCTUnwrap(member.id)
            try await app.test(.GET, "members/\(memberID)/loans", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                XCTAssertTrue(try res.content.decode([LoanDTO].self).isEmpty)
            })
            let game = try await createGame(app)
            let gameID = try XCTUnwrap(game.id)
            var loanID: UUID?
            try await app.test(.POST, "loans", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(
                    CreateLoanDTO(gameID: gameID, memberID: memberID)
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
                loanID = try res.content.decode(LoanDTO.self).id
            })
            try await app.test(.GET, "members/\(memberID)/loans", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let loans = try res.content.decode([LoanDTO].self)
                XCTAssertEqual(loans.count, 1)
                XCTAssertEqual(loans.first?.memberID, memberID)
                XCTAssertNil(loans.first?.returnedAt)
            })
            let id = try XCTUnwrap(loanID)
            try await app.test(.POST, "loans/\(id)/return", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
            })
            try await app.test(.GET, "members/\(memberID)/loans", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let loans = try res.content.decode([LoanDTO].self)
                XCTAssertEqual(loans.count, 1)
                XCTAssertNotNil(loans.first?.returnedAt)
            })
        }
    }
}
