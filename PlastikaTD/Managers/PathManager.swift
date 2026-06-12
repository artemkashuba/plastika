import CoreGraphics
import SpriteKit

struct GamePath {
    let waypoints: [CGPoint]
    let movementSpeed: CGFloat
    /// Indices of segments that run underground. A segment `i` spans `waypoints[i] →
    /// waypoints[i+1]`. While an enemy traverses a tunnel segment it goes underground —
    /// hidden, untargetable, and immune to damage — re-emerging at the far mouth. Empty for
    /// fully-aboveground paths.
    let tunnelSegmentIndices: Set<Int>

    init(waypoints: [CGPoint], movementSpeed: CGFloat, tunnelSegmentIndices: Set<Int> = []) {
        self.waypoints = waypoints
        self.movementSpeed = movementSpeed
        self.tunnelSegmentIndices = tunnelSegmentIndices
    }

    var startPoint: CGPoint? {
        waypoints.first
    }

    /// The path's final waypoint — where enemies breach the base. The Mortar aims its shells
    /// relative to this so it bombards the leading edge of the advance.
    var endPoint: CGPoint? {
        waypoints.last
    }
}

@MainActor
final class PathManager {
    // A 5-lane serpentine: spawn bottom-left → switchbacks → the full middle lane runs
    // underground (the tunnel) → more switchbacks → across the top → base top-right.
    // Segment 4 (waypoints[4] → waypoints[5]) is the tunnel.
    private(set) var activePath = GamePath(
        waypoints: [
            CGPoint(x: 72,  y: 165),   // 0 — spawn (bottom-left)
            CGPoint(x: 300, y: 165),   // 1
            CGPoint(x: 300, y: 300),   // 2
            CGPoint(x: 72,  y: 300),   // 3
            CGPoint(x: 72,  y: 420),   // 4 — tunnel entrance (left)
            CGPoint(x: 300, y: 420),   // 5 — tunnel exit (right)
            CGPoint(x: 300, y: 545),   // 6
            CGPoint(x: 72,  y: 545),   // 7
            CGPoint(x: 72,  y: 680),   // 8
            CGPoint(x: 300, y: 680),   // 9
            CGPoint(x: 300, y: 720)    // 10 — base (top-right)
        ],
        movementSpeed: 76,
        tunnelSegmentIndices: [4]
    )

    func resetForNewScene() {
    }

    func makeDebugPathNode() -> SKNode {
        let root = SKNode()
        root.zPosition = 5

        let roadPath = makeAbovegroundRoadPath()

        // Road base — wide dark asphalt strip. Tunnel segments are left as gaps: like real
        // life, an underground stretch is invisible from above (grass simply continues over
        // it) and the only indication of the tunnel is the portal at each mouth.
        let road = SKShapeNode(path: roadPath)
        road.strokeColor = SKColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 0.88)
        road.lineWidth = 28
        road.lineCap = .round
        road.lineJoin = .round
        root.addChild(road)

        // Center dashes — faint lane marking running along the road
        let stripe = SKShapeNode(path: roadPath)
        stripe.strokeColor = SKColor(white: 1.0, alpha: 0.10)
        stripe.lineWidth = 2
        stripe.lineCap = .butt
        stripe.lineJoin = .round
        root.addChild(stripe)

        addTunnelPortals(to: root)

