import SpriteKit

final class GameScene: SKScene {
    static let sceneName = "GameScene"

    private let configuration: GameConfiguration
    private let systems: GameSystems
    private var didBuildScene = false
    private var debugPathNode: SKNode?
    /// Scene-coordinate Y of the bottom edge of the notch / Dynamic Island / status bar.
    /// Computed once from view.safeAreaInsets.top and reused on restart.
    private var safeAreaTopInScene: CGFloat = 0

    init(configuration: GameConfiguration, systems: GameSystems) {
        self.configuration = configuration
        self.systems = systems
        super.init(size: configuration.sceneSize)
        backgroundColor = SKColor(red: 0.07, green: 0.15, blue: 0.16, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("GameScene does not support storyboard initialization.")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        guard didBuildScene == false else {
            return
        }

        didBuildScene = true
        view.preferredFramesPerSecond = configuration.preferredFramesPerSecond
        // Camera at the scene's exact center, scale 1 — renders identically to having no
        // camera at all, but gives `shakeScreen` something to jolt for impact moments
        // (mortar detonations, base breaches).
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode
        // Convert the bottom of the notch/island/status bar from UIKit coords (top-left origin,
        // y increases downward) to scene coords (bottom-left origin, y increases upward).
        safeAreaTopInScene = convertPoint(fromView: CGPoint(x: 0, y: view.safeAreaInsets.top)).y
        resetPlaceholderSystems()
        buildPlaceholderScene()
        buildGameplaySlice()
        setupCallbacks()
        systems.uiManager.configureOverlay(in: self, safeAreaTop: safeAreaTopInScene)
        // The HUD wave badge is built above, after the wave already started (and fired its
        // initial onWaveProgressChanged before the callback was wired) — sync it explicitly.
        systems.uiManager.setWave(number: systems.waveManager.currentWaveNumber)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    private func resetPlaceholderSystems() {
        debugPathNode?.removeFromParent()
        debugPathNode = nil

        systems.pathManager.resetForNewScene()
        systems.waveManager.resetForNewScene()
        systems.enemyManager.resetForNewScene()
        systems.buildSpotManager.resetForNewScene()
        systems.towerManager.resetForNewScene()
        systems.projectileManager.resetForNewScene()
        systems.economyManager.resetForNewScene()
        systems.baseHealthManager.resetForNewScene()
        systems.uiManager.resetForNewScene()
    }

    private func buildPlaceholderScene() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Wooden tabletop under the grass mat — a visible wood margin all around frames the
        // battlefield as toys set up on a real table, per the game's tabletop presentation.
        let woodFrame = SKShapeNode(rectOf: CGSize(width: size.width * 0.94, height: size.height * 0.80), cornerRadius: 30)
        woodFrame.fillColor = SKColor(red: 0.43, green: 0.30, blue: 0.18, alpha: 1.0)
        woodFrame.strokeColor = SKColor(red: 0.27, green: 0.18, blue: 0.10, alpha: 1.0)
        woodFrame.lineWidth = 3
        woodFrame.position = center
        woodFrame.zPosition = -2
        addChild(woodFrame)

        // Faint horizontal grain lines across the wood (the middle is covered by the grass
        // mat, so these only show in the margins — a subtle plank texture, not a pattern).
        for fraction in [-0.36, -0.19, -0.02, 0.16, 0.34] as [CGFloat] {
            let grain = SKShapeNode(rectOf: CGSize(width: size.width * 0.90, height: 1.5), cornerRadius: 0.75)
            grain.fillColor = SKColor(white: 0.0, alpha: 0.16)
            grain.strokeColor = .clear
            grain.position = CGPoint(x: center.x, y: center.y + size.height * 0.80 * fraction)
            grain.zPosition = -1.5
            addChild(grain)
        }

        let table = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: size.height * 0.72), cornerRadius: 24)
        table.fillColor = SKColor(red: 0.23, green: 0.48, blue: 0.38, alpha: 1.0)
        table.strokeColor = SKColor(red: 0.86, green: 0.95, blue: 0.78, alpha: 1.0)
        table.lineWidth = 4
        table.position = center
        addChild(table)

        // Soft vignette over the grass — nested low-alpha dark strokes hugging the mat's
        // edge so the field reads as gently lit from above rather than a flat green fill.
        for (inset, alpha) in [(CGFloat(10), 0.09), (CGFloat(26), 0.05)] {
            let ring = SKShapeNode(
                rectOf: CGSize(width: size.width * 0.82 - inset * 2, height: size.height * 0.72 - inset * 2),
                cornerRadius: max(6, 24 - inset)
            )
            ring.fillColor = .clear
            ring.strokeColor = SKColor(white: 0.0, alpha: alpha)
            ring.lineWidth = inset * 1.6
            ring.position = center
            ring.zPosition = 0.5
            addChild(ring)
        }

