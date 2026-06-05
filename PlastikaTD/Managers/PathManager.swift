import CoreGraphics
import SpriteKit

struct GamePath {
    let waypoints: [CGPoint]
    let movementSpeed: CGFloat

    var startPoint: CGPoint? {
        waypoints.first
    }
}

@MainActor
final class PathManager {
    private(set) var activePath = GamePath(
        waypoints: [
            CGPoint(x: 38, y: 130),
            CGPoint(x: 112, y: 196),
            CGPoint(x: 94, y: 356),
            CGPoint(x: 220, y: 438),
            CGPoint(x: 178, y: 612),
            CGPoint(x: 334, y: 710)
        ],
        movementSpeed: 96
    )

    func resetForNewScene() {
    }

    func makeDebugPathNode() -> SKShapeNode {
        let path = CGMutablePath()

        guard let firstPoint = activePath.waypoints.first else {
            return SKShapeNode()
        }

        path.move(to: firstPoint)
        activePath.waypoints.dropFirst().forEach { point in
            path.addLine(to: point)
        }

        let node = SKShapeNode(path: path)
        node.strokeColor = SKColor(white: 1.0, alpha: 0.28)
        node.lineWidth = 8
        node.lineCap = .round
        node.lineJoin = .round
        node.zPosition = 5
        return node
    }
}
