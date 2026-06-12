import CoreGraphics
import SpriteKit

struct BuildSpot {
    let id: Int
    let position: CGPoint
}

struct TowerBuildMenuSelection {
    let buildSpot: BuildSpot
    let towerType: TowerType
}

@MainActor
final class BuildSpotManager {
    // Eight spots in two columns, tucked into the gaps between the serpentine's lanes
    // (off the road, clear of the tunnel). The right-column pair flanking the tunnel exit
    // (ids 4 & 5) is the prime "kill zone" — enemies surface there untouched.
    private let buildSpots = [
        BuildSpot(id: 0, position: CGPoint(x: 120, y: 232)),   // band A (bottom) — left
        BuildSpot(id: 1, position: CGPoint(x: 245, y: 232)),   // band A (bottom) — right
        BuildSpot(id: 2, position: CGPoint(x: 120, y: 360)),   // band B (below tunnel) — left
        BuildSpot(id: 3, position: CGPoint(x: 245, y: 360)),   // band B (below tunnel) — right
        BuildSpot(id: 4, position: CGPoint(x: 120, y: 482)),   // band C (above tunnel) — left
        BuildSpot(id: 5, position: CGPoint(x: 245, y: 482)),   // band C (above tunnel) — right ← tunnel-exit kill zone
        BuildSpot(id: 6, position: CGPoint(x: 120, y: 612)),   // band D (top) — left
        BuildSpot(id: 7, position: CGPoint(x: 245, y: 612))    // band D (top) — right
    ]

    private let tapRadius: CGFloat = 30
    private let menuOptionRadius: CGFloat = 18
    private let menuOptionTapRadius: CGFloat = 24
    private let menuYOffset: CGFloat = -54
    private let menuOptionSpacing: CGFloat = 52
    private var buildSpotLayer: SKNode?
    private var buildMenuNode: SKNode?
    private var menuOptionNodesByType: [TowerType: SKNode] = [:]
    private var activeMenuBuildSpot: BuildSpot?
    private var occupiedBuildSpotIDs: Set<Int> = []

    func resetForNewScene() {
        buildSpotLayer?.removeFromParent()
        buildSpotLayer = nil
        hideBuildMenu()
        menuOptionNodesByType.removeAll(keepingCapacity: true)
        occupiedBuildSpotIDs.removeAll(keepingCapacity: true)
    }

    func makeBuildSpotLayer() -> SKNode {
        if let buildSpotLayer {
            return buildSpotLayer
        }

        let layer = SKNode()
        layer.name = "BuildSpotLayer"
        layer.zPosition = 12

        buildSpots.forEach { buildSpot in
            layer.addChild(makeBuildSpotNode(at: buildSpot.position))
        }

        buildSpotLayer = layer
        return layer
    }

    func emptyBuildSpot(containing point: CGPoint) -> BuildSpot? {
        buildSpots.first { buildSpot in
            occupiedBuildSpotIDs.contains(buildSpot.id) == false
                && buildSpot.position.distance(to: point) <= tapRadius
        }
    }

    func showBuildMenu(for buildSpot: BuildSpot, coins: Int, in scene: SKScene) {
        let menuNode = makeBuildMenuNode()
        activeMenuBuildSpot = buildSpot
        menuNode.position = CGPoint(x: buildSpot.position.x, y: buildSpot.position.y + menuYOffset)

        if menuNode.parent == nil {
            scene.addChild(menuNode)
        }

        updateMenuOptionAffordability(coins: coins)
        menuNode.isHidden = false
    }

    func hideBuildMenu() {
        activeMenuBuildSpot = nil
        buildMenuNode?.isHidden = true
        buildMenuNode?.removeFromParent()
    }

    func towerBuildMenuSelection(containing point: CGPoint, coins: Int) -> TowerBuildMenuSelection? {
        guard let activeMenuBuildSpot, let buildMenuNode, buildMenuNode.parent != nil else {
            return nil
        }

        guard let towerType = TowerType.allCases.first(where: { towerType in
            let optionPosition = buildMenuNode.position.translated(by: menuOffset(for: towerType))
            return optionPosition.distance(to: point) <= menuOptionTapRadius
        }) else {
            return nil
        }

        guard coins >= towerType.cost else {
            return nil
        }

        return TowerBuildMenuSelection(buildSpot: activeMenuBuildSpot, towerType: towerType)
    }

    func markOccupied(_ buildSpot: BuildSpot) {
        occupiedBuildSpotIDs.insert(buildSpot.id)
    }

    func markUnoccupied(buildSpotID: Int) {
        occupiedBuildSpotIDs.remove(buildSpotID)
    }

