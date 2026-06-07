import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode
    let type: TowerType

    private let selectionActionKey = "placeholderTower.selection"
    private let recoilActionKey = "placeholderTower.recoil"
    private let reloadIndicatorActionKey = "placeholderTower.reloadIndicator"
    private let beamPulseActionKey = "placeholderTower.beamPulse"
    private let aimNode: SKNode
    private let selectionRing: SKShapeNode
    /// Forward weapon geometry (no turret base) — kicks back along local +y when firing.
    private let barrelNode: SKNode
    /// Small radial ring shown only while the tower is reloading; nil once it fades out.
    private var reloadIndicatorNode: SKNode?
    /// Persistent laser-beam visual (glow + bright core) for beam-style towers. Lives inside
    /// `aimNode` so it automatically points at the target alongside the turret — `showBeam`
    /// only needs to redraw its length each frame. Created lazily on first use; nil for
    /// towers that never fire a beam.
    private var beamGlow: SKShapeNode?
    private var beamCore: SKShapeNode?
    /// Radius of the reload ring — sits as a rim just outside the base plate (radius 17).
    private let reloadIndicatorRadius: CGFloat = 20
    /// Barrel tip in aimNode local space (+y = forward). Used to derive world-space firing origin.
    private let barrelTipOffset: CGPoint

    /// World-space position of the barrel tip, accounting for current turret rotation.
    /// Use this as the projectile spawn point instead of the tower centre.
    var barrelTipPosition: CGPoint {
        let a = aimNode.zRotation
        return CGPoint(
            x: node.position.x + barrelTipOffset.x * cos(a) - barrelTipOffset.y * sin(a),
            y: node.position.y + barrelTipOffset.x * sin(a) + barrelTipOffset.y * cos(a)
        )
    }

    init(type: TowerType) {
        let root = SKNode()
        root.name = "PlaceholderTower"
        root.zPosition = 18

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 40, height: 18))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -7)
        shadow.zPosition = -1
        root.addChild(shadow)

        // Base plate
        let base = SKShapeNode(circleOfRadius: 17)
        base.fillColor = type.baseColor
        base.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        base.lineWidth = 3
        root.addChild(base)

        // Specular highlight
        let highlight = SKShapeNode(circleOfRadius: 5)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.52)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -8, y: 9)
        highlight.zPosition = 1
        root.addChild(highlight)

        let assembly = TowerGunFactory.makeAssembly(for: type)
        root.addChild(assembly.aimNode)
        let tipOffset = assembly.tipOffset

        let selectionRing = SKShapeNode(circleOfRadius: 22)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = SKColor(white: 1.0, alpha: 0.75)
        selectionRing.lineWidth = 2
        selectionRing.zPosition = 5
        selectionRing.isHidden = true
        root.addChild(selectionRing)

        self.aimNode = assembly.aimNode
        self.selectionRing = selectionRing
        self.barrelNode = assembly.barrelNode
        self.barrelTipOffset = tipOffset
        self.type = type
        node = root
    }

    func reset() {
        setSelected(false, animated: false)
        node.removeFromParent()
    }

    func setSelected(_ isSelected: Bool, animated: Bool) {
        node.removeAction(forKey: selectionActionKey)

        if isSelected {
            selectionRing.isHidden = false
        }

        guard animated else {
            node.setScale(isSelected ? 1.05 : 1.0)
            selectionRing.isHidden = isSelected == false
            return
        }

        let scaleAction = SKAction.scale(to: isSelected ? 1.05 : 1.0, duration: 0.18)
        scaleAction.timingMode = .easeOut

        let finish = SKAction.run { [weak selectionRing] in
            selectionRing?.isHidden = isSelected == false
        }

        node.run(SKAction.sequence([scaleAction, finish]), withKey: selectionActionKey)
    }

    func aim(at targetPosition: CGPoint) {
        let dx = targetPosition.x - node.position.x
        let dy = targetPosition.y - node.position.y

        guard dx != 0 || dy != 0 else {
            return
        }

        aimNode.zRotation = atan2(dy, dx) - (.pi / 2)
    }

    // MARK: - Beam (continuous laser)

    /// Draws (or redraws) a persistent beam from the barrel tip to `targetPosition`, tinted
    /// with `color`. Call once per frame while a beam-style tower is locked on a target —
    /// `aimNode` is already rotated toward that target via `aim(at:)`, so the beam only needs
    /// its *length* recomputed each frame; it stays perfectly aimed for free. Built the same
    /// way as the muzzle flash (a soft tinted glow behind a bright core) for visual consistency
    /// with the rest of the tower roster's "feel".
    func showBeam(to targetPosition: CGPoint, color: SKColor) {
        let glow: SKShapeNode
        let core: SKShapeNode

        if let beamGlow, let beamCore {
            glow = beamGlow
            core = beamCore
        } else {
            let glowLine = SKShapeNode()
            glowLine.name = "PlaceholderTowerBeamGlow"
            glowLine.strokeColor = color.withAlphaComponent(0.32)
            glowLine.lineWidth = 7
            glowLine.lineCap = .round
            glowLine.fillColor = .clear
            glowLine.zPosition = 4
            barrelNode.addChild(glowLine)

            let coreLine = SKShapeNode()
            coreLine.name = "PlaceholderTowerBeamCore"
            coreLine.strokeColor = color.withAlphaComponent(0.95)
            coreLine.lineWidth = 2.5
            coreLine.lineCap = .round
            coreLine.fillColor = .clear
            coreLine.zPosition = 5
            barrelNode.addChild(coreLine)

            beamGlow = glowLine
            beamCore = coreLine
            glow = glowLine
            core = coreLine

            startBeamPulse(glow: glowLine, core: coreLine)
        }

        let length = max(0, barrelTipPosition.distance(to: targetPosition))
        let path = CGMutablePath()
        path.move(to: barrelTipOffset)
        path.addLine(to: CGPoint(x: barrelTipOffset.x, y: barrelTipOffset.y + length))

        glow.path = path
        core.path = path
        glow.isHidden = false
        core.isHidden = false
    }

    /// Hides the beam (if one exists). Call whenever a beam-style tower has no valid locked
    /// target — out of range, target died, etc. Safe to call on any tower; a no-op if no
    /// beam has ever been drawn.
    func hideBeam() {
        beamGlow?.isHidden = true
        beamCore?.isHidden = true
    }

    /// Kicks off a slow, organic "neon sign" breathing loop on the beam the instant it's
    /// first created — runs forever, independent of `showBeam`'s per-frame path redraws
    /// (and keeps quietly cycling even while the beam is hidden, so it picks back up
    /// mid-breath rather than resetting whenever the lock re-acquires). Two layers pulse
    /// at slightly different periods and a phase offset so they never breathe in lockstep —
    /// that subtle desync is what reads as a living energy conduit instead of a metronome.
    private func startBeamPulse(glow: SKShapeNode, core: SKShapeNode) {
        let glowBaseLineWidth = glow.lineWidth
        let glowPeriod: TimeInterval = 1.15

        // Soft brightness "breathing" — the glow's halo blooms and recedes.
        let glowAlphaPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.58, duration: glowPeriod / 2),
            SKAction.fadeAlpha(to: 1.0, duration: glowPeriod / 2)
        ])
        glowAlphaPulse.timingMode = .easeInEaseOut

        // Thickness "breathing" — the halo gently swells and thins in time with its glow,
        // like a neon tube's hum made visible.
        let glowWidthPulse = SKAction.customAction(withDuration: glowPeriod) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let phase = (elapsed / CGFloat(glowPeriod)) * (2 * .pi)
            shape.lineWidth = glowBaseLineWidth + sin(phase) * 1.4
        }

        glow.run(.repeatForever(.group([glowAlphaPulse, glowWidthPulse])), withKey: beamPulseActionKey)

        // The bright core flickers on a faster, independent cadence — and starts partway
        // through its cycle — so the two layers drift in and out of phase with each other.
        let corePeriod: TimeInterval = 0.75
        let corePulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.80, duration: corePeriod / 2),
            SKAction.fadeAlpha(to: 1.0, duration: corePeriod / 2)
        ])
        corePulse.timingMode = .easeInEaseOut

        core.run(
            .sequence([SKAction.wait(forDuration: corePeriod * 0.4), .repeatForever(corePulse)]),
            withKey: beamPulseActionKey
        )
    }

    // MARK: - Fire effects

    /// Plays the barrel recoil kick, spawns a muzzle flash at the barrel tip, and shows the
    /// reload-timer ring. Call exactly once at the instant a shot is fired (alongside the
    /// shoot sound) — the moment a fresh cooldown period begins.
    func playFireEffects() {
        playRecoil()
        spawnMuzzleFlash()
        showReloadTimer()
    }

    /// Kicks the barrel assembly backward along its local +y (firing) axis, then springs it
    /// back to rest. Heavier guns (higher recoilDistance) kick back further and feel punchier.
    private func playRecoil() {
        let distance = type.recoilDistance

        // Reset to rest first — guards against the kick/return sequence being interrupted
        // mid-flight by a rapid-fire tower (e.g. the Autocannon's 0.28s cooldown).
        barrelNode.removeAction(forKey: recoilActionKey)
        barrelNode.position = .zero

        let kick = SKAction.moveBy(x: 0, y: -distance, duration: 0.045)
        kick.timingMode = .easeOut
        let recover = SKAction.moveBy(x: 0, y: distance, duration: 0.16)
        recover.timingMode = .easeOut

        barrelNode.run(SKAction.sequence([kick, recover]), withKey: recoilActionKey)
    }

    /// Spawns a brief, bright burst at the barrel tip — a white-hot core inside a tinted glow,
    /// scaled to the gun's bulk — that flashes up and dissolves almost instantly.
    private func spawnMuzzleFlash() {
        let scale = type.muzzleFlashScale

        let flash = SKNode()
        flash.position = barrelTipOffset
        flash.zPosition = 6
        flash.alpha = 0
        flash.setScale(0.5)
        aimNode.addChild(flash)

        let glow = SKShapeNode(ellipseOf: CGSize(width: 12 * scale, height: 19 * scale))
        glow.fillColor = type.projectileColor.withAlphaComponent(0.55)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 4 * scale)
        glow.zPosition = -1
        flash.addChild(glow)

        let core = SKShapeNode(circleOfRadius: 4 * scale)
        core.fillColor = SKColor(white: 1.0, alpha: 0.95)
        core.strokeColor = .clear
        flash.addChild(core)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.025),
            SKAction.scale(to: 1.0, duration: 0.04)
        ])
        appear.timingMode = .easeOut

        let dissolve = SKAction.group([
            SKAction.fadeOut(withDuration: 0.085),
            SKAction.scale(to: 1.4, duration: 0.085)
        ])

        flash.run(SKAction.sequence([appear, dissolve, SKAction.removeFromParent()]))
    }

    // MARK: - Reload indicator

    /// Shows a small radial ring — a faint static track plus a bright white arc that sweeps from
    /// empty to a full circle over the tower's reload duration — sitting like a rim around the
    /// base plate. Fades out the instant the tower is ready to fire again, so it's visible
    /// only while reloading. Does not rotate with the turret (it's a sibling of `aimNode`,
    /// not a child of it).
    private func showReloadTimer() {
        reloadIndicatorNode?.removeAllActions()
        reloadIndicatorNode?.removeFromParent()
        reloadIndicatorNode = nil

        let duration = type.attackCooldown
        guard duration > 0 else { return }

        let radius = reloadIndicatorRadius
        let container = SKNode()
        container.zPosition = 0.5
        container.alpha = 0
        node.addChild(container)
        reloadIndicatorNode = container

        let track = SKShapeNode(circleOfRadius: radius)
        track.strokeColor = SKColor(white: 1.0, alpha: 0.16)
        track.lineWidth = 2
        track.fillColor = .clear
        container.addChild(track)

        let fill = SKShapeNode()
        fill.strokeColor = SKColor(white: 1.0, alpha: 0.92)
        fill.lineWidth = 2.5
        fill.lineCap = .round
        fill.fillColor = .clear
        container.addChild(fill)

        // Redraw the arc's path every frame as elapsed/duration advances from 0 → 1.
        let sweep = SKAction.customAction(withDuration: duration) { [weak fill] _, elapsed in
            let progress = duration > 0 ? min(1, max(0, elapsed / CGFloat(duration))) : 1
            fill?.path = Self.radialArcPath(progress: progress, radius: radius)
        }

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        let fadeOut = SKAction.fadeOut(withDuration: 0.16)
        let cleanup = SKAction.run { [weak self, weak container] in
            guard let container else { return }
            container.removeFromParent()
            if self?.reloadIndicatorNode === container {
                self?.reloadIndicatorNode = nil
            }
        }

        container.run(SKAction.sequence([
            SKAction.group([fadeIn, sweep]),
            fadeOut,
            cleanup
        ]), withKey: reloadIndicatorActionKey)
    }

    /// Builds a stroked arc path starting at 12 o'clock and sweeping clockwise as `progress`
    /// goes from 0 (just fired — empty) to 1 (reloaded — full circle).
    private static func radialArcPath(progress: CGFloat, radius: CGFloat) -> CGPath {
        let clamped = min(1, max(0, progress))
        let path = CGMutablePath()

        guard clamped > 0.001 else {
            return path
        }

        let startAngle = CGFloat.pi / 2
        let endAngle = startAngle - clamped * (2 * .pi)
        path.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return path
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
