import Vapor

func routes(_ app: Application) throws {
    // Routes publiques
    try app.register(collection: AuthController())

    // Routes protégées par JWT
    let protected = app.grouped(JWTMiddleware())

    try protected.register(collection: GameController())
    try protected.register(collection: MemberController())
    try protected.register(collection: LoanController())
}