    private func makeBuildMenuNode() -> SKNode {
        if let buildMenuNode {
            return buildMenuNode
        }

        let root = SKNode()
        root.name = "TowerBuildMenu"
        root.zPosition = 32

        TowerType.allCases.forEach { towerType in
            let optionNode = makeBuildMenuOption(for: towerType, at: menuOffset(for: towerType))
            menuOptionNodesByType[towerType] = optionNode
            root.addChild(optionNode)
        }

        buildMenuNode = root
        return root
    }

    private func updateMenuOptionAffordability(coins: Int) {
        TowerType.allCases.forEach { towerType in
            menuOptionNodesByType[towerType]?.alpha = coins >= towerType.cost ? 1.0 : 0.4
        }
    }

    private func makeBuildMenuOption(for towerType: TowerType, at position: CGPoint) -> SKNode {
        let root = SKNode()
        root.name = "TowerBuildMenuOption.\(towerType.displayName)"
        root.position = position

        // Drop shadow
        let shadow = SKShapeNode(circleOfRadius: menuOptionRadius + 3)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: -2)
        root.addChild(shadow)

        // Gunmetal plate background — matches build-spot aesthetic
        let plate = SKShapeNode(circleOfRadius: menuOptionRadius)
        plate.name = root.name
        plate.fillColor = SKColor(red: 0.20, green: 0.24, blue: 0.22, alpha: 1.0)
        plate.strokeColor = towerType.turretColor.withAlphaComponent(0.80)
        plate.lineWidth = 2.5
        plate.zPosition = 1
        root.addChild(plate)

        // Gun preview — scaled-down real tower gun pointing upward
        let previewScale: CGFloat = 0.44
        let assembly = TowerGunFactory.makeAssembly(for: towerType)
        let gun = assembly.aimNode
        gun.position = CGPoint(x: 0, y: -(assembly.tipOffset.y / 2) * previewScale)
        gun.setScale(previewScale)
        gun.zPosition = 2
        root.addChild(gun)

        return root
    }

    /// Spaces every `TowerType` evenly along a horizontal row, centred on the build spot.
    /// Index-based and centred around the row's midpoint, so the layout scales cleanly to
    /// any number of tower types — for the original 3 (red/green/blue) this reproduces the
    /// exact -spacing/0/+spacing offsets the menu always had; the 4th (pink) slots in
    /// symmetrically alongside them at ±spacing/2 and ±3·spacing/2.
    private func menuOffset(for towerType: TowerType) -> CGPoint {
        let allTypes = TowerType.allCases

        guard let index = allTypes.firstIndex(of: towerType) else {
            return .zero
        }

        let centeredIndex = CGFloat(index) - CGFloat(allTypes.count - 1) / 2
        return CGPoint(x: centeredIndex * menuOptionSpacing, y: 0)
    }

    private func makeBuildSpotNode(at position: CGPoint) -> SKNode {
        let root = SKNode()
        root.name = "BuildSpot"
        root.position = position

        // Shadow — offset ellipse below the plate
        let shadow = SKShapeNode(rectOf: CGSize(width: 46, height: 20), cornerRadius: 8)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -5)
        shadow.zPosition = 0
        root.addChild(shadow)

        // Mounting plate — gunmetal square, game-board slot aesthetic
        let plate = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 7)
        plate.fillColor = SKColor(red: 0.26, green: 0.30, blue: 0.28, alpha: 1.0)
        plate.strokeColor = SKColor(red: 0.52, green: 0.60, blue: 0.54, alpha: 0.88)
        plate.lineWidth = 2.5
        plate.zPosition = 1
        root.addChild(plate)

        // Inner recess — slightly darker inset to show depth
        let recess = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        recess.fillColor = SKColor(red: 0.18, green: 0.21, blue: 0.20, alpha: 1.0)
        recess.strokeColor = SKColor(white: 1.0, alpha: 0.12)
        recess.lineWidth = 1
        recess.zPosition = 2
        root.addChild(recess)

        // Centre crosshair — horizontal bar
        let crossH = SKShapeNode(rectOf: CGSize(width: 14, height: 2), cornerRadius: 1)
        crossH.fillColor = SKColor(white: 1.0, alpha: 0.28)
        crossH.strokeColor = .clear
        crossH.zPosition = 3
        root.addChild(crossH)

        // Centre crosshair — vertical bar
        let crossV = SKShapeNode(rectOf: CGSize(width: 2, height: 14), cornerRadius: 1)
        crossV.fillColor = SKColor(white: 1.0, alpha: 0.28)
        crossV.strokeColor = .clear
        crossV.zPosition = 3
        root.addChild(crossV)

        return root
    }
}

private extension CGPoint {
    func translated(by point: CGPoint) -> CGPoint {
        CGPoint(x: x + point.x, y: y + point.y)
    }

    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
