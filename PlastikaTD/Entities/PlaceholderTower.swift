import SpriteKit

@MainActor
final class PlaceholderTower: GameEntity {
    let node: SKNode
    let type: TowerType

    private let selectionActionKey = "placeholderTower.selection"
    private let aimNode: SKNode
    private let selectionRing: SKShapeNode

    init(type: TowerType) {
        let root = SKNode()
        root.name = "PlaceholderTower"
        root.zPosition = 18

        let base = SKShapeNode(circleOfRadius: 17)
        base.fillColor = type.baseColor
        base.strokeColor = SKColor(red: 0.76, green: 0.92, blue: 1.0, alpha: 1.0)
        base.lineWidth = 3
        root.addChild(base)

        let aimNode = SKNode()
        aimNode.name = "PlaceholderTowerAim"
        root.addChild(aimNode)

        let turret = SKShapeNode(circleOfRadius: 10)
        turret.fillColor = type.turretColor
        turret.strokeColor = SKColor(white: 1.0, alpha: 0.45)
        turret.lineWidth = 2
        turret.zPosition = 1
        aimNode.addChild(turret)

        let barrel = SKShapeNode(rectOf: CGSize(width: 8, height: 22), cornerRadius: 3)
        barrel.fillColor = type.barrelColor
        barrel.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: 0, y: 16)
        barrel.zPosition = 2
        aimNode.addChild(barrel)

        let selectionRing = SKShapeNode(circleOfRadius: 22)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = SKColor(white: 1.0, alpha: 0.75)
        selectionRing.lineWidth = 2
        selectionRing.zPosition = 3
        selectionRing.isHidden = true
        root.addChild(selectionRing)

        self.aimNode = aimNode
        self.selectionRing = selectionRing
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
