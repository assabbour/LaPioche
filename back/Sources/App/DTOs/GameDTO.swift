import Vapor

struct GameDTO: Content {
    let id: UUID?
    let title: String
    let minPlayers: Int
    let maxPlayers: Int
    let durationMinutes: Int
    let isAvailable: Bool
    // Identifiant de l'emprunt actif pour permettre le retour du jeu.
    let activeLoanID: UUID?
}

extension Game {
    func toDTO() -> GameDTO {
        GameDTO(
            id: id,
            title: title,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            durationMinutes: durationMinutes,
            isAvailable: isAvailable,
            // BUG-06 : Transmettre l'ID de l'emprunt non rendu au frontend.
            activeLoanID: $loans.value?.first(where: { $0.returnedAt == nil })?.id
        )
    }
}
