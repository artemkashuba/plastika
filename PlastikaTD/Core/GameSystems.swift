@MainActor
struct GameSystems {
    let gameStateManager: GameStateManager
    let pathManager: PathManager
    let waveManager: WaveManager
    let enemyManager: EnemyManager
    let towerManager: TowerManager
    let projectileManager: ProjectileManager
    let economyManager: EconomyManager
    let uiManager: UIManager

    init(gameStateManager: GameStateManager) {
        self.gameStateManager = gameStateManager
        self.pathManager = PathManager()
        self.waveManager = WaveManager()
        self.enemyManager = EnemyManager()
        self.towerManager = TowerManager()
        self.projectileManager = ProjectileManager()
        self.economyManager = EconomyManager()
        self.uiManager = UIManager()
    }
}