        // Ambient cloud shadow — a soft dark blob drifting diagonally across the table on a
        // long loop. Barely-there (alpha 0.05), purely for a feeling of life and light.
        let cloud = SKShapeNode(ellipseOf: CGSize(width: 240, height: 140))
        cloud.fillColor = SKColor(white: 0.0, alpha: 0.05)
        cloud.strokeColor = .clear
        cloud.position = CGPoint(x: -160, y: size.height * 0.25)
        cloud.zPosition = 7  // above road (5) and scenery (6), below gameplay units (20)
        addChild(cloud)
        cloud.run(.repeatForever(.sequence([
            .move(to: CGPoint(x: size.width + 160, y: size.height * 0.75), duration: 32),
            .move(to: CGPoint(x: -160, y: size.height * 0.25), duration: 0),
            .wait(forDuration: 9)
        ])))

        // Static decorative scenery — toy trees, bushes, rocks, grass tufts, and the
        // spawn-camp / base-objective markers at the path ends. Purely cosmetic, built once,
        // and rendered below gameplay units. Added here (not in buildGameplaySlice) so it
        // persists across restarts like the table, since this method only runs once.
        let path = systems.pathManager.activePath
        addChild(SceneryFactory.makeScenery(
            start: path.startPoint ?? .zero,
            end: path.endPoint ?? .zero
        ))

