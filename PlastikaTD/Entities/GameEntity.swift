import SpriteKit

@MainActor
protocol GameEntity: AnyObject {
    var node: SKNode { get }

    func reset()
}
