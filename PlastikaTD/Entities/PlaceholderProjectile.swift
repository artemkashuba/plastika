import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderProjectile: GameEntity {
    let node: SKNode

    // Orb variant — the shared glow-behind-bright-core ball every type defaults to.
    private let glowNode: SKShapeNode
    private let coreNode: SKShapeNode

    // Rocket variant — elongated body + nose cone + tail-mounted exhaust, used by warheads
    // that should read as guided munitions (see `ProjectileVisualStyle`). Both variants are
    // built once here in `init` and toggled per-use in `configure`, rather than rebuilt on
    // every fire — cheap, avoids node churn, and correctly handles the pooling reality that
    // any instance may be asked to switch styles between uses.
    private let rocketBodyNode: SKShapeNode
    private let rocketNoseNode: SKShapeNode
    private let exhaustGlowNode: SKShapeNode
    private let exhaustCoreNode: SKShapeNode

    private var style: ProjectileVisualStyle = .orb
    private var smokeColor = SKColor(white: 0.60, alpha: 0.50)

    private let travelActionKey = "placeholderProjectile.travel"

    init() {
        let root = SKNode()
        root.name = "PlaceholderProjectile"
        root.zPosition = 26

        let glow = SKShapeNode(circleOfRadius: 7)
        glow.fillColor = SKColor(red: 1.0, green: 0.28, blue: 0.88, alpha: 0.28)
        glow.strokeColor = .clear
        root.addChild(glow)

        let core = SKShapeNode(circleOfRadius: 4)
        core.fillColor = SKColor(red: 1.0, green: 0.18, blue: 0.83, alpha: 1.0)
        core.strokeColor = SKColor(white: 1.0, alpha: 0.7)
        core.lineWidth = 1
        core.zPosition = 1
        root.addChild(core)

        // Tail-mounted exhaust — a warm glow-behind-bright-core pair, the same visual
        // grammar as the orb's own glow/core relationship, just recolored for "rocket
        // flame" and parked at the missile's tail instead of centred on its body.
        let exhaustGlow = SKShapeNode(circleOfRadius: 7)
        exhaustGlow.fillColor = SKColor(red: 1.0, green: 0.55, blue: 0.18, alpha: 0.30)
        exhaustGlow.strokeColor = .clear
        exhaustGlow.zPosition = 0
        exhaustGlow.isHidden = true
        root.addChild(exhaustGlow)

        let exhaustCore = SKShapeNode(circleOfRadius: 3)
        exhaustCore.fillColor = SKColor(red: 1.0, green: 0.78, blue: 0.30, alpha: 0.95)
        exhaustCore.strokeColor = .clear
        exhaustCore.zPosition = 1
        exhaustCore.isHidden = true
        root.addChild(exhaustCore)

        // Body — solid elongated hull. Its rest orientation (zRotation == 0) points
        // "forward" along +y, matching `aim(at:)`'s rotation convention, so the heading
        // rotation applied in `startHomingTravel` can reuse that exact
        // `atan2(dy, dx) - (.pi / 2)` formula with zero translation needed.
        let body = SKShapeNode()
        body.strokeColor = .clear
        body.zPosition = 2
        body.isHidden = true
        root.addChild(body)

        // Nose cone — small triangular warhead tip, tinted with the projectile's own
        // signature color so a rocket still reads as "this tower's shot," not a generic
        // gray dart wearing someone else's paint.
        let nose = SKShapeNode()
        nose.strokeColor = SKColor(white: 1.0, alpha: 0.6)
        nose.lineWidth = 1
        nose.zPosition = 3
        nose.isHidden = true
        root.addChild(nose)

        node = root
        glowNode = glow
        coreNode = core
        rocketBodyNode = body
        rocketNoseNode = nose
        exhaustGlowNode = exhaustGlow
        exhaustCoreNode = exhaustCore
    }

    /// Resets every bit of visual state for the requested style — color, geometry,
    /// rotation, and which node tree is visible — since pooled instances may have been
    /// last configured as a completely different tower's projectile.
    func configure(color: SKColor, radius: CGFloat, style: ProjectileVisualStyle) {
        self.style = style
        node.zRotation = 0

        let r = max(1, radius)

        switch style {
        case .orb:
            glowNode.isHidden = false
            coreNode.isHidden = false
            rocketBodyNode.isHidden = true
            rocketNoseNode.isHidden = true
            exhaustGlowNode.isHidden = true
            exhaustCoreNode.isHidden = true

            coreNode.fillColor = color
            glowNode.fillColor = color.withAlphaComponent(0.28)
            coreNode.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2), transform: nil)
            glowNode.path = CGPath(ellipseIn: CGRect(x: -r * 1.8, y: -r * 1.8, width: r * 3.6, height: r * 3.6), transform: nil)

        case .rocket:
            glowNode.isHidden = true
            coreNode.isHidden = true
            rocketBodyNode.isHidden = false
            rocketNoseNode.isHidden = false
            exhaustGlowNode.isHidden = false
            exhaustCoreNode.isHidden = false

            let bodyWidth = r * 1.7
            let bodyLength = r * 3.4
            let noseLength = r * 1.6
            let halfBody = bodyLength / 2

            rocketBodyNode.fillColor = SKColor(white: 0.16, alpha: 1.0)
            rocketBodyNode.strokeColor = color.withAlphaComponent(0.5)
            rocketBodyNode.lineWidth = 1
            rocketBodyNode.path = CGPath(
                roundedRect: CGRect(x: -bodyWidth / 2, y: -halfBody, width: bodyWidth, height: bodyLength),
                cornerWidth: bodyWidth * 0.35,
                cornerHeight: bodyWidth * 0.35,
                transform: nil
            )

            let nosePath = CGMutablePath()
            nosePath.move(to: CGPoint(x: -bodyWidth / 2, y: halfBody))
            nosePath.addLine(to: CGPoint(x: bodyWidth / 2, y: halfBody))
            nosePath.addLine(to: CGPoint(x: 0, y: halfBody + noseLength))
            nosePath.closeSubpath()
            rocketNoseNode.fillColor = color
            rocketNoseNode.path = nosePath

            let exhaustGlowRadius = r * 2.0
            let exhaustCoreRadius = r * 0.85
            let tailPosition = CGPoint(x: 0, y: -halfBody)

            exhaustGlowNode.position = tailPosition
            exhaustGlowNode.path = CGPath(
                ellipseIn: CGRect(x: -exhaustGlowRadius, y: -exhaustGlowRadius, width: exhaustGlowRadius * 2, height: exhaustGlowRadius * 2),
                transform: nil
            )

            exhaustCoreNode.position = tailPosition
            exhaustCoreNode.path = CGPath(
                ellipseIn: CGRect(x: -exhaustCoreRadius, y: -exhaustCoreRadius, width: exhaustCoreRadius * 2, height: exhaustCoreRadius * 2),
                transform: nil
            )

            smokeColor = SKColor(white: 0.60, alpha: 0.50)
        }
    }

    func reset() {
        node.removeAction(forKey: travelActionKey)
        node.removeFromParent()
        node.isHidden = true
        node.zRotation = 0
    }

    func startDirectTravel(
        from startPosition: CGPoint,
        to targetPosition: CGPoint,
        duration: TimeInterval,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.isHidden = false

        let travel = SKAction.move(to: targetPosition, duration: duration)
        travel.timingMode = .easeIn

        node.run(
            SKAction.sequence([
                travel,
                SKAction.run {
                    completion(true)
                }
            ]),
            withKey: travelActionKey
        )
    }

    func startHomingTravel(
        from startPosition: CGPoint,
        speed: CGFloat,
        targetPositionProvider: @escaping @MainActor () -> CGPoint?,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.zRotation = 0
        node.isHidden = false

        let impactRadius: CGFloat = 7
        var previousElapsedTime: CGFloat = 0
        var didComplete = false

        // Rocket-style smoke trail bookkeeping — accumulates elapsed flight time and drops
        // a puff every `smokeInterval` seconds, independent of frame rate.
        var smokeAccumulator: CGFloat = 0
        let smokeInterval: CGFloat = 0.06

        let home = SKAction.customAction(withDuration: 2.6) { node, elapsedTime in
            guard didComplete == false else {
                return
            }

            guard let targetPosition = targetPositionProvider() else {
                didComplete = true
                node.removeAction(forKey: self.travelActionKey)
                completion(false)
                return
            }

            let deltaTime = max(0, elapsedTime - previousElapsedTime)
            previousElapsedTime = elapsedTime

            let dx = targetPosition.x - node.position.x
            let dy = targetPosition.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)

            // For a homing missile, the direction toward the target IS the direction of
            // travel each frame — so the heading comes "for free" from `dx`/`dy`, with no
            // separate velocity tracking needed. Reuses `aim(at:)`'s exact rotation
            // formula (assumes the sprite's rest orientation faces +y) for visual
            // consistency with every turret's own aim rotation. Smoke puffs spawn at a
            // steady real-time cadence, leaving a drifting trail behind the rocket as it
            // streaks toward its target.
            if self.style == .rocket {
                node.zRotation = atan2(dy, dx) - (.pi / 2)

                smokeAccumulator += deltaTime
                if smokeAccumulator >= smokeInterval {
                    smokeAccumulator = 0
                    self.spawnSmokePuff(at: node.position)
                }
            }

            guard distance > impactRadius else {
                didComplete = true
                node.position = targetPosition
                node.removeAction(forKey: self.travelActionKey)
                completion(true)
                return
            }

            let stepDistance = max(1, speed * deltaTime)

            if stepDistance >= distance {
                didComplete = true
                node.position = targetPosition
                node.removeAction(forKey: self.travelActionKey)
                completion(true)
                return
            }

            node.position = CGPoint(
                x: node.position.x + (dx / distance) * stepDistance,
                y: node.position.y + (dy / distance) * stepDistance
            )
        }

        node.run(
            SKAction.sequence([
                home,
                SKAction.run {
                    if didComplete == false {
                        didComplete = true
                        completion(false)
                    }
                }
            ]),
            withKey: travelActionKey
        )
    }

    /// Spawns a small drifting smoke puff at `position` that grows and fades before
    /// removing itself — the same spawn → animate (scale + fade-out group) → remove
    /// pattern as `ProjectileManager.showImpactFlash`. Added as a sibling of the
    /// projectile via `node.parent` (which is the scene, and persists across pooling
    /// reuse) rather than as a child, so each puff stays put in world space while the
    /// rocket streaks onward — building a trail rather than riding along with it.
    private func spawnSmokePuff(at position: CGPoint) {
        guard let parent = node.parent else {
            return
        }

        let puff = SKShapeNode(circleOfRadius: 2.2)
        puff.fillColor = smokeColor
        puff.strokeColor = .clear
        puff.alpha = 0.55
        puff.position = position
        puff.zPosition = 24
        parent.addChild(puff)

        puff.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.4, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
