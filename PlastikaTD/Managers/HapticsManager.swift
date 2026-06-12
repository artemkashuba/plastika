import QuartzCore
import UIKit

/// Centralizes tactile feedback for the game's key moments, mirroring the sound model: gated
/// behind a single persisted enable flag (toggled in the pause menu, stored on
/// `GameStateManager`) and fired from the same call sites as the matching visual/audio cues.
/// Holds the UIKit feedback generators so they stay warm via `prepare()` for low-latency
/// response. Haptics are device-only — on the simulator the generators simply no-op.
///
/// Design notes on *which* moments get haptics (see `DECISIONS.md`):
/// - Discrete, deliberate, or rare events get a crisp tap or notification: placing,
///   upgrading, or selling a tower; a mortar's heavy detonation; an enemy breaching the base;
///   victory/defeat; and HUD button presses.
/// - Per-shot firing is deliberately **not** hapticized — the Autocannon alone fires every
///   0.28s, so tapping on every shot would buzz almost continuously and hammer the Taptic
///   Engine. The Mortar's detonation carries the "heavy weapon" tactile beat for the roster.
/// - Enemy kills tap lightly but are **throttled**, so a mortar splashing a cluster (or
///   several towers all scoring in the same instant) produces a single tap, not a buzz.
@MainActor
final class HapticsManager {
    /// Kept in sync with `GameStateManager.isHapticsEnabled` (mirrors how `isSoundEnabled`
    /// is pushed onto `TowerManager`). Every fire path checks this first, so a disabled
    /// setting is a cheap early-out with no generator work.
    var isEnabled = true

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// Monotonic time of the last throttled impact (kill / detonation). Bursts within
    /// `throttleInterval` collapse to a single tap so dense combat never buzzes.
    private var lastThrottledImpactTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.11

    /// Warms every generator so the first real fire has minimal latency. Call at scene load
    /// and whenever haptics are re-enabled. No-op when disabled.
    func prepareAll() {
        guard isEnabled else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Tower actions

    /// Committing a build — a solid, satisfying "thunk".
    func towerPlaced() { fire(mediumImpact) }

    /// Spending coins to bump a tower a tier — a crisp, "snappier" rigid tap distinct from
    /// the softer placement medium.
    func towerUpgraded() { fire(rigidImpact) }

    /// Cashing a tower out — a light tap, lower-stakes than placing.
    func towerSold() { fire(lightImpact) }

    /// HUD button presses (pause, restart) — the system "selection" feel.
    func buttonTapped() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Combat

    /// An enemy destroyed by damage. Throttled, so splash multi-kills and rapid clusters
    /// produce one tap rather than a buzz.
    func enemyKilled() { fireThrottled(lightImpact) }

    /// A mortar shell detonating — the roster's heaviest tactile beat, paired with the
    /// screen shake. Forced through the throttle (it always fires) AND resets the window, so
    /// the splash kills landing in the same instant are swallowed into this one boom.
    func mortarDetonated() { fireThrottled(heavyImpact, force: true) }

    // MARK: - Outcomes

    /// An enemy reached the base and cost a life — a "warning" double-tap that reads as
    /// something going wrong.
    func baseBreached() { notify(.warning) }

    /// All waves cleared.
    func victory() { notify(.success) }

    /// Base destroyed.
    func defeat() { notify(.error) }

    // MARK: - Internals

    private func fire(_ generator: UIImpactFeedbackGenerator) {
        guard isEnabled else { return }
        generator.impactOccurred()
        generator.prepare()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }

    private func fireThrottled(_ generator: UIImpactFeedbackGenerator, force: Bool = false) {
        guard isEnabled else { return }

        let now = CACurrentMediaTime()
        if !force && now - lastThrottledImpactTime < throttleInterval {
            return
        }

        lastThrottledImpactTime = now
        generator.impactOccurred()
        generator.prepare()
    }
}
