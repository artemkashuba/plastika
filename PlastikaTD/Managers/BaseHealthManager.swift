@MainActor
final class BaseHealthManager {
    static let startingHealth = 3

    private(set) var health = BaseHealthManager.startingHealth

    var isDestroyed: Bool {
        health == 0
    }

    func resetForNewScene() {
        health = BaseHealthManager.startingHealth
    }

    @discardableResult
    func takeDamage() -> Bool {
        health = max(0, health - 1)
        return health == 0
    }
}
