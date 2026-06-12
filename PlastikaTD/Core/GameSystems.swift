@MainActor
struct GameSystems {
    let gameStateManager: GameStateManager
    let pathManager: PathManager
    let waveManager: WaveManager
    let enemyManager: EnemyManager
    let buildSpotManager: BuildSpotManager
    let towerManager: TowerManager
    let projectileManager: ProjectileManager
    let economyManager: EconomyManager
    let baseHealthManager: BaseHealthManager
    let uiManager: UIManager
    let hapticsManager: HapticsManager

    init(gameStateManager: GameStateManager) {
        self.gameStateManager = gameStateManager
        self.pathManager = PathManager()
        self.waveManager = WaveManager()
        self.enemyManager = EnemyManager()
        self.buildSpotManager = BuildSpotManager()
        self.towerManager = TowerManager()
        self.projectileManager = ProjectileManager()
        self.economyManager = EconomyManager()
        self.baseHealthManager = BaseHealthManager()
        self.uiManager = UIManager()
        self.hapticsManager = HapticsManager()
    }
}
