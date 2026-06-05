enum GamePhase: Equatable {
    case booting
    case sceneLoaded
    case paused
}

struct GameState: Equatable {
    var phase: GamePhase = .booting
    var activeSceneName: String?
}
