import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode
    let type: TowerType

    private let selectionActionKey = "placeholderTower.selection"
    private let aimNode: SKNode
    private let selectionRing: SKShapeNode
    /// Barrel tip in aimNode local space (+y = forward). Used to derive world-space firing origin.
    private let barrelTipOffset: CGPoint

    /// World-space position of the barrel tip, accounting for current turret rotation.
    /// Use this as the projectile spawn point instead of the tower centre.
    var barrelTipPosition: CGPoint {
        let a = aimNode.zRotation
        return CGPoint(
            x: node.position.x + barrelTipOffset.x * cos(a) - barrelTipOffset.y * sin(a),
            y: node.position.y + barrelTipOffset.x * sin(a) + barrelTipOffset.y * cos(a)
        )
    }

    init(type: TowerType) {
        let root = SKNode()
        root.name = "PlaceholderTower"
        root.zPosition = 18

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 40, height: 18))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -7)
        shadow.zPosition = -1
        root.addChild(shadow)

        // Base plate
        let base = SKShapeNode(circleOfRadius: 17)
        base.fillColor = type.baseColor
        base.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        base.lineWidth = 3
        root.addChild(base)

        // Specular highlight
        let highlight = SKShapeNode(circleOfRadius: 5)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.52)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -8, y: 9)
        highlight.zPosition = 1
        root.addChild(highlight)

        let assembly = TowerGunFactory.makeAssembly(for: type)
        root.addChild(assembly.aimNode)
        let tipOffset = assembly.tipOffset

        let selectionRing = SKShapeNode(circleOfRadius: 22)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = SKColor(white: 1.0, alpha: 0.75)
        selectionRing.lineWidth = 2
        selectionRing.zPosition = 5
        selectionRing.isHidden = true
        root.addChild(selectionRing)

        self.aimNode = assembly.aimNode
        self.selectionRing = selectionRing
        self.barrelTipOffset = tipOffset
        self.type = type
        node = root
    }

    func reset() {
        setSelected(false, animated: false)
        node.removeFromParent()
    }

    func setSelected(_ isSelected: Bool, animated: Bool) {
        node.removeAction(forKey: selectionActionKey)

        if isSelected {
            selectionRing.isHidden = false
        }

        guard animated else {
            node.setScale(isSelected ? 1.05 : 1.0)
            selectionRing.isHidden = isSelected == false
            return
        }

        let scaleAction = SKAction.scale(to: isSelected ? 1.05 : 1.0, duration: 0.18)
        scaleAction.timingMode = .easeOut

        let finish = SKAction.run { [weak selectionRing] in
            selectionRing?.isHidden = isSelected == false
        }

        node.run(SKAction.sequence([scaleAction, finish]), withKey: selectionActionKey)
    }

    func aim(at targetPosition: CGPoint) {
        let dx = targetPosition.x - node.position.x
        let dy = targetPosition.y - node.position.y

        guard dx != 0 || dy != 0 else {
            return
        }

        aimNode.zRotation = atan2(dy, dx) - (.pi / 2)
    }
}