        // Warm up AVAudioEngine and preload all audio files into SpriteKit's buffer cache.
        // SKAction.playSoundFileNamed starts the audio engine synchronously on first call,
        // causing a 5-10 second freeze. Adding SKAudioNode instances here forces that work
        // to happen at scene-build time (acceptable loading pause) instead of on first tap.
        preloadSounds()
    }

    private func playSound(_ filename: String) {
        guard systems.gameStateManager.isSoundEnabled else { return }
        run(SKAction.playSoundFileNamed(filename, waitForCompletion: false))
    }

    private func preloadSounds() {
        let files: [String] = [
            "tower_shoot_red.wav",
            "tower_shoot_green.wav",
            "tower_shoot_blue.wav",
            "enemy_hit.wav",
            "enemy_death.wav",
            "enemy_breach.wav",
            "tower_place.wav",
            "tower_sell.wav",
            "tower_beam_pink_start.wav"
        ]

        let container = SKNode()
        container.name = "SoundPreloadContainer"
        addChild(container)

        for filename in files {
            let node = SKAudioNode(fileNamed: filename)
            node.autoplayLooped = false  // do NOT play on add — load only
            node.isPositional = false
            container.addChild(node)
        }
    }

    private func buildGameplaySlice() {
        let pathNode = systems.pathManager.makeDebugPathNode()
        addChild(pathNode)
        debugPathNode = pathNode

        addChild(systems.buildSpotManager.makeBuildSpotLayer())

        systems.waveManager.beginWaveProgression(
            in: self,
            path: systems.pathManager.activePath,
            enemyManager: systems.enemyManager
        )
    }

    private func setupCallbacks() {
        systems.enemyManager.onEnemyReachedEnd = { [weak self] in
            self?.handleEnemyReachedEnd()
        }

        systems.gameStateManager.onResume = { [weak self] in
            self?.isPaused = false
        }

        systems.gameStateManager.onSoundEnabledChange = { [weak self] enabled in
            self?.systems.towerManager.isSoundEnabled = enabled
        }

        systems.waveManager.onWaveProgressChanged = { [weak self] waveNumber, countdown in
            self?.systems.uiManager.setWave(number: waveNumber, countdown: countdown)
        }

        // Apply persisted sound setting immediately
        systems.towerManager.isSoundEnabled = systems.gameStateManager.isSoundEnabled
    }

    private func handleEnemyReachedEnd() {
        guard systems.gameStateManager.state.phase == .sceneLoaded else {
            return
        }

        playSound("enemy_breach.wav")
        shakeScreen(intensity: 5, duration: 0.3)
        let isDestroyed = systems.baseHealthManager.takeDamage()

        // Force a HUD update immediately so the heart loss animation triggers now.
        // Without this, a health:0 loss never gets an update() call because
        // markGameOver() stops the update loop before the next frame.
        systems.uiManager.update(
            coins: systems.economyManager.coins,
            health: systems.baseHealthManager.health
        )

        if isDestroyed {
            triggerGameOver()
        }
    }

    private func triggerGameOver() {
        // Stop gameplay immediately so no further input or combat runs.
        systems.gameStateManager.markGameOver()
        // Delay the overlay so the last heart animation (0.31s) plays before it appears.
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.36),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.systems.uiManager.showGameOverOverlay(in: self)
            }
        ]))
    }

    private func triggerVictory() {
        systems.gameStateManager.markVictory()
        systems.uiManager.showVictoryOverlay(in: self)
    }

    private func restartGame() {
        resetPlaceholderSystems()
        buildGameplaySlice()
        setupCallbacks()
        systems.uiManager.configureOverlay(in: self, safeAreaTop: safeAreaTopInScene)
        systems.uiManager.setWave(number: systems.waveManager.currentWaveNumber)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        guard systems.gameStateManager.state.phase == .sceneLoaded else {
            return
        }

        systems.towerManager.updateCombat(
            currentTime: currentTime,
            enemyManager: systems.enemyManager,
            projectileManager: systems.projectileManager,
            economyManager: systems.economyManager,
            uiManager: systems.uiManager,
            pathEndPoint: systems.pathManager.activePath.endPoint ?? .zero,
            in: self
        )
        systems.uiManager.update(
            coins: systems.economyManager.coins,
            health: systems.baseHealthManager.health
        )

        let allWavesCleared = systems.waveManager.updateProgression(
            activeEnemyCount: systems.enemyManager.activeEnemyCount,
            in: self,
            path: systems.pathManager.activePath,
            enemyManager: systems.enemyManager
        )
        if allWavesCleared {
            triggerVictory()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        let phase = systems.gameStateManager.state.phase

        if phase == .paused { return }

        if phase == .gameOver || phase == .victory {
            if nodes(at: location).contains(where: { $0.name == "RestartButton" }) {
                restartGame()
            }
            return
        }

        if nodes(at: location).contains(where: { $0.name == "PauseButton" }),
           phase == .sceneLoaded {
            isPaused = true
            let stats = PauseStats(
                activeEnemies: systems.enemyManager.activeEnemyCount,
                spawnedEnemies: systems.waveManager.spawnedCount,
                totalEnemies: systems.waveManager.totalEnemyCount,
                killCount: systems.enemyManager.killCount,
                towerCounts: systems.towerManager.towerCountsByType,
                coinsInvested: systems.towerManager.totalCoinsInvested,
                waveNumber: systems.waveManager.currentWaveNumber,
                totalWaveCount: systems.waveManager.totalWaveCount
            )
            systems.gameStateManager.pause(stats: stats)
            return
        }

        if nodes(at: location).contains(where: { $0.name == "SellBadge" }) {
            if let sold = systems.towerManager.sellSelectedTower(in: self) {
                systems.economyManager.credit(sold.refund)
                systems.buildSpotManager.markUnoccupied(buildSpotID: sold.buildSpotID)
                systems.uiManager.update(
                    coins: systems.economyManager.coins,
                    health: systems.baseHealthManager.health
                )
                playSound("tower_sell.wav")
            }
            return
        }

        if nodes(at: location).contains(where: { $0.name == "UpgradeBadge" }) {
            if systems.towerManager.upgradeSelectedTower(economyManager: systems.economyManager, in: self) {
                systems.uiManager.update(
                    coins: systems.economyManager.coins,
                    health: systems.baseHealthManager.health
                )
                // Reuses the placement cue — both moments are "coins committed, tower
                // changed for the better", and adding a dedicated sample for this single
                // tap isn't worth the asset work yet (mirrors how Pink reuses Blue's
                // shoot sound for its unused `shootSound` slot).
                playSound("tower_place.wav")
            }
            return
        }

        if let menuSelection = systems.buildSpotManager.towerBuildMenuSelection(
            containing: location,
            coins: systems.economyManager.coins
        ) {
            let didPlaceTower = systems.towerManager.placePlaceholderTower(
                ofType: menuSelection.towerType,
                on: menuSelection.buildSpot,
                in: self
            )

            if didPlaceTower {
                systems.economyManager.spend(menuSelection.towerType.cost)
                systems.buildSpotManager.markOccupied(menuSelection.buildSpot)
                systems.buildSpotManager.hideBuildMenu()
                playSound("tower_place.wav")
            }

            return
        }

        if systems.towerManager.selectTower(containing: location, in: self) {
            systems.buildSpotManager.hideBuildMenu()
            return
        }

        if let buildSpot = systems.buildSpotManager.emptyBuildSpot(containing: location) {
            systems.towerManager.clearSelection()
            systems.buildSpotManager.showBuildMenu(for: buildSpot, coins: systems.economyManager.coins, in: self)
            return
        }

        systems.towerManager.clearSelection()
        systems.buildSpotManager.hideBuildMenu()
    }
}

extension SKScene {
    /// A brief screen shake for impact moments — jolts the camera through a few random
    /// offsets with linear falloff and lands it exactly back at the scene center (the
    /// camera's fixed resting position in this game). Re-triggering mid-shake replaces the
    /// running shake, so overlapping impacts can never leave the camera displaced. No-op
    /// when the scene has no camera.
    func shakeScreen(intensity: CGFloat, duration: TimeInterval) {
        guard let camera else { return }

        let resting = CGPoint(x: size.width / 2, y: size.height / 2)
        let stepDuration = 0.04
        let stepCount = max(2, Int(duration / stepDuration))

        camera.removeAction(forKey: "screenShake")

        var steps: [SKAction] = []
        for index in 0..<stepCount {
            let falloff = 1 - CGFloat(index) / CGFloat(stepCount)
            let jolt = CGPoint(
                x: resting.x + CGFloat.random(in: -intensity...intensity) * falloff,
                y: resting.y + CGFloat.random(in: -intensity...intensity) * falloff
            )
            steps.append(.move(to: jolt, duration: stepDuration))
        }
        steps.append(.move(to: resting, duration: stepDuration))

        camera.run(.sequence(steps), withKey: "screenShake")
    }
}
