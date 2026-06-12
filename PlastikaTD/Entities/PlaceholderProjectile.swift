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

    // Shell variant — a dark finned mortar bomb that lobs in an arc. The body + fins live on
    // `shellLiftNode`, which is offset upward each frame to fake height in the top-down view,
    // while `shellShadowNode` stays on the ground (the projectile's true `node.position`) and
    // grows as the shell descends — selling the arc without a real third dimension.
    private let shellLiftNode: SKNode
    private let shellBodyNode: SKShapeNode
    private let shellFinNode: SKShapeNode
    private let shellShadowNode: SKShapeNode

    private var style: ProjectileVisualStyle = .orb
    private var smokeColor = SKColor(white: 0.82, alpha: 0.85)
    /// The projectile's configured signature color + core radius, cached so a homing missile
    /// that loses its target mid-flight can detonate on the road in its own color (see
    /// `spawnLandingExplosion`). Set in `configure`.
    private var detonationColor = SKColor(red: 0.28, green: 1.0, blue: 0.18, alpha: 1.0)
    private var detonationRadius: CGFloat = 4

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

        // Shadow — stays on the ground at the shell's true position, grows as it descends.
        let shellShadow = SKShapeNode(ellipseOf: CGSize(width: 14, height: 7))
        shellShadow.fillColor = SKColor(white: 0.0, alpha: 0.28)
        shellShadow.strokeColor = .clear
        shellShadow.zPosition = -1
        shellShadow.isHidden = true
        root.addChild(shellShadow)

        // Lift node — carries the floating shell body/fins; offset upward to fake arc height.
        let shellLift = SKNode()
        shellLift.zPosition = 2
        shellLift.isHidden = true
        root.addChild(shellLift)

        // Tail fins — flare out at the base, tinted with the tower's signature color.
        let shellFin = SKShapeNode()
        shellFin.strokeColor = .clear
        shellFin.zPosition = 0
        shellFin.isHidden = true
        shellLift.addChild(shellFin)

        // Body — a stubby dark bomb hull (rest orientation points +y).
        let shellBody = SKShapeNode()
        shellBody.strokeColor = SKColor(white: 1.0, alpha: 0.18)
        shellBody.lineWidth = 1
        shellBody.zPosition = 1
        shellBody.isHidden = true
        shellLift.addChild(shellBody)

        node = root
        glowNode = glow
        coreNode = core
        rocketBodyNode = body
        rocketNoseNode = nose
        exhaustGlowNode = exhaustGlow
        exhaustCoreNode = exhaustCore
        shellLiftNode = shellLift
        shellBodyNode = shellBody
        shellFinNode = shellFin
        shellShadowNode = shellShadow
    }

    /// Resets every bit of visual state for the requested style — color, geometry,
    /// rotation, and which node tree is visible — since pooled instances may have been
    /// last configured as a completely different tower's projectile.
    func configure(color: SKColor, radius: CGFloat, style: ProjectileVisualStyle) {
        self.style = style
        node.zRotation = 0

        let r = max(1, radius)
        detonationColor = color
        detonationRadius = r

        switch style {
        case .orb:
            glowNode.isHidden = false
            coreNode.isHidden = false
            rocketBodyNode.isHidden = true
            rocketNoseNode.isHidden = true
            exhaustGlowNode.isHidden = true
            exhaustCoreNode.isHidden = true
            hideShellNodes()

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
            hideShellNodes()

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

            smokeColor = SKColor(white: 0.82, alpha: 0.85)

        case .shell:
            glowNode.isHidden = true
            coreNode.isHidden = true
            rocketBodyNode.isHidden = true
            rocketNoseNode.isHidden = true
            exhaustGlowNode.isHidden = true
            exhaustCoreNode.isHidden = true

            shellLiftNode.isHidden = false
            shellBodyNode.isHidden = false
            shellFinNode.isHidden = false
            shellShadowNode.isHidden = false
            shellLiftNode.position = .zero
            shellLiftNode.setScale(1)
            shellLiftNode.zRotation = 0
            shellShadowNode.setScale(1)

            let bodyWidth = r * 1.2
            let bodyLength = r * 2.6
            let halfBody = bodyLength / 2

            shellBodyNode.fillColor = SKColor(white: 0.13, alpha: 1.0)
            shellBodyNode.strokeColor = color.withAlphaComponent(0.55)
            shellBodyNode.path = CGPath(
                roundedRect: CGRect(x: -bodyWidth / 2, y: -halfBody, width: bodyWidth, height: bodyLength),
                cornerWidth: bodyWidth * 0.45,
                cornerHeight: bodyWidth * 0.45,
                transform: nil
            )

            let finSpan = bodyWidth * 1.7
            let finPath = CGMutablePath()
            finPath.move(to: CGPoint(x: -bodyWidth / 2, y: -halfBody + r * 0.5))
            finPath.addLine(to: CGPoint(x: -finSpan / 2, y: -halfBody - r * 0.4))
            finPath.addLine(to: CGPoint(x: -bodyWidth / 2, y: -halfBody))
            finPath.closeSubpath()
            finPath.move(to: CGPoint(x: bodyWidth / 2, y: -halfBody + r * 0.5))
            finPath.addLine(to: CGPoint(x: finSpan / 2, y: -halfBody - r * 0.4))
            finPath.addLine(to: CGPoint(x: bodyWidth / 2, y: -halfBody))
            finPath.closeSubpath()
            shellFinNode.fillColor = color
            shellFinNode.path = finPath
        }
    }

    /// Hides every shell-variant node — called from the orb/rocket configure branches so a
    /// pooled instance reused as a different style never leaves a stale shell/shadow on screen.
    private func hideShellNodes() {
        shellLiftNode.isHidden = true
        shellBodyNode.isHidden = true
        shellFinNode.isHidden = true
        shellShadowNode.isHidden = true
    }

    func reset() {
        node.removeAction(forKey: travelActionKey)
        node.removeFromParent()
        node.isHidden = true
        node.zRotation = 0
        shellLiftNode.position = .zero
        shellLiftNode.setScale(1)
        shellLiftNode.zRotation = 0
        shellShadowNode.setScale(1)
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

    /// Lobs the shell in an arc from `startPosition` to `landingPosition` over `duration`.
    /// The projectile's true `node.position` travels the straight ground line between the two
    /// (so the impact, shadow, and splash all land exactly where intended), while the shell
    /// body floats above it on a sine-curve "lift" that peaks at `peakHeight` mid-flight and
    /// returns to zero on touchdown — and the ground shadow grows as it comes down. Always
    /// completes with `true`: a mortar shell always lands and explodes, even on empty road.
    func startLobbedTravel(
        from startPosition: CGPoint,
        to landingPosition: CGPoint,
        duration: TimeInterval,
        peakHeight: CGFloat,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.isHidden = false

        let dx = landingPosition.x - startPosition.x
        let dy = landingPosition.y - startPosition.y
        let safeDuration = max(0.1, duration)

        let lob = SKAction.customAction(withDuration: safeDuration) { [weak self] node, elapsed in
            guard let self else { return }
            let t = min(1, elapsed / CGFloat(safeDuration))
            node.position = CGPoint(x: startPosition.x + dx * t, y: startPosition.y + dy * t)

            let arc = sin(t * .pi)
            self.shellLiftNode.position = CGPoint(x: 0, y: arc * peakHeight)
            self.shellLiftNode.setScale(1 + 0.5 * arc)
            // Shadow is full-size on the ground (t≈0 or 1) and smallest at the apex.
            self.shellShadowNode.setScale(0.4 + 0.6 * (1 - arc))

            // Rotate the shell to follow its ballistic tangent — nose up on the way out, level
            // at the apex, nose down toward the landing. The shell's apparent screen-space
            // velocity is the constant ground travel (dx, dy) plus the lift's rate of change
            // (d/dt of sin(t·π)·peakHeight = cos(t·π)·π·peakHeight, pointing screen-up). The
            // flight duration is a common factor in both components, so it cancels inside
            // atan2 and doesn't need to appear here. Rest orientation points +y, hence −π/2.
            let velocityX = dx
            let velocityY = dy + cos(t * .pi) * .pi * peakHeight
            self.shellLiftNode.zRotation = atan2(velocityY, velocityX) - (.pi / 2)
        }

        node.run(
            SKAction.sequence([
                lob,
                SKAction.run { completion(true) }
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
        let smokeInterval: CGFloat = 0.045

        // Last position the (live) target was seen at, and whether the target has since been
        // lost. When a homing missile's target dies or breaches mid-flight, the missile does
        // NOT vanish — it commits to this ground point and detonates there (cosmetically; the
        // dead target takes no damage), so a fired missile always resolves on the road instead
        // of blinking out of the air.
        var lastKnownTargetPosition = startPosition
        var isCommittingToGround = false

        let home = SKAction.customAction(withDuration: 2.6) { node, elapsedTime in
            guard didComplete == false else {
                return
            }

            let targetPosition: CGPoint
            if isCommittingToGround {
                // Target already gone — fly out the rest of the way to where it last was.
                targetPosition = lastKnownTargetPosition
            } else if let provided = targetPositionProvider() {
                targetPosition = provided
                lastKnownTargetPosition = provided
            } else {
                // Lost the target this frame: switch to "land on the road" mode toward its
                // last seen spot rather than aborting in mid-air.
                isCommittingToGround = true
                targetPosition = lastKnownTargetPosition
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
            // streaks toward its target. The trail keeps drawing while committing to ground.
            if self.style == .rocket {
                node.zRotation = atan2(dy, dx) - (.pi / 2)

                smokeAccumulator += deltaTime
                if smokeAccumulator >= smokeInterval {
                    smokeAccumulator = 0
                    self.spawnSmokePuff(at: node.position)
                }
            }

            // Reached the impact point — either a live target (deal damage via `completion(true)`)
            // or the road spot of a lost target (detonate cosmetically, no damage/sound, so
            // `completion(false)` keeps it out of the normal hit path).
            let stepDistance = max(1, speed * deltaTime)
            if distance <= impactRadius || stepDistance >= distance {
                didComplete = true
                node.position = targetPosition
                node.removeAction(forKey: self.travelActionKey)
                if isCommittingToGround {
                    self.spawnLandingExplosion(at: targetPosition)
                    completion(false)
                } else {
                    completion(true)
                }
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
                        // Ran out of flight time. If it was already committing to a lost
                        // target's ground spot, detonate where it is now rather than blinking
                        // out — keeping the "a fired missile always lands" guarantee even in
                        // the rare long-flight case.
                        if isCommittingToGround {
                            self.spawnLandingExplosion(at: self.node.position)
                        }
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

        let puff = SKShapeNode(circleOfRadius: 3.0)
        puff.fillColor = smokeColor
        puff.strokeColor = .clear
        puff.alpha = 0.85
        puff.position = position
        puff.zPosition = 24
        parent.addChild(puff)

        puff.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.6, duration: 0.7),
                SKAction.fadeOut(withDuration: 0.7)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    /// Detonates a lost-target missile on the road: a color-matched flash inside a thin
    /// expanding shockwave ring — bigger and "explosion-ier" than the normal point impact
    /// flash, but deliberately small and tinted in the missile's own color (not the Mortar's
    /// big fiery orange) so it reads as a wasted warhead going off, not an area attack. Purely
    /// cosmetic: deals no damage (its target is already gone) and plays no sound. Added as a
    /// self-removing sibling via `node.parent`, like `spawnSmokePuff`, so it outlives the
    /// projectile's recycle the same frame.
    private func spawnLandingExplosion(at position: CGPoint) {
        guard let parent = node.parent else {
            return
        }

        let r = detonationRadius

        let flash = SKShapeNode(circleOfRadius: r * 2.0)
        flash.position = position
        flash.fillColor = detonationColor.withAlphaComponent(0.9)
        flash.strokeColor = .clear
        flash.zPosition = 27
        parent.addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 2.4, duration: 0.22), .fadeOut(withDuration: 0.22)]),
            .removeFromParent()
        ]))

        let ring = SKShapeNode(circleOfRadius: r * 1.6)
        ring.position = position
        ring.fillColor = .clear
        ring.strokeColor = detonationColor.withAlphaComponent(0.85)
        ring.lineWidth = 2
        ring.zPosition = 27
        parent.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 3.0, duration: 0.3), .fadeOut(withDuration: 0.3)]),
            .removeFromParent()
        ]))
    }
}
