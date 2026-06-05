import SpriteKit

protocol GameEntity: AnyObject {
    var node: SKNode { get }

    func reset()
}
