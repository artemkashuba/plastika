import SpriteKit

@MainActor
final class UIManager {
    // MARK: - HUD

    private var hudNode: SKNode?
    private var coinLabel: SKLabelNode?
    /// The coin icon in the HUD cluster — landing target for the kill-reward fly animation.
    private var coinIconNode: SKShapeNode?
    private var heartNodes: [SKLabelNode] = []
    /// The wave-badge label — updated on demand via `setWave` (wave start / countdown ticks),
    /// not every frame, since it only changes on discrete progression events.
    private var waveLabel: SKLabelNode?
    /// Tracks the last known health value so updateHearts can detect a loss and animate it.
    private var currentHealth = BaseHealthManager.startingHealth

    // MARK: - End overlay

    private var endOverlayNode: SKNode?

    // MARK: - Lifecycle

    func resetForNewScene() {
        hudNode?.removeFromParent()
        hudNode = nil
        endOverlayNode?.removeFromParent()
        endOverlayNode = nil
        coinLabel = nil
        coinIconNode = nil
        waveLabel = nil
        heartNodes = []
        currentHealth = BaseHealthManager.startingHealth
    }

    /// `safeAreaTop` is the scene-coordinate Y of the bottom edge of the notch / Dynamic Island /
    /// status bar, as computed by `GameScene` via `convertPoint(fromView:)`. The HUD bar is placed
    /// immediately below this boundary so it renders correctly on all device variants.
    func configureOverlay(in scene: SKScene, safeAreaTop: CGFloat) {
        resetForNewScene()
        buildHUD(in: scene, safeAreaTop: safeAreaTop)
    }

    func update(coins: Int, health: Int) {
        coinLabel?.text = "\(coins)"
        updateHearts(health: health)
    }

    /// Updates the HUD wave badge. Called only on discrete progression events (a wave
    /// starting, or each inter-wave countdown tick) — not every frame — since the text
    /// only ever changes at those moments. `countdown` non-nil shows "WAVE N IN S";
    /// nil shows the plain "WAVE N" state.
    func setWave(number: Int, countdown: Int? = nil) {
        guard let waveLabel else {
            return
        }

        if let countdown {
            waveLabel.text = "WAVE \(number) IN \(countdown)"
            waveLabel.fontSize = 10
        } else {
            waveLabel.text = "WAVE \(number)"
            waveLabel.fontSize = 12
        }
    }

    // MARK: - Coin reward animation

    /// Spawns a small coin at `startPosition` (typically an enemy's death spot), arcs it toward
    /// the HUD coin counter, and pulses the counter when it lands. Purely cosmetic feedback —
    /// the actual credit is applied immediately by EconomyManager regardless of this animation.
    func flyCoinReward(from startPosition: CGPoint, in scene: SKScene) {
        guard let targetPosition = coinTargetPosition(in: scene) else {
            return
        }

        let coin = makeFlyingCoinNode()
        coin.position = startPosition
        scene.addChild(coin)

        // Gentle upward arc between the two points — reads as a little "hop" toward the HUD.
        let midX = (startPosition.x + targetPosition.x) / 2
        let arcHeight: CGFloat = 70
        let controlPoint = CGPoint(x: midX, y: max(startPosition.y, targetPosition.y) + arcHeight)

        let path = CGMutablePath()
        path.move(to: startPosition)
        path.addQuadCurve(to: targetPosition, control: controlPoint)

        let duration: TimeInterval = 0.5
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeIn
        let shrink = SKAction.scale(to: 0.45, duration: duration)
        shrink.timingMode = .easeIn

        coin.run(SKAction.sequence([
            SKAction.group([follow, shrink]),
            SKAction.run { [weak self] in self?.pulseCoinLabel() },
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent()
        ]))
    }

    /// Scene-space position of the HUD coin icon — the landing point for fly animations.
    private func coinTargetPosition(in scene: SKScene) -> CGPoint? {
        guard let coinIconNode else {
            return nil
        }

        return scene.convert(.zero, from: coinIconNode)
    }

    private func makeFlyingCoinNode() -> SKNode {
        let coin = SKNode()
        coin.zPosition = 45 // above the HUD bar (40) so it visibly "lands" on the counter

        let glow = SKShapeNode(circleOfRadius: 12)
        glow.fillColor = SKColor(red: 0.98, green: 0.80, blue: 0.12, alpha: 0.22)
        glow.strokeColor = .clear
        glow.zPosition = -1
        coin.addChild(glow)

        let icon = SKShapeNode(circleOfRadius: 7)
        icon.fillColor = SKColor(red: 0.98, green: 0.80, blue: 0.12, alpha: 1.0)
        icon.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 1.0)
        icon.lineWidth = 1.4
        coin.addChild(icon)

