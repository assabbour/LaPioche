import Fluent
import FluentSQLiteDriver
import Vapor
import JWTKit

struct JWTKeysStorageKey: StorageKey {
    typealias Value = JWTKeyCollection
}

extension Application {
    var jwtKeys: JWTKeyCollection {
        get {
            guard let keys = storage[JWTKeysStorageKey.self] else {
                fatalError("JWT keys not configured")
            }
            return keys
        }
        set {
            storage[JWTKeysStorageKey.self] = newValue
        }
    }
}

func configure(_ app: Application) async throws {
    app.http.server.configuration.port = 8081

    let cors = CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .contentType, .origin, .authorization]
    ))
    // CORS must wrap the error middleware so that error responses carry its headers too.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory, defaultFile: "index.html"))

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateGame())
    app.migrations.add(CreateMember())
    app.migrations.add(CreateLoan())
    try await app.autoMigrate()

    guard let secret = Environment.get("JWT_SECRET"),
      secret.utf8.count >= 32 else {
        throw Abort(
            .internalServerError,
            reason: "JWT_SECRET doit contenir au moins 32 octets."
        )
    }

    let jwtKeys = JWTKeyCollection()
    await jwtKeys.add(
        hmac: HMACKey(from: secret),
        digestAlgorithm: .sha256
    )
    app.jwtKeys = jwtKeys

    try routes(app)
}
