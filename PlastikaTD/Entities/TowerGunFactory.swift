import SpriteKit

/// Builds the turret aimNode and barrel-tip offset for a tower type.
/// Used by PlaceholderTower (full size) and BuildSpotManager (scaled preview).
enum TowerGunFactory {

    struct Assembly {
        /// The assembled gun node. Coordinate space: origin = turret pivot, +y = forward.
        let aimNode: SKNode
        /// Barrel tip in aimNode local space. Rotate by aimNode.zRotation to get world-space offset.
        let tipOffset: CGPoint
        /// Forward weapon geometry only (excludes the turret pivot/base). Recoils backward
        /// along its local +y axis when firing — heavier guns kick back further.
        let barrelNode: SKNode
    }

    static func makeAssembly(for type: TowerType) -> Assembly {
        let aimNode = SKNode()
        aimNode.name = "PlaceholderTowerAim"

        // Forward weapon geometry lives in its own node so it can recoil independently
        // of the turret pivot, which stays anchored to the rotation centre.
        let barrelNode = SKNode()
        barrelNode.name = "PlaceholderTowerBarrel"
        aimNode.addChild(barrelNode)

        let tipOffset: CGPoint

        switch type {

        // ── RED: dual autocannon ─────────────────────────────────────────────
        case .red:
            let turret = SKShapeNode(circleOfRadius: 9)
            turret.fillColor = type.turretColor
            turret.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            turret.lineWidth = 2
            turret.zPosition = 1
            aimNode.addChild(turret)

            let bridge = SKShapeNode(rectOf: CGSize(width: 14, height: 5), cornerRadius: 2)
            bridge.fillColor = type.barrelColor
            bridge.strokeColor = .clear
            bridge.position = CGPoint(x: 0, y: 7)
            bridge.zPosition = 2
            barrelNode.addChild(bridge)

            let barrelL = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            barrelL.fillColor = type.barrelColor
            barrelL.strokeColor = SKColor(white: 1.0, alpha: 0.22)
            barrelL.lineWidth = 1
            barrelL.position = CGPoint(x: -5, y: 15)
            barrelL.zPosition = 2
            barrelNode.addChild(barrelL)

            let barrelR = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            barrelR.fillColor = type.barrelColor
            barrelR.strokeColor = SKColor(white: 1.0, alpha: 0.22)
            barrelR.lineWidth = 1
            barrelR.position = CGPoint(x: 5, y: 15)
            barrelR.zPosition = 2
            barrelNode.addChild(barrelR)

            tipOffset = CGPoint(x: 0, y: 25)

        // ── GREEN: missile pod launcher ──────────────────────────────────────
        case .green:
            // Swivel mount — small fixed plate the launcher hull pivots and recoils
            // against; replaces the old bare circular turret so even the rotation pivot
            // itself reads as hardware, not an empty disc peeking out from under the gun.
            let mount = SKShapeNode(rectOf: CGSize(width: 14, height: 10), cornerRadius: 3)
            mount.fillColor = type.turretColor
            mount.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            mount.lineWidth = 2
            mount.position = CGPoint(x: 0, y: 3)
            mount.zPosition = 1
            aimNode.addChild(mount)

            // Launcher hull — one solid rectangular mass that fills the tower's centre and
            // reads as "rocket truck," not "circle with straws stuck on top." Replaces the
            // old floating pod + separate tube pair; recoils backward on every shot like
            // the rest of the roster's forward weapon geometry.
            let hull = SKShapeNode(rectOf: CGSize(width: 24, height: 18), cornerRadius: 4)
            hull.fillColor = type.barrelColor
            hull.strokeColor = SKColor(red: 0.28, green: 0.60, blue: 0.32, alpha: 0.55)
            hull.lineWidth = 1.5
            hull.position = CGPoint(x: 0, y: 13)
            hull.zPosition = 2
            barrelNode.addChild(hull)

            // Twin launch holes recessed directly into the hull's face — dark sockets
            // rather than tubes perched on top, so the armament reads as built-in.
            let holeL = SKShapeNode(circleOfRadius: 3)
            holeL.fillColor = SKColor(white: 0.08, alpha: 1.0)
            holeL.strokeColor = SKColor(white: 1.0, alpha: 0.20)
            holeL.lineWidth = 1
            holeL.position = CGPoint(x: -5.5, y: 17)
            holeL.zPosition = 3
            barrelNode.addChild(holeL)

            let holeR = SKShapeNode(circleOfRadius: 3)
            holeR.fillColor = SKColor(white: 0.08, alpha: 1.0)
            holeR.strokeColor = SKColor(white: 1.0, alpha: 0.20)
            holeR.lineWidth = 1
            holeR.position = CGPoint(x: 5.5, y: 17)
            holeR.zPosition = 3
            barrelNode.addChild(holeR)

            tipOffset = CGPoint(x: 0, y: 23)

        // ── BLUE: mortar ─────────────────────────────────────────────────────
        // A chunky, upward-flaring tube with a 3D angled (elliptical) mouth, sitting on a
        // baseplate + bipod — reads unmistakably as a high-angle mortar from the top-down
        // camera, not a flat direct-fire cannon. The tube recoils straight down into the
        // base on launch (barrelNode kicks back along +y), like a real mortar absorbing the
        // shell. The dark elliptical bore is where the lobbed shell and muzzle flash spawn.
        case .blue:
            let steel = SKColor(red: 0.40, green: 0.48, blue: 0.58, alpha: 1.0)

            // Baseplate — flat dark slab the whole weapon is bedded into.
            let baseplate = SKShapeNode(rectOf: CGSize(width: 26, height: 16), cornerRadius: 6)
            baseplate.fillColor = SKColor(white: 0.14, alpha: 1.0)
            baseplate.strokeColor = SKColor(white: 1.0, alpha: 0.12)
            baseplate.lineWidth = 1
            baseplate.position = CGPoint(x: 0, y: -2)
            baseplate.zPosition = 0
            aimNode.addChild(baseplate)

            // Bipod legs — a splayed V bracing the tube against the baseplate.
            let legL = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            legL.fillColor = type.barrelColor
            legL.strokeColor = SKColor(white: 1.0, alpha: 0.15)
            legL.lineWidth = 1
            legL.position = CGPoint(x: -9, y: 7)
            legL.zRotation = 0.5
            legL.zPosition = 1
            aimNode.addChild(legL)

            let legR = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            legR.fillColor = type.barrelColor
            legR.strokeColor = SKColor(white: 1.0, alpha: 0.15)
            legR.lineWidth = 1
            legR.position = CGPoint(x: 9, y: 7)
            legR.zRotation = -0.5
            legR.zPosition = 1
            aimNode.addChild(legR)

            // Pivot collar — the swivel the tube rotates on.
            let collar = SKShapeNode(circleOfRadius: 9)
            collar.fillColor = type.turretColor
            collar.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            collar.lineWidth = 2
            collar.zPosition = 2
            aimNode.addChild(collar)

            // ── Tube (recoils) — flares wider toward the mouth. ──
            let tubePath = CGMutablePath()
            tubePath.move(to: CGPoint(x: -6, y: 2))
            tubePath.addLine(to: CGPoint(x: 6, y: 2))
            tubePath.addLine(to: CGPoint(x: 9, y: 22))
            tubePath.addLine(to: CGPoint(x: -9, y: 22))
            tubePath.closeSubpath()
            let tube = SKShapeNode(path: tubePath)
            tube.fillColor = type.barrelColor
            tube.strokeColor = SKColor(white: 1.0, alpha: 0.22)
            tube.lineWidth = 1.5
            tube.zPosition = 3
            barrelNode.addChild(tube)

            // Cylinder shading — a soft lighter sliver up the left flank of the tube.
            let sheen = SKShapeNode(rectOf: CGSize(width: 3, height: 17), cornerRadius: 1.5)
            sheen.fillColor = SKColor(white: 1.0, alpha: 0.14)
            sheen.strokeColor = .clear
            sheen.position = CGPoint(x: -4, y: 11)
            sheen.zRotation = 0.06
            sheen.zPosition = 4
            barrelNode.addChild(sheen)

            // Reinforcement bands wrapping the tube.
            let bandLow = SKShapeNode(rectOf: CGSize(width: 15, height: 3.5), cornerRadius: 1.5)
            bandLow.fillColor = SKColor(white: 0.10, alpha: 1.0)
            bandLow.strokeColor = .clear
            bandLow.position = CGPoint(x: 0, y: 8)
            bandLow.zPosition = 5
            barrelNode.addChild(bandLow)

            let bandHigh = SKShapeNode(rectOf: CGSize(width: 17, height: 3.5), cornerRadius: 1.5)
            bandHigh.fillColor = SKColor(white: 0.10, alpha: 1.0)
            bandHigh.strokeColor = .clear
            bandHigh.position = CGPoint(x: 0, y: 15)
            bandHigh.zPosition = 5
            barrelNode.addChild(bandHigh)

            // ── Mouth — an angled elliptical opening (wider than tall) for a 3D look. ──
            let mouthRim = SKShapeNode(ellipseOf: CGSize(width: 21, height: 11))
            mouthRim.fillColor = steel
            mouthRim.strokeColor = SKColor(white: 1.0, alpha: 0.30)
            mouthRim.lineWidth = 1.5
            mouthRim.position = CGPoint(x: 0, y: 22)
            mouthRim.zPosition = 6
            barrelNode.addChild(mouthRim)

            let bore = SKShapeNode(ellipseOf: CGSize(width: 14, height: 7))
            bore.fillColor = SKColor(white: 0.05, alpha: 1.0)
            bore.strokeColor = .clear
            bore.position = CGPoint(x: 0, y: 21.5)
            bore.zPosition = 7
            barrelNode.addChild(bore)

            // Specular crescent on the near lip of the bore — sells the angled 3D mouth.
            let glint = SKShapeNode(ellipseOf: CGSize(width: 8, height: 2.5))
            glint.fillColor = SKColor(white: 1.0, alpha: 0.55)
            glint.strokeColor = .clear
            glint.position = CGPoint(x: -2, y: 24)
            glint.zPosition = 8
            barrelNode.addChild(glint)

            tipOffset = CGPoint(x: 0, y: 23)

        // ── PINK: laser lance ────────────────────────────────────────────────
        case .pink:
            let turret = SKShapeNode(circleOfRadius: 9)
            turret.fillColor = type.turretColor
            turret.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            turret.lineWidth = 2
            turret.zPosition = 1
            aimNode.addChild(turret)

            // Slim emitter housing — the "barrel" a beam projects from
            let housing = SKShapeNode(rectOf: CGSize(width: 9, height: 22), cornerRadius: 4)
            housing.fillColor = type.barrelColor
            housing.strokeColor = SKColor(white: 1.0, alpha: 0.24)
            housing.lineWidth = 1
            housing.position = CGPoint(x: 0, y: 14)
            housing.zPosition = 2
            barrelNode.addChild(housing)

            // Lens glow — soft tinted halo behind the bright emitter core
            let lensGlow = SKShapeNode(circleOfRadius: 6.5)
            lensGlow.fillColor = type.projectileColor.withAlphaComponent(0.35)
            lensGlow.strokeColor = .clear
            lensGlow.position = CGPoint(x: 0, y: 24)
            lensGlow.zPosition = 2
            barrelNode.addChild(lensGlow)

            // Lens — bright white-hot core where the beam originates
            let lens = SKShapeNode(circleOfRadius: 4)
            lens.fillColor = SKColor(white: 1.0, alpha: 0.92)
            lens.strokeColor = type.projectileColor.withAlphaComponent(0.85)
            lens.lineWidth = 2
            lens.position = CGPoint(x: 0, y: 24)
            lens.zPosition = 3
            barrelNode.addChild(lens)

            tipOffset = CGPoint(x: 0, y: 25)
        }

        return Assembly(aimNode: aimNode, tipOffset: tipOffset, barrelNode: barrelNode)
    }
}
