@testable import App
import XCTVapor

final class LoanTests: XCTestCase {
    private func borrow(
        _ app: Application,
        gameID: UUID,
        memberID: UUID,
        afterResponse: (XCTHTTPResponse) async throws -> Void
    ) async throws {
        try await app.test(.POST, "loans", beforeRequest: { req in
            try req.content.encode(CreateLoanDTO(gameID: gameID, memberID: memberID))
        }, afterResponse: afterResponse)
    }

    func testBorrowGameReturnsCreated() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let member = try await createMember(app)

            try await borrow(
                app, gameID: try XCTUnwrap(game.id), memberID: try XCTUnwrap(member.id)
            ) { res in
                XCTAssertEqual(res.status, .created)
                let loan = try res.content.decode(LoanDTO.self)
                XCTAssertEqual(loan.gameID, game.id)
                XCTAssertEqual(loan.memberID, member.id)
                XCTAssertNil(loan.returnedAt)
            }
        }
    }

    func testDueDateIsFourteenDaysAfterBorrowDate() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let member = try await createMember(app)

            try await borrow(
                app, gameID: try XCTUnwrap(game.id), memberID: try XCTUnwrap(member.id)
            ) { res in
                let loan = try res.content.decode(LoanDTO.self)
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let days = calendar.dateComponents([.day], from: loan.borrowedAt, to: loan.dueAt).day
                XCTAssertEqual(days, 14)
            }
        }
    }

    func testBorrowedGameIsNoLongerAvailable() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let member = try await createMember(app)
            let gameID = try XCTUnwrap(game.id)

            try await borrow(app, gameID: gameID, memberID: try XCTUnwrap(member.id)) { _ in }

            try await app.test(.GET, "games/\(gameID)", afterResponse: { res async throws in
                XCTAssertFalse(try res.content.decode(GameDTO.self).isAvailable)
            })
        }
    }

    func testBorrowingAGameAlreadyOnLoanReturnsConflict() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let first = try await createMember(app, email: "first@example.com")
            let second = try await createMember(app, name: "Alex", email: "second@example.com")
            let gameID = try XCTUnwrap(game.id)

            try await borrow(app, gameID: gameID, memberID: try XCTUnwrap(first.id)) { _ in }
            try await borrow(app, gameID: gameID, memberID: try XCTUnwrap(second.id)) { res in
                XCTAssertEqual(res.status, .conflict)
            }
        }
    }

    func testBorrowUnknownGameReturnsNotFound() async throws {
        try await withApp { app in
            let member = try await createMember(app)

            try await borrow(app, gameID: UUID(), memberID: try XCTUnwrap(member.id)) { res in
                XCTAssertEqual(res.status, .notFound)
            }
        }
    }

    func testBorrowWithUnknownMemberReturnsNotFound() async throws {
        try await withApp { app in
            let game = try await createGame(app)

            try await borrow(app, gameID: try XCTUnwrap(game.id), memberID: UUID()) { res in
                XCTAssertEqual(res.status, .notFound)
            }
        }
    }

    // FEAT-03 : Vérifier qu'un jeu redevient disponible après son retour.
    func testReturnedGameBecomesAvailable() async throws {
        try await withApp { app in
            let game = try await createGame(app)
            let member = try await createMember(app)
            let gameID = try XCTUnwrap(game.id)

            var loanID: UUID?

            try await borrow(
                app,
                gameID: gameID,
                memberID: try XCTUnwrap(member.id)
            ) { res in
                let loan = try res.content.decode(LoanDTO.self)
                loanID = loan.id
            }

            let id = try XCTUnwrap(loanID)

            try await app.test(.POST, "loans/\(id)/return") { res async throws in
                XCTAssertEqual(res.status, .ok)
                let loan = try res.content.decode(LoanDTO.self)
                XCTAssertNotNil(loan.returnedAt)
            }

            try await app.test(.GET, "games/\(gameID)") { res async throws in
                let game = try res.content.decode(GameDTO.self)
                XCTAssertTrue(game.isAvailable)
                XCTAssertNil(game.activeLoanID)
            }
        }
    }

    // EXTRA-01 : Vérifier que l'historique contient les emprunts du plus récent au plus ancien.
    func testLoanHistoryReturnsNewestFirst() async throws {
        try await withApp { app in
            let game1 = try await createGame(app)
            let game2 = try await createGame(app)
            let member = try await createMember(app)

            let gameID1 = try XCTUnwrap(game1.id)
            let gameID2 = try XCTUnwrap(game2.id)
            let memberID = try XCTUnwrap(member.id)

            try await borrow(app, gameID: gameID1, memberID: memberID) { _ in }
            try await borrow(app, gameID: gameID2, memberID: memberID) { _ in }

            let loans = try await Loan.query(on: app.db).all()

            for loan in loans {
                loan.borrowedAt = loan.$game.id == gameID1
                    ? Date(timeIntervalSince1970: 1_700_000_000)
                    : Date(timeIntervalSince1970: 1_700_086_400)

                try await loan.save(on: app.db)
            }

            try await app.test(.GET, "loans") { res async throws in
                XCTAssertEqual(res.status, .ok)

                let history = try res.content.decode([LoanDTO].self)

                XCTAssertEqual(history.count, 2)
                XCTAssertEqual(history[0].gameID, gameID2)
                XCTAssertEqual(history[1].gameID, gameID1)
            }
        }
    }
}
