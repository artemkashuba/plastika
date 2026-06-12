import CoreGraphics
import SpriteKit

@MainActor
final class ProjectileManager {
    private var activeProjectiles: [PlaceholderProjectile] = []
    private var pooledProjectiles: [PlaceholderProjectile] = []

    func resetForNewScene() {
        (activeProjectiles + pooledProjectiles).forEach { projectile in
            projectile.reset()
        }

        activeProjectiles.removeAll(keepingCapacity: true)
        pooledProjectiles.removeAll(keepingCapacity: true)
    }

    func firePlaceholderProjectile(
        from startPosition: CGPoint,
        to targetPosition: CGPoint,
        behavior: TowerProjectileBehavior,
        color: SKColor,
        radius: CGFloat,
        style: ProjectileVisualStyle,
        speed: CGFloat,
        targetPositionProvider: @escaping @MainActor () -> CGPoint?,
        in scene: SKScene,
        onImpact: @escaping @MainActor () -> Void
    ) {
        let projectile = pooledProjectiles.popLast() ?? PlaceholderProjectile()

        if projectile.node.parent == nil {
            scene.addChild(projectile.node)
        }

        activeProjectiles.append(projectile)
        projectile.configure(color: color, radius: radius, style: style)

        let completion: @MainActor (Bool) -> Void = { [weak self, weak projectile, weak scene] didImpact in
            guard let self, let projectile else {
                return
            }

            let impactPosition = projectile.node.position
            self.recycle(projectile)

            if didImpact {
                onImpact()
                if let scene {
                    self.showImpactFlash(at: impactPosition, color: color, radius: radius, in: scene)
                }
            }
        }

        switch behavior {
        case .direct:
            let duration = TimeInterval(max(0.18, startPosition.distance(to: targetPosition) / speed))
            projectile.startDirectTravel(from: startPosition, to: targetPosition, duration: duration, completion: completion)
        case .homing:
            projectile.startHomingTravel(
                from: startPosition,
                speed: speed,
                targetPositionProvider: targetPositionProvider,
                completion: completion
            )
        case .mortar:
            // Mortar shells are lobbed via `fireMortarShell`, never this path — but recycle
            // defensively so an unexpected call can't leak a configured, parented projectile.
            recycle(projectile)
        }
    }

    /// Lobs a mortar shell from `startPosition` to a fixed `landingPosition` over
    /// `flightDuration`, then detonates: shows a fiery explosion sized to `explosionRadius`
    /// and calls `onImpact` (where the caller applies the area damage at the landing point).
    /// Unlike `firePlaceholderProjectile`, the impact point is decided up front — a mortar
    /// aims at the ground, not a moving target — so there's no in-flight target provider.
    func fireMortarShell(
        from startPosition: CGPoint,
        to landingPosition: CGPoint,
        color: SKColor,
        radius: CGFloat,
        flightDuration: TimeInterval,
        peakHeight: CGFloat,
        explosionRadius: CGFloat,
        in scene: SKScene,
        onImpact: @escaping @MainActor () -> Void
    ) {
        let projectile = pooledProjectiles.popLast() ?? PlaceholderProjectile()

        if projectile.node.parent == nil {
            scene.addChild(projectile.node)
        }

        activeProjectiles.append(projectile)
        projectile.configure(color: color, radius: radius, style: .shell)

        projectile.startLobbedTravel(
            from: startPosition,
            to: landingPosition,
            duration: flightDuration,
            peakHeight: peakHeight
        ) { [weak self, weak scene] _ in
            guard let self else { return }
            self.recycle(projectile)
            onImpact()
            if let scene {
                self.showExplosion(at: landingPosition, radius: explosionRadius, in: scene)
            }
        }
    }

    /// A fiery mortar detonation at `position`: a white-hot core, an orange fireball, an
    /// expanding shockwave ring scaled to the blast `radius`, and a scatter of dark smoke
    /// puffs. All transient, self-removing `SKShapeNode`s — same visual language as the
    /// impact flash and enemy death burst, just bigger and tuned to read as an explosion.
    private func showExplosion(at position: CGPoint, radius: CGFloat, in scene: SKScene) {
        let fireOrange = SKColor(red: 1.0, green: 0.55, blue: 0.14, alpha: 1.0)

        // Heavy ordnance should physically register — a short, small jolt of the whole screen.
        scene.shakeScreen(intensity: 4, duration: 0.2)

        let fireball = SKShapeNode(circleOfRadius: radius * 0.55)
        fireball.position = position
        fireball.fillColor = fireOrange.withAlphaComponent(0.9)
        fireball.strokeColor = .clear
        fireball.zPosition = 28
        scene.addChild(fireball)
        fireball.run(.sequence([
            .group([.scale(to: 1.9, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent()
        ]))

        let core = SKShapeNode(circleOfRadius: radius * 0.30)
        core.position = position
        core.fillColor = SKColor(white: 1.0, alpha: 0.95)
        core.strokeColor = .clear
        core.zPosition = 29
        scene.addChild(core)
        core.run(.sequence([
            .group([.scale(to: 2.0, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))

        let ring = SKShapeNode(circleOfRadius: radius * 0.5)
        ring.position = position
        ring.fillColor = .clear
        ring.strokeColor = fireOrange.withAlphaComponent(0.9)
        ring.lineWidth = 3
        ring.zPosition = 28
        scene.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.0, duration: 0.34), .fadeOut(withDuration: 0.34)]),
            .removeFromParent()
        ]))

        for index in 0..<6 {
            let puff = SKShapeNode(circleOfRadius: radius * 0.22)
            puff.position = position
            puff.fillColor = SKColor(white: 0.22, alpha: 0.55)
            puff.strokeColor = .clear
            puff.zPosition = 27
            scene.addChild(puff)

            let angle = (CGFloat(index) / 6.0) * (2 * .pi) + CGFloat.random(in: -0.4...0.4)
            let distance = radius * CGFloat.random(in: 0.5...0.95)
            let duration = TimeInterval(CGFloat.random(in: 0.4...0.6))
            let drift = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration)
            drift.timingMode = .easeOut
            puff.run(.sequence([
                .group([drift, .scale(to: 1.6, duration: duration), .fadeOut(withDuration: duration)]),
                .removeFromParent()
            ]))
        }
    }

    private func showImpactFlash(at position: CGPoint, color: SKColor, radius: CGFloat, in scene: SKScene) {
        let flash = SKShapeNode(circleOfRadius: radius * 1.2)
        flash.position = position
        flash.fillColor = color.withAlphaComponent(0.90)
        flash.strokeColor = color.withAlphaComponent(0.50)
        flash.lineWidth = 1.5
        flash.zPosition = 27
        scene.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.6, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func recycle(_ projectile: PlaceholderProjectile) {
        projectile.reset()
        activeProjectiles.removeAll { $0 === projectile }
        pooledProjectiles.append(projectile)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
