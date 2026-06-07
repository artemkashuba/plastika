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
            let turret = SKShapeNode(circleOfRadius: 10)
            turret.fillColor = type.turretColor
            turret.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            turret.lineWidth = 2
            turret.zPosition = 1
            aimNode.addChild(turret)

            let pod = SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 3)
            pod.fillColor = type.barrelColor
            pod.strokeColor = SKColor(red: 0.28, green: 0.60, blue: 0.32, alpha: 0.55)
            pod.lineWidth = 1.5
            pod.position = CGPoint(x: 0, y: 13)
            pod.zPosition = 2
            barrelNode.addChild(pod)

            let tubeL = SKShapeNode(rectOf: CGSize(width: 5, height: 9), cornerRadius: 2)
            tubeL.fillColor = type.barrelColor
            tubeL.strokeColor = .clear
            tubeL.position = CGPoint(x: -5, y: 21)
            tubeL.zPosition = 3
            barrelNode.addChild(tubeL)

            let tubeR = SKShapeNode(rectOf: CGSize(width: 5, height: 9), cornerRadius: 2)
            tubeR.fillColor = type.barrelColor
            tubeR.strokeColor = .clear
            tubeR.position = CGPoint(x: 5, y: 21)
            tubeR.zPosition = 3
            barrelNode.addChild(tubeR)

            let holeL = SKShapeNode(circleOfRadius: 2)
            holeL.fillColor = SKColor(white: 0.08, alpha: 1.0)
            holeL.strokeColor = .clear
            holeL.position = CGPoint(x: -5, y: 25)
            holeL.zPosition = 4
            barrelNode.addChild(holeL)

            let holeR = SKShapeNode(circleOfRadius: 2)
            holeR.fillColor = SKColor(white: 0.08, alpha: 1.0)
            holeR.strokeColor = .clear
            holeR.position = CGPoint(x: 5, y: 25)
            holeR.zPosition = 4
            barrelNode.addChild(holeR)

            tipOffset = CGPoint(x: 0, y: 26)

        // ── BLUE: heavy siege cannon ─────────────────────────────────────────
        case .blue:
            let turret = SKShapeNode(circleOfRadius: 12)
            turret.fillColor = type.turretColor
            turret.strokeColor = SKColor(white: 1.0, alpha: 0.40)
            turret.lineWidth = 2.5
            turret.zPosition = 1
            aimNode.addChild(turret)

            let collar = SKShapeNode(circleOfRadius: 14)
            collar.fillColor = .clear
            collar.strokeColor = type.barrelColor
            collar.lineWidth = 3
            collar.zPosition = 1
            aimNode.addChild(collar)

            let jacket = SKShapeNode(rectOf: CGSize(width: 14, height: 18), cornerRadius: 4)
            jacket.fillColor = type.barrelColor
            jacket.strokeColor = SKColor(white: 1.0, alpha: 0.18)
            jacket.lineWidth = 1.5
            jacket.position = CGPoint(x: 0, y: 15)
            jacket.zPosition = 2
            barrelNode.addChild(jacket)

            let barrel = SKShapeNode(rectOf: CGSize(width: 8, height: 26), cornerRadius: 3)
            barrel.fillColor = SKColor(white: 0.12, alpha: 1.0)
            barrel.strokeColor = .clear
            barrel.position = CGPoint(x: 0, y: 16)
            barrel.zPosition = 3
            barrelNode.addChild(barrel)

            let muzzle = SKShapeNode(rectOf: CGSize(width: 14, height: 5), cornerRadius: 2)
            muzzle.fillColor = type.barrelColor
            muzzle.strokeColor = SKColor(white: 1.0, alpha: 0.28)
            muzzle.lineWidth = 1
            muzzle.position = CGPoint(x: 0, y: 30)
            muzzle.zPosition = 4
            barrelNode.addChild(muzzle)

            tipOffset = CGPoint(x: 0, y: 33)
        }

        return Assembly(aimNode: aimNode, tipOffset: tipOffset, barrelNode: barrelNode)
    }
}
