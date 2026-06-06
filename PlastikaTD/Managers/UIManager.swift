import SpriteKit

@MainActor
final class UIManager {
    // MARK: - HUD

    private var hudNode: SKNode?
    private var coinLabel: SKLabelNode?
    private var heartNodes: [SKLabelNode] = []
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

        // -- Hearts (right) --
        let heartsCluster = buildHeartsCluster(startingHealth: BaseHealthManager.startingHealth)
        heartsCluster.position = CGPoint(x: width - 20, y: barCenterY)
        root.addChild(heartsCluster)

        scene.addChild(root)
        hudNode = root
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
