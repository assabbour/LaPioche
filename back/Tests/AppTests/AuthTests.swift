@testable import App
import XCTVapor

final class AuthTests: XCTestCase {

    func testRegisterReturnsCreated() async throws {
        try await withApp { app in

            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in

                XCTAssertEqual(res.status, .created)

                let response = try res.content.decode(AuthResponseDTO.self)

                XCTAssertFalse(response.token.isEmpty)
                XCTAssertEqual(response.user.email, "staff@example.com")
                XCTAssertNotNil(response.user.id)
                XCTAssertGreaterThan(response.expiresAt, Date())
            })
        }
    }

    func testRegisterRejectsShortPassword() async throws {
        try await withApp { app in
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "test@example.com",
                    "password": "123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testRegisterRejectsInvalidEmail() async throws {
        try await withApp { app in
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "email-invalide",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            })
        }
    }

    func testRegisterRejectsDuplicateEmail() async throws {
        try await withApp { app in

            // Première inscription : acceptée
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "test@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })

            // Deuxième inscription : refusée
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "TEST@example.com",
                    "password": "password456"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            })
        }
    }

    func testLoginReturnsToken() async throws {
        try await withApp { app in

            // 1. Créer un utilisateur
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })

            // 2. Se connecter avec ce compte
            try await app.test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)

                let response = try res.content.decode(AuthResponseDTO.self)

                XCTAssertFalse(response.token.isEmpty)
                XCTAssertEqual(response.user.email, "staff@example.com")
            })
        }
    }

    func testLoginRejectsWrongPassword() async throws {
        try await withApp { app in

            // 1. Créer un utilisateur
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)
            })

            // 2. Essayer avec un mauvais mot de passe
            try await app.test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "mauvais123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            })
        }
    }

    func testLoginRejectsUnknownEmail() async throws {
        try await withApp { app in
            try await app.test(.POST, "auth/login", beforeRequest: { req in
                try req.content.encode([
                    "email": "inconnu@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            })
        }
    }

    func testMeRejectsMissingToken() async throws {
        try await withApp { app in
            try await app.test(.GET, "auth/me", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            })
        }
    }

    func testMeReturnsAuthenticatedUser() async throws {
        try await withApp { app in
            var token = ""

            // 1. Inscrire un utilisateur et récupérer son JWT
            try await app.test(.POST, "auth/register", beforeRequest: { req in
                try req.content.encode([
                    "email": "staff@example.com",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .created)

                let response = try res.content.decode(AuthResponseDTO.self)
                token = response.token
            })

            // 2. Envoyer le JWT dans Authorization
            try await app.test(.GET, "auth/me", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)

                let user = try res.content.decode(UserDTO.self)
                XCTAssertEqual(user.email, "staff@example.com")
            })
        }
    }

    func testMeRejectsInvalidToken() async throws {
        try await withApp { app in
            try await app.test(.GET, "auth/me", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(
                    token: "token-invalide"
                )
            }, afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            })
        }
    }

    func testGamesRejectsMissingToken() async throws {
        try await withApp { app in
            try await app.test(.GET, "games", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            })
        }
    }

}