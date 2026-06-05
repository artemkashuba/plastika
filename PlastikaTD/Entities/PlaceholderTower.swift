import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode

    init() {
        let root = SKNode()
        root.name = "PlaceholderTower"
        root.zPosition = 18

        let base = SKShapeNode(circleOfRadius: 17)
        base.fillColor = SKColor(red: 0.16, green: 0.39, blue: 0.73, alpha: 1.0)
        base.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        base.lineWidth = 3
        root.addChild(base)

        let turret = SKShapeNode(circleOfRadius: 10)
        turret.fillColor = SKColor(red: 0.19, green: 0.64, blue: 0.84, alpha: 1.0)
        turret.strokeColor = SKColor(white: 1.0, alpha: 0.45)
        turret.lineWidth = 2
        turret.zPosition = 1
        root.addChild(turret)

        let barrel = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 3)
        barrel.fillColor = SKColor(red: 0.12, green: 0.27, blue: 0.54, alpha: 1.0)
        barrel.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: 0, y: 16)
        barrel.zPosition = 2
        root.addChild(barrel)

        node = root
    }

    func reset() {
        node.removeFromParent()
    }
}
