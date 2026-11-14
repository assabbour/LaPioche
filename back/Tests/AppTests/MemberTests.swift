@testable import App
import XCTVapor

final class MemberTests: XCTestCase {
    func testCreateMemberReturnsCreated() async throws {
        try await withApp { app in
            try await app.test(.POST, "members", beforeRequest: { req in
                try req.content.encode(CreateMemberDTO(name: "Camille", email: "camille@example.com"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
                XCTAssertEqual(try res.content.decode(MemberDTO.self).name, "Camille")
            })
        }
    }

    func testCreateMemberWithInvalidEmailIsRejected() async throws {
        try await withApp { app in
            try await app.test(.POST, "members", beforeRequest: { req in
                try req.content.encode(CreateMemberDTO(name: "Camille", email: "not-an-email"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testCreateMemberWithDuplicateEmailReturnsConflict() async throws {
        try await withApp { app in
            _ = try await createMember(app)

            try await app.test(.POST, "members", beforeRequest: { req in
                try req.content.encode(CreateMemberDTO(name: "Autre", email: "camille@example.com"))
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })
        }
    }

    func testShowUnknownMemberReturnsNotFound() async throws {
        try await withApp { app in
            try await app.test(.GET, "members/\(UUID())", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
            })
        }
    }

    // FEAT-02 : Modifier un adhérent et vérifier l'enregistrement.
    func testUpdateMember() async throws {
        try await withApp { app in
            let member = try await createMember(app)
            let id = try XCTUnwrap(member.id)
            try await app.test(.PUT, "members/\(id)", beforeRequest: { req in
                try req.content.encode(
                    CreateMemberDTO(
                        name: "Camille Dupont",
                        email: "camille.dupont@example.com"
                    )
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let updated = try res.content.decode(MemberDTO.self)
                XCTAssertEqual(updated.name, "Camille Dupont")
                XCTAssertEqual(updated.email, "camille.dupont@example.com")
            })
            try await app.test(.GET, "members/\(id)", afterResponse: { res async throws in
                let member = try res.content.decode(MemberDTO.self)
                XCTAssertEqual(member.name, "Camille Dupont")
                XCTAssertEqual(member.email, "camille.dupont@example.com")
            })
        }
    }

    // FEAT-02 : Refuser un e-mail déjà utilisé par un autre adhérent.
    func testUpdateMemberWithDuplicateEmailReturnsConflict() async throws {
        try await withApp { app in
            let first = try await createMember(app)
            _ = try await createMember(
                app,
                name: "Alex",
                email: "alex@example.com"
            )
            let id = try XCTUnwrap(first.id)
            try await app.test(.PUT, "members/\(id)", beforeRequest: { req in
                try req.content.encode(
                    CreateMemberDTO(
                        name: "Camille",
                        email: "alex@example.com"
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
            let member = try await createMember(app)
            let id = try XCTUnwrap(member.id)
            try await app.test(.DELETE, "members/\(id)") { res async throws in
                XCTAssertEqual(res.status, .noContent)
            }
            try await app.test(.GET, "members/\(id)") { res async throws in
                XCTAssertEqual(res.status, .notFound)
            }
        }
    }

    // FEAT-02 : Refuser la suppression d'un adhérent ayant des emprunts.
    func testDeleteMemberWithLoanHistoryReturnsConflict() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let member = try await createMember(app)

            let gameID = try XCTUnwrap(game.id)
            let memberID = try XCTUnwrap(member.id)
            try await app.test(.POST, "loans", beforeRequest: { req in
                try req.content.encode(
                    CreateLoanDTO(gameID: gameID, memberID: memberID)
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })
            try await app.test(.DELETE, "members/\(memberID)") { res async throws in
                XCTAssertEqual(res.status, .conflict)
            }
            try await app.test(.GET, "members/\(memberID)") { res async throws in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }
}
