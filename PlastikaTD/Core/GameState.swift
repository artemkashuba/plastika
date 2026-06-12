enum GamePhase: Equatable {
    case booting
    /// Scene is built and visible as a backdrop, but gameplay hasn't started — the SwiftUI
    /// main menu is showing. Waves begin (and the phase moves to `.sceneLoaded`) when the
    /// player taps PLAY.
    case mainMenu
    case sceneLoaded
    case paused
    case gameOver
    case victory
}

struct GameState: Equatable {
    var phase: GamePhase = .booting
    var activeSceneName: String?
}
