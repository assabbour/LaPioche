import Vapor
import Fluent
import JWTKit

struct AuthController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.get("me", use: me)
    }

    func register(req: Request) async throws -> Response {
        let credentials = try req.content.decode(CredentialsDTO.self)

        let email = credentials.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard email.contains("@"),
            let domain = email.split(separator: "@").last,
            domain.contains("."),
            credentials.password.count >= 8 else {
            throw Abort(.badRequest, reason: "Email ou mot de passe invalide")
        }

        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first()

        guard existingUser == nil else {
            throw Abort(.conflict, reason: "Cet email est déjà utilisé")
        }

        let passwordHash = try await req.password.async.hash(credentials.password)

        let user = User(email: email, passwordHash: passwordHash)
        try await user.save(on: req.db)

        let userID = try user.requireID()
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60)

        let payload = UserPayload(
            subject: .init(value: userID.uuidString),
            expiration: .init(value: expiresAt)
        )

        let token = try await req.application.jwtKeys.sign(payload)

        let result = AuthResponseDTO(
            token: token,
            expiresAt: expiresAt,
            user: UserDTO(id: userID, email: user.email)
        )

        let response = Response(status: .created)
        try response.content.encode(result)
        return response
    }
    
    func login(req: Request) async throws -> Response {
        let credentials = try req.content.decode(CredentialsDTO.self)

        let email = credentials.email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 1. Rechercher l'utilisateur
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first() else {
            throw Abort(.unauthorized, reason: "Identifiants invalides")
        }

        // 2. Vérifier le mot de passe avec bcrypt
        let validPassword = try await req.password.async.verify(
            credentials.password,
            created: user.passwordHash
        )

        guard validPassword else {
            throw Abort(.unauthorized, reason: "Identifiants invalides")
        }

        // 3. Générer un JWT valable 24 heures
        let userID = try user.requireID()
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60)

        let payload = UserPayload(
            subject: .init(value: userID.uuidString),
            expiration: .init(value: expiresAt)
        )

        let token = try await req.application.jwtKeys.sign(payload)

        // 4. Retourner la réponse HTTP 200
        let result = AuthResponseDTO(
            token: token,
            expiresAt: expiresAt,
            user: UserDTO(id: userID, email: user.email)
        )

        let response = Response(status: .ok)
        try response.content.encode(result)
        return response
    }

    func me(req: Request) async throws -> UserDTO {

        // 1. Récupérer le token Bearer
        guard let token = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Token manquant")
        }

        // 2. Vérifier la signature et l'expiration du JWT
        let payload: UserPayload

        do {
            payload = try await req.application.jwtKeys.verify(
                token,
                as: UserPayload.self
            )
        } catch {
            throw Abort(.unauthorized, reason: "Token invalide ou expiré")
        }

        // 3. Récupérer l'identifiant utilisateur
        guard let userID = UUID(uuidString: payload.subject.value),
            let user = try await User.find(userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Utilisateur introuvable")
        }

        // 4. Retourner les informations de l'utilisateur
        return UserDTO(
            id: userID,
            email: user.email
        )
    }

}