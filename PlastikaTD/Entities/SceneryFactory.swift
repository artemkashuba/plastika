import SpriteKit

/// Builds the battlefield's static, purely-decorative scenery — toy trees, bushes, rocks,
/// and grass tufts scattered through the empty green pockets, plus a "camp" marker where
/// enemies spawn and a "base" objective marker at the path end the player defends.
///
/// Everything here is cosmetic: hand-placed away from the road and build spots, built once
/// (no per-frame cost), and rendered *below* gameplay units — the whole tree sits at
/// `zPosition` 6, above the road (5) and well below enemies (20)/towers/projectiles, so the
/// action always draws on top and stays readable. The look matches the rest of the roster's
/// toy-plastic language: soft drop shadows, clean fills, dark outlines, and a small specular
/// highlight. Positions are fixed (not random per launch) so the map reads as hand-designed.
enum SceneryFactory {

    // MARK: - Palette

    private static let shadowColor = SKColor(white: 0.0, alpha: 0.22)
    private static let trunkColor  = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0)
    private static let leafMid     = SKColor(red: 0.26, green: 0.56, blue: 0.30, alpha: 1.0)
    private static let leafLight   = SKColor(red: 0.36, green: 0.66, blue: 0.38, alpha: 1.0)
    private static let leafDark    = SKColor(red: 0.15, green: 0.38, blue: 0.20, alpha: 1.0)
    private static let pineMid     = SKColor(red: 0.19, green: 0.46, blue: 0.27, alpha: 1.0)
    private static let pineDark    = SKColor(red: 0.12, green: 0.31, blue: 0.18, alpha: 1.0)
    private static let bushGreen   = SKColor(red: 0.28, green: 0.54, blue: 0.30, alpha: 1.0)
    private static let rockMid     = SKColor(red: 0.56, green: 0.57, blue: 0.59, alpha: 1.0)
    private static let rockDark    = SKColor(red: 0.38, green: 0.39, blue: 0.42, alpha: 1.0)
    private static let grassBlade  = SKColor(red: 0.33, green: 0.60, blue: 0.34, alpha: 1.0)
    private static let highlight   = SKColor(white: 1.0, alpha: 0.30)

    // MARK: - Assembly

    /// Returns one container node with all scenery, ready to add to the scene once. `start`
    /// and `end` are the path's first/last waypoints, so the camp and base markers line up
    /// with where enemies actually appear and breach.
    static func makeScenery(start: CGPoint, end: CGPoint) -> SKNode {
        let root = SKNode()
        root.name = "Scenery"
        root.zPosition = 6  // above the road (5), below gameplay units (enemies at 20)

        // Trees & bushes — tucked into the empty pockets between the road and build spots.
        root.addChild(roundTree(at: CGPoint(x: 196, y: 172), scale: 1.00))
        root.addChild(pineTree(at:  CGPoint(x: 338, y: 250), scale: 0.95))
        root.addChild(roundTree(at: CGPoint(x: 50,  y: 410), scale: 0.85))
        root.addChild(pineTree(at:  CGPoint(x: 312, y: 470), scale: 1.05))
        root.addChild(roundTree(at: CGPoint(x: 140, y: 500), scale: 0.95))
        root.addChild(pineTree(at:  CGPoint(x: 160, y: 685), scale: 0.90))
        root.addChild(bush(at:      CGPoint(x: 64,  y: 648), scale: 1.00))
        root.addChild(bush(at:      CGPoint(x: 246, y: 206), scale: 0.90))

        // Rocks.
        for point in [CGPoint(x: 232, y: 300), CGPoint(x: 120, y: 252),
                      CGPoint(x: 300, y: 560), CGPoint(x: 95, y: 590),
                      CGPoint(x: 60, y: 478)] {
            root.addChild(rock(at: point))
        }

        // Grass tufts.
        for point in [CGPoint(x: 250, y: 262), CGPoint(x: 118, y: 420),
                      CGPoint(x: 330, y: 402), CGPoint(x: 208, y: 648),
                      CGPoint(x: 88, y: 352), CGPoint(x: 284, y: 300)] {
            root.addChild(grassTuft(at: point))
        }

        // Objective markers, nudged slightly inward from the exact path ends so they sit on
        // the table rather than overhanging its edge.
        root.addChild(spawnMarker(at: CGPoint(x: start.x + 16, y: start.y + 8)))
        root.addChild(baseMarker(at: CGPoint(x: end.x - 8, y: end.y - 16)))

        return root
    }

    // MARK: - Shared helpers

    private static func shadow(width: CGFloat, height: CGFloat, at point: CGPoint) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        node.fillColor = shadowColor
        node.strokeColor = .clear
        node.position = point
        node.zPosition = 0
        return node
    }

    private static func circle(radius: CGFloat, fill: SKColor, stroke: SKColor,
                               at point: CGPoint, z: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 1.5
        node.position = point
        node.zPosition = z
        return node
    }

    // MARK: - Trees

    private static func roundTree(at point: CGPoint, scale: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = point
        node.setScale(scale)

        node.addChild(shadow(width: 30, height: 12, at: CGPoint(x: 2, y: -15)))

        let trunk = SKShapeNode(rectOf: CGSize(width: 5, height: 14), cornerRadius: 2)
        trunk.fillColor = trunkColor
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: -8)
        trunk.zPosition = 1
        node.addChild(trunk)

        node.addChild(circle(radius: 15, fill: leafMid, stroke: leafDark, at: CGPoint(x: 0, y: 4), z: 2))
        node.addChild(circle(radius: 9, fill: leafLight, stroke: .clear, at: CGPoint(x: -5, y: 9), z: 3))
        node.addChild(circle(radius: 3.5, fill: highlight, stroke: .clear, at: CGPoint(x: -7, y: 12), z: 4))

        return node
    }

    private static func pineTree(at point: CGPoint, scale: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = point
        node.setScale(scale)

        node.addChild(shadow(width: 26, height: 10, at: CGPoint(x: 1, y: -14)))

        let trunk = SKShapeNode(rectOf: CGSize(width: 4, height: 8), cornerRadius: 1.5)
        trunk.fillColor = trunkColor
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: -9)
        trunk.zPosition = 1
        node.addChild(trunk)

        node.addChild(pineTier(baseY: -6, halfWidth: 13, height: 14, z: 2))
        node.addChild(pineTier(baseY: 2,  halfWidth: 10, height: 13, z: 3))
        node.addChild(pineTier(baseY: 9,  halfWidth: 7,  height: 12, z: 4))

        return node
    }

    private static func pineTier(baseY: CGFloat, halfWidth: CGFloat, height: CGFloat, z: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfWidth, y: baseY))
        path.addLine(to: CGPoint(x: halfWidth, y: baseY))
        path.addLine(to: CGPoint(x: 0, y: baseY + height))
        path.closeSubpath()

        let tier = SKShapeNode(path: path)
        tier.fillColor = pineMid
        tier.strokeColor = pineDark
        tier.lineWidth = 1.5
        tier.zPosition = z
        return tier
    }

    private static func bush(at point: CGPoint, scale: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = point
        node.setScale(scale)

        node.addChild(shadow(width: 26, height: 9, at: CGPoint(x: 1, y: -7)))
        node.addChild(circle(radius: 9, fill: bushGreen, stroke: leafDark, at: CGPoint(x: -6, y: 0), z: 1))
        node.addChild(circle(radius: 11, fill: bushGreen, stroke: leafDark, at: CGPoint(x: 3, y: 1), z: 1))
        node.addChild(circle(radius: 7, fill: leafLight, stroke: .clear, at: CGPoint(x: -2, y: 5), z: 2))

        return node
    }

    // MARK: - Ground detail

    private static func rock(at point: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = point

        node.addChild(shadow(width: 16, height: 6, at: CGPoint(x: 1, y: -5)))

        let body = SKShapeNode(ellipseOf: CGSize(width: 16, height: 12))
        body.fillColor = rockMid
        body.strokeColor = rockDark
        body.lineWidth = 1.5
        body.zPosition = 1
        node.addChild(body)

        let spec = SKShapeNode(ellipseOf: CGSize(width: 5, height: 3))
        spec.fillColor = highlight
        spec.strokeColor = .clear
        spec.position = CGPoint(x: -3, y: 3)
        spec.zPosition = 2
        node.addChild(spec)

        return node
    }

    private static func grassTuft(at point: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = point

        let angles: [CGFloat] = [-0.5, -0.2, 0.05, 0.3, 0.55]
        for (index, angle) in angles.enumerated() {
            let height = 9 - abs(angle) * 4   // centre blades a touch taller
            let blade = SKShapeNode(rectOf: CGSize(width: 2, height: height), cornerRadius: 1)
            blade.fillColor = grassBlade
            blade.strokeColor = .clear
            blade.position = CGPoint(x: CGFloat(index - 2) * 2.5, y: height / 2 - 2)
            blade.zRotation = angle
            blade.zPosition = 1
            node.addChild(blade)
        }

        return node
    }

    // MARK: - Objective markers

    /// Enemy "camp" at the spawn — a khaki tent with a dark entrance and a maroon flag (the
    /// enemy livery color), so the start of the route reads as where the toy army musters.
    private static func spawnMarker(at point: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = point
        node.zPosition = 1

        node.addChild(shadow(width: 40, height: 14, at: CGPoint(x: 2, y: -13)))

        let tan = SKColor(red: 0.64, green: 0.54, blue: 0.36, alpha: 1.0)
        let tanDark = SKColor(red: 0.44, green: 0.36, blue: 0.22, alpha: 1.0)

        let tentPath = CGMutablePath()
        tentPath.move(to: CGPoint(x: -20, y: -12))
        tentPath.addLine(to: CGPoint(x: 20, y: -12))
        tentPath.addLine(to: CGPoint(x: 0, y: 18))
        tentPath.closeSubpath()
        let tent = SKShapeNode(path: tentPath)
        tent.fillColor = tan
        tent.strokeColor = tanDark
        tent.lineWidth = 2
        tent.zPosition = 1
        node.addChild(tent)

        let entrancePath = CGMutablePath()
        entrancePath.move(to: CGPoint(x: -7, y: -12))
        entrancePath.addLine(to: CGPoint(x: 7, y: -12))
        entrancePath.addLine(to: CGPoint(x: 0, y: 6))
        entrancePath.closeSubpath()
        let entrance = SKShapeNode(path: entrancePath)
        entrance.fillColor = SKColor(white: 0.08, alpha: 0.85)
        entrance.strokeColor = .clear
        entrance.zPosition = 2
        node.addChild(entrance)

        node.addChild(flag(poleX: 0, poleTopY: 32,
                           flagColor: SKColor(red: 0.68, green: 0.20, blue: 0.16, alpha: 1.0),
                           pointsRight: true))

        return node
    }

    /// Player "base" objective at the path end — a bunker with a friendly cyan flag, marking
    /// what the player is defending where enemies breach.
    private static func baseMarker(at point: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = point
        node.zPosition = 1

        node.addChild(shadow(width: 40, height: 14, at: CGPoint(x: 2, y: -12)))

        let wall = SKColor(red: 0.42, green: 0.47, blue: 0.55, alpha: 1.0)
        let wallDark = SKColor(red: 0.28, green: 0.32, blue: 0.40, alpha: 1.0)

        let body = SKShapeNode(rectOf: CGSize(width: 34, height: 24), cornerRadius: 5)
        body.fillColor = wall
        body.strokeColor = wallDark
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 2)
        body.zPosition = 1
        node.addChild(body)

        let roof = SKShapeNode(rectOf: CGSize(width: 34, height: 7), cornerRadius: 3)
        roof.fillColor = wallDark
        roof.strokeColor = .clear
        roof.position = CGPoint(x: 0, y: 11)
        roof.zPosition = 2
        node.addChild(roof)

        let door = SKShapeNode(rectOf: CGSize(width: 10, height: 12), cornerRadius: 2)
        door.fillColor = SKColor(white: 0.10, alpha: 0.9)
        door.strokeColor = .clear
        door.position = CGPoint(x: 0, y: -2)
        door.zPosition = 2
        node.addChild(door)

        let spec = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 2)
        spec.fillColor = highlight
        spec.strokeColor = .clear
        spec.position = CGPoint(x: -11, y: 3)
        spec.zPosition = 3
        node.addChild(spec)

        node.addChild(flag(poleX: 11, poleTopY: 33,
                           flagColor: SKColor(red: 0.19, green: 0.64, blue: 0.84, alpha: 1.0),
                           pointsRight: true))

        return node
    }

    /// A small pennant on a white pole — shared by both markers.
    private static func flag(poleX: CGFloat, poleTopY: CGFloat, flagColor: SKColor, pointsRight: Bool) -> SKNode {
        let node = SKNode()

        let poleHeight: CGFloat = 18
        let pole = SKShapeNode(rectOf: CGSize(width: 2, height: poleHeight), cornerRadius: 1)
        pole.fillColor = SKColor(white: 0.9, alpha: 1.0)
        pole.strokeColor = .clear
        pole.position = CGPoint(x: poleX, y: poleTopY - poleHeight / 2)
        pole.zPosition = 3
        node.addChild(pole)

        let direction: CGFloat = pointsRight ? 1 : -1
        let flagPath = CGMutablePath()
        flagPath.move(to: CGPoint(x: poleX + direction, y: poleTopY))
        flagPath.addLine(to: CGPoint(x: poleX + direction * 13, y: poleTopY - 3))
        flagPath.addLine(to: CGPoint(x: poleX + direction, y: poleTopY - 6))
        flagPath.closeSubpath()
        let pennant = SKShapeNode(path: flagPath)
        pennant.fillColor = flagColor
        pennant.strokeColor = .clear
        pennant.zPosition = 3
        node.addChild(pennant)

        return node
    }
}
