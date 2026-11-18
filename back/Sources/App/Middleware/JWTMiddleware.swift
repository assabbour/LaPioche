import Vapor
import Fluent
import JWTKit

struct JWTMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Token manquant")
        }

        let payload: UserPayload

        do {
            payload = try await req.application.jwtKeys.verify(
                token,
                as: UserPayload.self
            )
        } catch {
            throw Abort(.unauthorized, reason: "Token invalide ou expiré")
        }

        guard let userID = UUID(uuidString: payload.subject.value),
              try await User.find(userID, on: req.db) != nil else {
            throw Abort(.unauthorized, reason: "Utilisateur introuvable")
        }

        return try await next.respond(to: req)
    }
}
