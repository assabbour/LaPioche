import Vapor

struct CredentialsDTO: Content {
    let email: String
    let password: String
}

struct UserDTO: Content {
    let id: UUID
    let email: String
}

struct AuthResponseDTO: Content {
    let token: String
    let expiresAt: Date
    let user: UserDTO
}