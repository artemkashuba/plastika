import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode
    let type: TowerType

    /// Current upgrade tier — 0 (base) up to `TowerType.maxUpgradeLevel`. Lives here
    /// (alongside `type`) rather than in one of `TowerManager`'s per-buildspot dictionaries,
    /// because it's part of "what this tower currently is" — identity/state — not
    /// combat-scheduling bookkeeping like cooldowns or target locks. Mutated only via
    /// `upgrade()`, which `TowerManager.upgradeSelectedTower` calls after gating on
    /// affordability and `TowerType.maxUpgradeLevel`.
    private(set) var upgradeLevel = 0

    private let selectionActionKey = "placeholderTower.selection"
    private let recoilActionKey = "placeholderTower.recoil"
    private let reloadIndicatorActionKey = "placeholderTower.reloadIndicator"
    private let beamPulseActionKey = "placeholderTower.beamPulse"
    private let energyVentPulseActionKey = "placeholderTower.energyVentPulse"
    private let aimNode: SKNode
    private let selectionRing: SKShapeNode
    /// Forward weapon geometry (no turret base) — kicks back along local +y when firing.
    private let barrelNode: SKNode
    /// Small radial ring shown only while the tower is reloading; nil once it fades out.
    private var reloadIndicatorNode: SKNode?
    /// Cluster of small glowing "tier pips" sitting just under the base plate — one per
    /// upgrade level purchased. nil at base tier (no pips to show); rebuilt from scratch
    /// by `updateUpgradeIndicator` every time `upgradeLevel` changes, since the count
    /// (not just the visibility) needs to change.
    private var upgradeIndicatorNode: SKNode?
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

    /// This tower's current per-shot damage, scaled by its upgrade level. Mirrors
    /// `TowerType.damage` (0, and unused, for beam towers — see `currentDPS`).
    ///
    /// Walks the multiplier curve tier-by-tier and *ratchets* each step up by at least
    /// +1 over the previous tier's value, rather than independently rounding
    /// `base * multiplier` per level. Plain independent rounding has a real failure mode
    /// for the roster's lowest-damage gun (Red, base damage 1): `1 × 1.5 = 1.5` and
    /// `1 × 2.0 = 2.0` both round to 2, so its second upgrade would be a complete no-op —
    /// the player pays coins for a strictly-worse-than-nothing outcome (no benefit, but a
    /// real cost). The ratchet guarantees every purchased tier visibly does *something*
    /// for every tower, while leaving towers whose curve already lands on clean integers
    /// (Green, Blue) completely untouched — `max` only ever engages where rounding alone
    /// would otherwise stall.
    var currentDamage: Int {
        guard upgradeLevel > 0 else {
            return type.damage
        }

        var value = type.damage
        for level in 1...upgradeLevel {
            let scaled = Int((Double(type.damage) * type.damageMultiplier(atUpgradeLevel: level)).rounded())
            value = max(value + 1, scaled)
        }
        return value
    }

    /// This tower's current damage-per-second, scaled by its upgrade level — derived from
    /// `currentDamage`/cooldown for projectile towers, and from `laserDamagePerSecond`
    /// directly for beam towers, exactly mirroring how `TowerType.dps` derives the base
    /// figure (see that property's doc comment for why beam towers need their own branch).
    var currentDPS: Double {
        switch type.attackStyle {
        case .projectile: Double(currentDamage) / type.attackCooldown
        case .beam:       type.laserDamagePerSecond * type.damageMultiplier(atUpgradeLevel: upgradeLevel)
        }
    }

    /// Bumps this tower's upgrade tier by one and refreshes its tier-pip visual. The
    /// caller (`TowerManager.upgradeSelectedTower`) is responsible for checking
    /// `TowerType.maxUpgradeLevel` and affordability *before* calling this — it trusts
    /// the caller and just applies the change, mirroring how `reset()` trusts its caller
    /// to have already cleared selection state.
    func upgrade() {
        upgradeLevel += 1
        updateUpgradeIndicator()
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

        // Base plate — every tower shares the same round toy-turret plate + glossy specular
        // highlight here, *except* Pink and Green, which get their own unique chassis
        // silhouettes instead: the Laser Lance stands on an angular "energy platform"
        // (flat-topped hexagon ringed with idle-pulsing power vents), and the Missile Pod
        // now stands on a rectangular "armored launch deck" (see `makeArmoredDeck`) — both
        // exist so those towers read as fundamentally different *kinds* of machines at a
        // glance, not just different paint jobs on the same round chassis.
        var energyVentGlows: [SKShapeNode] = []

        switch type {
        case .pink:
            let (platform, ventGlows) = Self.makeEnergyPlatform(type: type)
            root.addChild(platform)
            energyVentGlows = ventGlows

        case .green:
            root.addChild(Self.makeArmoredDeck(type: type))

        case .red, .blue:
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
        }

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

        // Pink's energy-vent glow starts breathing the instant the tower exists — unlike
        // the beam pulse (which only kicks off on first fire), this chassis "tell" should
        // be visible from the moment the tower is placed, before it ever locks a target.
        if energyVentGlows.isEmpty == false {
            startEnergyVentPulse(glows: energyVentGlows)
        }
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

    // MARK: - Energy platform (Pink chassis)

    /// Builds Pink's unique "energy platform" base — a flat-topped hexagonal plate (standing
    /// in for the round plate + specular highlight every other tower shares) ringed with
    /// three small glowing power vents, evenly spaced and tinted in the laser's own
    /// signature color so the chassis itself feels wired into the same energy identity as
    /// its beam and burn mark. Returns the assembled platform plus the bare vent-glow shapes
    /// so `init` can hand them to `startEnergyVentPulse` once `self` is fully set up.
    private static func makeEnergyPlatform(type: TowerType) -> (platform: SKNode, ventGlows: [SKShapeNode]) {
        let platform = SKNode()

        let plate = SKShapeNode(path: polygonPath(sides: 6, radius: 17, rotation: 0))
        plate.fillColor = type.baseColor
        plate.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        plate.lineWidth = 3
        platform.addChild(plate)

        var ventGlows: [SKShapeNode] = []
        let ventCount = 3

        for index in 0..<ventCount {
            let angle = (CGFloat.pi / 2) + (CGFloat(index) / CGFloat(ventCount)) * (2 * .pi)
            let position = CGPoint(x: cos(angle) * 12.5, y: sin(angle) * 12.5)

            // Dark socket — gives the glow somewhere to "sit", like a recessed power port.
            let socket = SKShapeNode(circleOfRadius: 3.2)
            socket.fillColor = SKColor(white: 0.10, alpha: 0.85)
            socket.strokeColor = .clear
            socket.position = position
            socket.zPosition = 1
            platform.addChild(socket)

            // Glowing core — tinted with the laser's own signature color (the new neon-red),
            // tying the chassis's idle "tell" to the same living-energy identity as the beam
            // and the plasma-burn mark it leaves on its targets.
            let glow = SKShapeNode(circleOfRadius: 2.0)
            glow.fillColor = type.projectileColor.withAlphaComponent(0.80)
            glow.strokeColor = .clear
            glow.position = position
            glow.zPosition = 2
            platform.addChild(glow)

            ventGlows.append(glow)
        }

        return (platform, ventGlows)
    }

    // MARK: - Armored deck (Green chassis)

    /// Builds Green's unique "armored launch deck" base — a stout rectangular hull plate
    /// (standing in for the round plate + specular highlight every other tower shares,
    /// the same way Pink's hexagonal energy platform does) sized so its corner-to-center
    /// reach (~17pt) matches the round plate's footprint radius, keeping it within the
    /// selection ring and reload indicator at the same visual scale as the rest of the
    /// roster. Reads as a vehicle hull rather than a disc — the Missile Pod now looks like
    /// a "rocket truck" body even before its launcher hull is considered, instead of an
    /// empty-feeling circle peeking out from behind thin gun barrels. Plain and static (no
    /// idle-pulse glows like Pink's vents) — Green's "tell" is its rocket and smoke trail
    /// in flight, not its chassis at rest.
    private static func makeArmoredDeck(type: TowerType) -> SKNode {
        let deck = SKNode()

        let plate = SKShapeNode(rectOf: CGSize(width: 28, height: 20), cornerRadius: 5)
        plate.fillColor = type.baseColor
        plate.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        plate.lineWidth = 3
        deck.addChild(plate)

        // Specular highlight — same glossy "toy plastic" treatment as the shared round
        // plate's, just repositioned to sit comfortably within the rectangular footprint.
        let highlight = SKShapeNode(circleOfRadius: 5)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.52)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -10, y: 7)
        highlight.zPosition = 1
        deck.addChild(highlight)

        // Corner rivets — small dark studs that sell the "armored vehicle hull" read,
        // the rectangular-deck equivalent of the energy platform's recessed vent sockets.
        let rivetPositions: [CGPoint] = [
            CGPoint(x: -11, y: 7), CGPoint(x: 11, y: 7),
            CGPoint(x: -11, y: -7), CGPoint(x: 11, y: -7)
        ]

        for position in rivetPositions {
            let rivet = SKShapeNode(circleOfRadius: 1.4)
            rivet.fillColor = SKColor(white: 0.12, alpha: 0.55)
            rivet.strokeColor = .clear
            rivet.position = position
            rivet.zPosition = 1
            deck.addChild(rivet)
        }

        return deck
    }

    /// Kicks off a slow, gently out-of-phase idle "breathing" pulse on the energy platform's
    /// power-vent glows — started exactly once, the instant the tower is placed, and runs
    /// forever, completely independent of combat state. Where the beam's neon pulse only
    /// begins once the laser first fires (`startBeamPulse`), this keeps the chassis itself
    /// looking permanently charged and ready — the Laser Lance's "always-on" personality is
    /// visible at rest, not just mid-beam. Each vent starts at a different point in the
    /// cycle (evenly spread across the loop) so they never breathe in lockstep — reading as
    /// an energy core cycling through its conduits rather than a synchronized blink. Sine is
    /// 2π-periodic regardless of the additive phase offset, so every vent's loop still ends
    /// exactly where it began — seamless, just like `startBeamBurnFlicker`'s combined waves.
    private func startEnergyVentPulse(glows: [SKShapeNode]) {
        guard glows.isEmpty == false else {
            return
        }

        let period: TimeInterval = 1.4

        for (index, glow) in glows.enumerated() {
            let baseAlpha = glow.alpha
            let baseScale = glow.xScale
            let phaseOffset = (CGFloat(index) / CGFloat(glows.count)) * (2 * .pi)

            let pulse = SKAction.customAction(withDuration: period) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let phase = (elapsed / CGFloat(period)) * (2 * .pi) + phaseOffset
                let wobble = sin(phase)
                shape.alpha = baseAlpha + wobble * 0.28
                shape.setScale(baseScale + wobble * 0.22)
            }

            glow.run(.repeatForever(pulse), withKey: energyVentPulseActionKey)
        }
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

    // MARK: - Upgrade indicator

    /// Rebuilds the tier-pip cluster from scratch to match the current `upgradeLevel` —
    /// a small horizontal row of glowing dots (tinted in the tower's own `turretColor`,
    /// "glow behind a bright core" — the same visual language as the energy-vent glows
    /// and muzzle flashes) sitting just under the base plate. Hidden entirely at base
    /// tier (nothing to show); one pip at tier 1, two side-by-side at tier 2 (the max).
    /// Rebuilding rather than toggling visibility is simplest here since the *count*
    /// changes, not just whether any pips show.
    private func updateUpgradeIndicator() {
        upgradeIndicatorNode?.removeFromParent()
        upgradeIndicatorNode = nil

        guard upgradeLevel > 0 else {
            return
        }

        let container = SKNode()
        container.position = CGPoint(x: 0, y: -25)
        container.zPosition = 2
        node.addChild(container)
        upgradeIndicatorNode = container

        let pipSpacing: CGFloat = 9
        let totalWidth = CGFloat(upgradeLevel - 1) * pipSpacing
        let startX = -totalWidth / 2

        for index in 0..<upgradeLevel {
            let x = startX + CGFloat(index) * pipSpacing

            let glow = SKShapeNode(circleOfRadius: 3.4)
            glow.fillColor = type.turretColor.withAlphaComponent(0.35)
            glow.strokeColor = .clear
            glow.position = CGPoint(x: x, y: 0)
            container.addChild(glow)

            let core = SKShapeNode(circleOfRadius: 1.7)
            core.fillColor = type.turretColor
            core.strokeColor = .clear
            core.position = CGPoint(x: x, y: 0)
            core.zPosition = 1
            container.addChild(core)
        }
    }

    /// Builds a regular `sides`-gon path centred on the origin with vertices at `radius`,
    /// the first vertex placed `rotation` radians from the +x axis. For a hexagon,
    /// `rotation = 0` yields a flat-topped/flat-bottomed silhouette — a "landing pad" read
    /// from above that instantly distinguishes Pink's platform from the round bases the rest
    /// of the roster shares. Mirrors `radialArcPath`'s angle-math approach to building custom
    /// shape paths via trigonometry rather than hand-plotted points.
    private static func polygonPath(sides: Int, radius: CGFloat, rotation: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleStep = (2 * .pi) / CGFloat(sides)

        for index in 0..<sides {
            let angle = rotation + angleStep * CGFloat(index)
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
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
