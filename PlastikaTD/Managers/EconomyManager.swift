@MainActor
final class EconomyManager {
    static let startingCoins = 150

    private(set) var coins = EconomyManager.startingCoins

    func resetForNewScene() {
        coins = EconomyManager.startingCoins
    }

    func canAfford(_ cost: Int) -> Bool {
        coins >= cost
    }

    func spend(_ amount: Int) {
        coins = max(0, coins - amount)
    }

    func credit(_ amount: Int) {
        coins += amount
    }
}
