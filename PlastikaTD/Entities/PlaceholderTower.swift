import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode
    let type: TowerType

    private let selectionActionKey = "placeholderTower.selection"
    private let recoilActionKey = "placeholderTower.recoil"
    private let reloadIndicatorActionKey = "placeholderTower.reloadIndicator"
    private let aimNode: SKNode
    private let selectionRing: SKShapeNode
    /// Forward weapon geometry (no turret base) — kicks back along local +y when firing.
    private let barrelNode: SKNode
    /// Small radial ring shown only while the tower is reloading; nil once it fades out.
    private var reloadIndicatorNode: SKNode?
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

    /// Shows a small radial ring — a faint static track plus a colored arc that sweeps from
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
        fill.strokeColor = type.turretColor
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