        return root
    }

    /// The road's CGPath covering only above-ground segments — each tunnel segment becomes
    /// a gap in the stroke (a fresh `move(to:)` restarts the road at the tunnel's far mouth).
    private func makeAbovegroundRoadPath() -> CGPath {
        let waypoints = activePath.waypoints
        let cgPath = CGMutablePath()
        var needsMove = true

        for index in 0..<max(0, waypoints.count - 1) {
            if activePath.tunnelSegmentIndices.contains(index) {
                needsMove = true
                continue
            }
            if needsMove {
                cgPath.move(to: waypoints[index])
                needsMove = false
            }
            cgPath.addLine(to: waypoints[index + 1])
        }

        return cgPath
    }

    /// Marks each tunnel mouth with a grassy hillside portal — a mound with a stone facade
    /// and a dark arched opening — the only visible trace of the tunnel, exactly like a real
    /// hill tunnel seen from above. Each portal's opening lines up with the *above-ground*
    /// road it connects to (the entrance faces the arriving road, the exit faces the resuming
    /// road), so the asphalt runs straight into the dark mouth like a road into a hillside.
    private func addTunnelPortals(to root: SKNode) {
        let waypoints = activePath.waypoints

        for index in activePath.tunnelSegmentIndices.sorted() {
            guard index + 1 < waypoints.count else { continue }
            let start = waypoints[index]
            let end = waypoints[index + 1]
            // Fallback when the tunnel is the path's first/last segment: face the buried line.
            let tunnelAngle = atan2(end.y - start.y, end.x - start.x)

            // Entrance — local -y (the opening) faces back along the road that arrives here.
            var entranceAngle = tunnelAngle - (.pi / 2)
            if index > 0 {
                let previous = waypoints[index - 1]
                entranceAngle = atan2(start.y - previous.y, start.x - previous.x) - (.pi / 2)
            }
            root.addChild(tunnelPortal(at: start, rotation: entranceAngle))

            // Exit — the opening faces along the road that resumes at the far mouth.
            var exitAngle = tunnelAngle + (.pi / 2)
            if index + 2 < waypoints.count {
                let next = waypoints[index + 2]
                exitAngle = atan2(next.y - end.y, next.x - end.x) + (.pi / 2)
            }
            root.addChild(tunnelPortal(at: end, rotation: exitAngle))
        }
    }

    /// One tunnel-mouth portal in the roster's toy-plastic language: soft shadow, a
    /// grass-covered mound, a stone facade with a dark arched opening at the local origin
    /// (facing -y), and a small specular highlight. Rotate so local +y points underground.
    private func tunnelPortal(at point: CGPoint, rotation: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = point
        node.zRotation = rotation
        node.zPosition = 0.5

        let grassMound = SKColor(red: 0.19, green: 0.42, blue: 0.32, alpha: 1.0)
        let grassEdge = SKColor(red: 0.12, green: 0.30, blue: 0.22, alpha: 1.0)
        let stone = SKColor(red: 0.56, green: 0.57, blue: 0.59, alpha: 1.0)
        let stoneDark = SKColor(red: 0.38, green: 0.39, blue: 0.42, alpha: 1.0)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 56, height: 48))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: 9)
        node.addChild(shadow)

        let mound = SKShapeNode(ellipseOf: CGSize(width: 50, height: 42))
        mound.fillColor = grassMound
        mound.strokeColor = grassEdge
        mound.lineWidth = 2
        mound.position = CGPoint(x: 0, y: 12)
        mound.zPosition = 1
        node.addChild(mound)

        // Stone facade — the front wall the opening is cut into.
        let facade = SKShapeNode(rectOf: CGSize(width: 42, height: 12), cornerRadius: 4)
        facade.fillColor = stone
        facade.strokeColor = stoneDark
        facade.lineWidth = 1.5
        facade.zPosition = 2
        node.addChild(facade)

        // Dark opening the road disappears into.
        let opening = SKShapeNode(ellipseOf: CGSize(width: 24, height: 13))
        opening.fillColor = SKColor(white: 0.06, alpha: 0.95)
        opening.strokeColor = .clear
        opening.position = CGPoint(x: 0, y: -3)
        opening.zPosition = 3
        node.addChild(opening)

        // Stone arch rim around the opening.
        let rim = SKShapeNode(ellipseOf: CGSize(width: 28, height: 16))
        rim.fillColor = .clear
        rim.strokeColor = stoneDark
        rim.lineWidth = 2.5
        rim.position = CGPoint(x: 0, y: -3)
        rim.zPosition = 4
        node.addChild(rim)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: 12, height: 6))
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.22)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -8, y: 20)
        highlight.zPosition = 5
        node.addChild(highlight)

        return node
    }
}
