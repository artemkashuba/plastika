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
    private let buildSpots = [
        BuildSpot(id: 0, position: CGPoint(x: 300, y: 185)),
        BuildSpot(id: 1, position: CGPoint(x: 66, y: 280)),
        BuildSpot(id: 2, position: CGPoint(x: 292, y: 352)),
        BuildSpot(id: 3, position: CGPoint(x: 82, y: 530)),
        BuildSpot(id: 4, position: CGPoint(x: 292, y: 620))
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

        let shadow = SKShapeNode(circleOfRadius: menuOptionRadius + 3)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.20)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: -2)
        root.addChild(shadow)

        let option = SKShapeNode(circleOfRadius: menuOptionRadius)
        option.name = root.name
        option.fillColor = towerType.menuColor
        option.strokeColor = SKColor(white: 1.0, alpha: 0.86)
        option.lineWidth = 3
        option.zPosition = 1
        root.addChild(option)

        let inset = SKShapeNode(circleOfRadius: 7)
        inset.fillColor = towerType.baseColor
        inset.strokeColor = SKColor(white: 1.0, alpha: 0.34)
        inset.lineWidth = 1
        inset.zPosition = 2
        root.addChild(inset)

        return root
    }

    private func menuOffset(for towerType: TowerType) -> CGPoint {
        switch towerType {
        case .red:
            CGPoint(x: -menuOptionSpacing, y: 0)
        case .green:
            .zero
        case .blue:
            CGPoint(x: menuOptionSpacing, y: 0)
        }
    }

    private func makeBuildSpotNode(at position: CGPoint) -> SKNode {
        let root = SKNode()
        root.name = "BuildSpot"
        root.position = position

        let shadow = SKShapeNode(circleOfRadius: 24)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.16)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -3)
        shadow.zPosition = 0
        root.addChild(shadow)

        let base = SKShapeNode(circleOfRadius: 22)
        base.fillColor = SKColor(red: 0.73, green: 0.84, blue: 0.64, alpha: 1.0)
        base.strokeColor = SKColor(red: 0.98, green: 0.94, blue: 0.66, alpha: 1.0)
        base.lineWidth = 4
        base.zPosition = 1
        root.addChild(base)

        let inset = SKShapeNode(circleOfRadius: 11)
        inset.fillColor = SKColor(red: 0.38, green: 0.57, blue: 0.44, alpha: 1.0)
        inset.strokeColor = SKColor(white: 1.0, alpha: 0.26)
        inset.lineWidth = 2
        inset.zPosition = 2
        root.addChild(inset)

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