        let innerRing = SKShapeNode(circleOfRadius: 3.5)
        innerRing.fillColor = .clear
        innerRing.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 0.55)
        innerRing.lineWidth = 1
        coin.addChild(innerRing)

        return coin
    }

    private func pulseCoinLabel() {
        guard let coinLabel else {
            return
        }

        coinLabel.removeAction(forKey: "coinPulse")
        let scaleUp = SKAction.scale(to: 1.32, duration: 0.07)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.20)
        scaleDown.timingMode = .easeOut
        coinLabel.run(SKAction.sequence([scaleUp, scaleDown]), withKey: "coinPulse")
    }

    // MARK: - End overlays

    func showGameOverOverlay(in scene: SKScene) {
        showEndOverlay(
            title: "DEFEAT",
            titleColor: SKColor(red: 0.94, green: 0.25, blue: 0.20, alpha: 1.0),
            subtitle: "Your base was overrun.",
            in: scene
        )
    }

    func showVictoryOverlay(in scene: SKScene) {
        showEndOverlay(
            title: "VICTORY",
            titleColor: SKColor(red: 0.98, green: 0.82, blue: 0.18, alpha: 1.0),
            subtitle: "All enemies defeated!",
            in: scene
        )
    }

    func hideEndOverlay() {
        endOverlayNode?.removeFromParent()
        endOverlayNode = nil
    }

    // MARK: - HUD construction

    private func buildHUD(in scene: SKScene, safeAreaTop: CGFloat) {
        let width = scene.size.width
        let barHeight: CGFloat = 52
        // Place the bar's top edge flush with the safe area boundary so it sits just below
        // the notch / Dynamic Island / status bar on every device variant.
        let barCenterY = safeAreaTop - barHeight / 2

        let root = SKNode()
        root.name = "HUD"
        root.zPosition = 40

        // Background bar
        let bar = SKShapeNode(rectOf: CGSize(width: width, height: barHeight))
        bar.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.12, alpha: 0.82)
        bar.strokeColor = SKColor(white: 1.0, alpha: 0.10)
        bar.lineWidth = 1
        bar.position = CGPoint(x: width / 2, y: barCenterY)
        root.addChild(bar)

        // -- Coin cluster (left) --
        let coinCluster = buildCoinCluster(coins: 150)
        coinCluster.position = CGPoint(x: 20, y: barCenterY)
        root.addChild(coinCluster)

        // -- Wave badge (center) --
        let waveBadge = buildWaveBadge()
        waveBadge.position = CGPoint(x: width / 2, y: barCenterY)
        root.addChild(waveBadge)

        // -- Hearts (right, shifted left to make room for pause button) --
        let heartsCluster = buildHeartsCluster(startingHealth: BaseHealthManager.startingHealth)
        heartsCluster.position = CGPoint(x: width - 54, y: barCenterY)
        root.addChild(heartsCluster)

        // -- Pause button (far right) --
        let pauseButton = buildPauseButton()
        pauseButton.position = CGPoint(x: width - 18, y: barCenterY)
        root.addChild(pauseButton)

        scene.addChild(root)
        hudNode = root
    }

    private func buildPauseButton() -> SKNode {
        let root = SKNode()
        root.name = "PauseButton"

        // Invisible tap target (larger than the visual)
        let tap = SKShapeNode(circleOfRadius: 18)
        tap.name = "PauseButton"
        tap.fillColor = .clear
        tap.strokeColor = .clear
        root.addChild(tap)

        // Visual: two rounded vertical bars
        let barL = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
        barL.fillColor = SKColor(white: 1.0, alpha: 0.70)
        barL.strokeColor = .clear
        barL.position = CGPoint(x: -4, y: 0)
        root.addChild(barL)

        let barR = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
        barR.fillColor = SKColor(white: 1.0, alpha: 0.70)
        barR.strokeColor = .clear
        barR.position = CGPoint(x: 4, y: 0)
        root.addChild(barR)

        return root
    }

    private func buildCoinCluster(coins: Int) -> SKNode {
        let cluster = SKNode()

        // Coin icon — filled yellow circle
        let icon = SKShapeNode(circleOfRadius: 9)
        icon.fillColor = SKColor(red: 0.98, green: 0.80, blue: 0.12, alpha: 1.0)
        icon.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 1.0)
        icon.lineWidth = 1.5
        icon.position = CGPoint(x: 9, y: 0)
        cluster.addChild(icon)
        coinIconNode = icon

        // Inner coin detail ring
        let innerRing = SKShapeNode(circleOfRadius: 5)
        innerRing.fillColor = .clear
        innerRing.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 0.55)
        innerRing.lineWidth = 1
        innerRing.position = CGPoint(x: 9, y: 0)
        cluster.addChild(innerRing)

        // Coin count label
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "\(coins)"
        label.fontSize = 16
        label.fontColor = SKColor(red: 0.98, green: 0.90, blue: 0.60, alpha: 1.0)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 23, y: 0)
        cluster.addChild(label)
        coinLabel = label

        return cluster
    }

    private func buildWaveBadge() -> SKNode {
        let badge = SKNode()

        // Badge background pill
        let pill = SKShapeNode(rectOf: CGSize(width: 72, height: 24), cornerRadius: 6)
        pill.fillColor = SKColor(red: 0.20, green: 0.48, blue: 0.38, alpha: 0.72)
        pill.strokeColor = SKColor(red: 0.86, green: 0.95, blue: 0.78, alpha: 0.36)
        pill.lineWidth = 1
        badge.addChild(pill)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "WAVE 1"
        label.fontSize = 12
        label.fontColor = SKColor(red: 0.86, green: 0.95, blue: 0.78, alpha: 0.92)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = .zero
        badge.addChild(label)
        waveLabel = label

        return badge
    }

    private func buildHeartsCluster(startingHealth: Int) -> SKNode {
        let cluster = SKNode()
        let spacing: CGFloat = 22
        let totalWidth = CGFloat(startingHealth - 1) * spacing
        heartNodes = []

        // heartNodes[0] = leftmost, heartNodes[last] = rightmost.
        // updateHearts dims from the right as health decreases.
        for i in 0..<startingHealth {
            let heart = SKLabelNode(fontNamed: "AvenirNext-Bold")
            heart.text = "♥"
            heart.fontSize = 20
            heart.fontColor = SKColor(red: 0.92, green: 0.22, blue: 0.18, alpha: 1.0)
            heart.horizontalAlignmentMode = .center
            heart.verticalAlignmentMode = .center
            heart.position = CGPoint(x: -totalWidth + CGFloat(i) * spacing, y: -1)
            cluster.addChild(heart)
            heartNodes.append(heart)
        }

        return cluster
    }

    private func updateHearts(health: Int) {
        guard health != currentHealth else { return }
        defer { currentHealth = health }

        if health < currentHealth {
            // Animate each newly lost heart (normally just one at a time).
            for lostIndex in health..<currentHealth {
                animateHeartLoss(at: lostIndex)
            }
        } else {
            // Health jumped up (restart creates new nodes, but guard this path anyway).
            for (index, heart) in heartNodes.enumerated() {
                heart.removeAction(forKey: "heartLoss")
                heart.setScale(1.0)
                heart.fontColor = index < health
                    ? SKColor(red: 0.92, green: 0.22, blue: 0.18, alpha: 1.0)
                    : SKColor(white: 0.50, alpha: 0.90)
            }
        }
    }

    private func animateHeartLoss(at index: Int) {
        guard index >= 0, index < heartNodes.count else { return }
        let heart = heartNodes[index]

        // Scale up (heart still red — makes the "hit" obvious),
        // then lock to grey at the peak via SKAction.run (reliable, no customAction timing quirks),
        // then scale back down so the grey heart settles into place.
        let scaleUp = SKAction.scale(to: 1.55, duration: 0.09)
        let setGrey = SKAction.run { [weak heart] in
            heart?.fontColor = SKColor(white: 0.50, alpha: 0.90)
        }
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.22)
        scaleDown.timingMode = .easeOut

        heart.run(
            SKAction.sequence([scaleUp, setGrey, scaleDown]),
            withKey: "heartLoss"
        )
    }

    // MARK: - End overlay construction

    private func showEndOverlay(title: String, titleColor: SKColor, subtitle: String, in scene: SKScene) {
        hideEndOverlay()

        let root = SKNode()
        root.name = "EndOverlay"
        root.zPosition = 50
        root.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)

        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 210), cornerRadius: 20)
        panel.fillColor = SKColor(white: 0.0, alpha: 0.78)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.22)
        panel.lineWidth = 2
        root.addChild(panel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 38
        titleLabel.fontColor = titleColor
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 52)
        root.addChild(titleLabel)

        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subtitleLabel.text = subtitle
        subtitleLabel.fontSize = 13
        subtitleLabel.fontColor = SKColor(white: 1.0, alpha: 0.72)
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: 18)
        root.addChild(subtitleLabel)

        let restartButton = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 10)
        restartButton.name = "RestartButton"
        restartButton.fillColor = SKColor(white: 1.0, alpha: 0.18)
        restartButton.strokeColor = SKColor(white: 1.0, alpha: 0.52)
        restartButton.lineWidth = 2
        restartButton.position = CGPoint(x: 0, y: -52)
        root.addChild(restartButton)

        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        restartLabel.name = "RestartButton"
        restartLabel.text = "Restart"
        restartLabel.fontSize = 16
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartButton.addChild(restartLabel)

        scene.addChild(root)
        endOverlayNode = root
    }
}
