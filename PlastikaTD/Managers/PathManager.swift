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
        movementSpeed: 76
    )

    func resetForNewScene() {
    }

    func makeDebugPathNode() -> SKNode {
        let cgPath = CGMutablePath()

        guard let firstPoint = activePath.waypoints.first else {
            return SKNode()
        }

        cgPath.move(to: firstPoint)
        activePath.waypoints.dropFirst().forEach { point in
            cgPath.addLine(to: point)
        }

        let root = SKNode()
        root.zPosition = 5

        // Road base — wide dark asphalt strip
        let road = SKShapeNode(path: cgPath)
        road.strokeColor = SKColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 0.88)
        road.lineWidth = 28
        road.lineCap = .round
        road.lineJoin = .round
        root.addChild(road)

        // Center dashes — faint lane marking running along the road
        let stripe = SKShapeNode(path: cgPath)
        stripe.strokeColor = SKColor(white: 1.0, alpha: 0.10)
        stripe.lineWidth = 2
        stripe.lineCap = .butt
        stripe.lineJoin = .round
        root.addChild(stripe)

        return root
    }
}
