enum GamePhase: Equatable {
    case booting
    case sceneLoaded
    case paused
    case gameOver
    case victory
}

struct GameState: Equatable {
    var phase: GamePhase = .booting
    var activeSceneName: String?
}
