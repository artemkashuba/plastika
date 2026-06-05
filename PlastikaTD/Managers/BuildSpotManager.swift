import CoreGraphics
import SpriteKit

struct BuildSpot {
    let id: Int
    let position: CGPoint
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
    private var buildSpotLayer: SKNode?
    private var occupiedBuildSpotIDs: Set<Int> = []

    func resetForNewScene() {
        buildSpotLayer?.removeFromParent()
        buildSpotLayer = nil
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

    func markOccupied(_ buildSpot: BuildSpot) {
        occupiedBuildSpotIDs.insert(buildSpot.id)
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
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
