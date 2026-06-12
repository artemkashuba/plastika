import SpriteKit

@MainActor
final class TowerManager {
    private let placeholderAttackRange: CGFloat = 175

    private struct TargetLock {
        weak var enemy: PlaceholderEnemy?
        let lifeID: Int
    }

    private var towersByBuildSpotID: [Int: PlaceholderTower] = [:]
    private var nextAttackTimesByBuildSpotID: [Int: TimeInterval] = [:]
    /// Tracks whether a beam tower's beam was actively projecting as of the previous combat
    /// frame. Compared each frame against "is it projecting now" to catch the precise
    /// off → on transition — "the laser starts heating" — that fires the one-shot ignition
    /// sound exactly once per lock-on rather than every frame the beam stays lit. Entries
    /// only exist for beam towers; cleared to `false` (not left stale) the instant the beam
    /// goes silent — lock lost, target killed, tower sold, scene reset — so the next
    /// lock-on always ignites fresh rather than staying silent on a stale "already on" flag.
    private var beamActiveByBuildSpotID: [Int: Bool] = [:]
    private var targetLocksByBuildSpotID: [Int: TargetLock] = [:]
    /// `currentTime` from the previous `updateCombat` call — used to derive `deltaTime` for
    /// beam-style towers, whose damage accrues continuously as `dps * deltaTime` rather than
    /// in discrete per-shot bursts. `nil` until the first frame after a (re)load.
    private var lastCombatUpdateTime: TimeInterval?
    private var selectedBuildSpotID: Int?
    var isSoundEnabled: Bool = true
    private var rangeIndicator: SKShapeNode?
    private var sellBadgeNode: SKNode?
    private let sellBadgeYOffset: CGFloat = -50
    /// Mirrors `sellBadgeNode`/`sellBadgeYOffset` exactly — same tap-to-act pattern, just
    /// for "spend coins to bump this tower's tier" instead of "sell it for a refund".
    /// Sits *above* the tower (positive offset) while the sell badge sits below, so both
    /// can be visible together without overlapping. Absent (not just hidden) once a tower
    /// reaches `TowerType.maxUpgradeLevel` — there's nothing left to buy.
    private var upgradeBadgeNode: SKNode?
    private let upgradeBadgeYOffset: CGFloat = 50

    func resetForNewScene() {
        clearSelection(animated: false)
        rangeIndicator?.removeFromParent()
        rangeIndicator = nil
        sellBadgeNode?.removeFromParent()
        sellBadgeNode = nil
        upgradeBadgeNode?.removeFromParent()
        upgradeBadgeNode = nil

        towersByBuildSpotID.values.forEach { tower in
            tower.reset()
        }
        towersByBuildSpotID.removeAll(keepingCapacity: true)
        nextAttackTimesByBuildSpotID.removeAll(keepingCapacity: true)
        beamActiveByBuildSpotID.removeAll(keepingCapacity: true)
        targetLocksByBuildSpotID.removeAll(keepingCapacity: true)
        lastCombatUpdateTime = nil
    }

    func placePlaceholderTower(ofType towerType: TowerType, on buildSpot: BuildSpot, in scene: SKScene) -> Bool {
        guard towersByBuildSpotID[buildSpot.id] == nil else {
            return false
        }

        let tower = PlaceholderTower(type: towerType)
        tower.node.position = buildSpot.position
        scene.addChild(tower.node)
        towersByBuildSpotID[buildSpot.id] = tower
        nextAttackTimesByBuildSpotID[buildSpot.id] = 0
        return true
    }

    func selectTower(containing point: CGPoint, in scene: SKScene) -> Bool {
        guard let selection = tower(containing: point) else {
            return false
        }

        selectTower(withBuildSpotID: selection.buildSpotID, tower: selection.tower, in: scene)
        return true
    }

    func clearSelection(animated: Bool = true) {
        if let selectedBuildSpotID, let selectedTower = towersByBuildSpotID[selectedBuildSpotID] {
            selectedTower.setSelected(false, animated: animated)
        }

        selectedBuildSpotID = nil
        rangeIndicator?.removeFromParent()
        hideSellBadge()
        hideUpgradeBadge()
    }

    // MARK: - Pause stats

    var towerCountsByType: [TowerType: Int] {
        towersByBuildSpotID.values.reduce(into: [:]) { counts, tower in
            counts[tower.type, default: 0] += 1
        }
    }

    var totalCoinsInvested: Int {
        towersByBuildSpotID.values.reduce(0) { total, tower in
            total + tower.type.totalInvestedCost(atUpgradeLevel: tower.upgradeLevel)
        }
    }

    /// Removes the selected tower, frees its dictionaries, clears selection, and returns the
    /// build spot id and refund amount so the caller can credit the economy and free the build spot.
    /// Returns nil if no tower is currently selected.
    func sellSelectedTower(in scene: SKScene) -> (buildSpotID: Int, refund: Int)? {
        guard let buildSpotID = selectedBuildSpotID,
              let tower = towersByBuildSpotID[buildSpotID] else {
            return nil
        }

        let refund = tower.type.sellRefund(atUpgradeLevel: tower.upgradeLevel)
        tower.node.removeFromParent()
        towersByBuildSpotID[buildSpotID] = nil
        nextAttackTimesByBuildSpotID[buildSpotID] = nil
        beamActiveByBuildSpotID[buildSpotID] = nil
        targetLocksByBuildSpotID[buildSpotID] = nil
        clearSelection(animated: false)
        return (buildSpotID, refund)
    }

    func updateCombat(
        currentTime: TimeInterval,
        enemyManager: EnemyManager,
        projectileManager: ProjectileManager,
        economyManager: EconomyManager,
        uiManager: UIManager,
        pathEndPoint: CGPoint,
        in scene: SKScene
    ) {
        let deltaTime = lastCombatUpdateTime.map { max(0, currentTime - $0) } ?? 0
        lastCombatUpdateTime = currentTime

        towersByBuildSpotID.forEach { buildSpotID, tower in
            // Mortar towers don't lock a single target or fire straight shots — they pick the
            // leading enemy each volley and lob an exploding shell onto its predicted road
            // position. Handled entirely in its own branch, bypassing the lock/beam logic below.
            if tower.type.projectileBehavior == .mortar {
                updateMortarCombat(
                    buildSpotID: buildSpotID,
                    tower: tower,
                    currentTime: currentTime,
                    deltaTime: deltaTime,
                    enemyManager: enemyManager,
                    projectileManager: projectileManager,
                    economyManager: economyManager,
                    uiManager: uiManager,
                    pathEndPoint: pathEndPoint,
                    in: scene
                )
                return
            }

            let isBeamTower = tower.type.attackStyle == .beam
            // Captured *before* refreshing the lock below — `targetLock(forBuildSpotID:...)`
            // silently swaps in a fresh target the instant the old one becomes invalid (dies,
            // leaves range, etc.), so this is our only chance to know who the beam was just
            // resting on, in order to switch its burn effect off down in the branches below.
            let previousBeamTarget = isBeamTower ? targetLocksByBuildSpotID[buildSpotID]?.enemy : nil

            guard let targetLock = targetLock(
                forBuildSpotID: buildSpotID,
                tower: tower,
                enemyManager: enemyManager
            ), let target = targetLock.enemy else {
                tower.hideBeam()
                previousBeamTarget?.hideBeamBurn()
                // Beam fell silent (lock lost / no target in range) — mark it inactive so
                // the *next* lock-on fires the ignition sound fresh rather than staying
                // silent because it thinks the beam never stopped. No-op for projectile
                // towers, which never populate this dictionary in the first place.
                beamActiveByBuildSpotID[buildSpotID] = false
                return
            }

            let targetPosition = target.node.position
            tower.aim(at: targetPosition, deltaTime: deltaTime)

            if isBeamTower {
                // The lock can only have moved on to a *different* enemy in the same tick the
                // old one became invalid (dead/out-of-range/etc) — `target.hideBeamBurn()` in
                // `updateBeamCombat`'s kill branch already covers the "died" case, so this
                // catches the remaining "still alive but no longer locked" cases (e.g. walked
                // out of beam range) before the new target's burn lights up below.
                if let previousBeamTarget, previousBeamTarget !== target {
                    previousBeamTarget.hideBeamBurn()
                }

                updateBeamCombat(
                    buildSpotID: buildSpotID,
                    tower: tower,
                    target: target,
                    targetPosition: targetPosition,
                    targetLock: targetLock,
                    deltaTime: deltaTime,
                    enemyManager: enemyManager,
                    economyManager: economyManager,
                    uiManager: uiManager,
                    scene: scene
                )
                return
            }

            let nextAttackTime = nextAttackTimesByBuildSpotID[buildSpotID] ?? 0

            guard currentTime >= nextAttackTime else {
                return
            }

            nextAttackTimesByBuildSpotID[buildSpotID] = currentTime + tower.type.attackCooldown
            tower.playFireEffects()
            if isSoundEnabled {
                tower.node.run(SKAction.playSoundFileNamed(tower.type.shootSound, waitForCompletion: false))
            }

            let killReward = target.killReward
            let towerDamage = tower.currentDamage

            // For predictive-aiming towers (Blue), fire at the enemy's projected intercept position.
            let firePosition: CGPoint
            if tower.type.usesPredictiveAiming,
               let intercept = predictedImpactPoint(
                   enemyPosition: target.node.position,
                   enemyVelocity: target.velocity,
                   shooterPosition: tower.barrelTipPosition,
                   projectileSpeed: tower.type.projectileSpeed
               ) {
                firePosition = intercept
            } else {
                firePosition = targetPosition
            }

            let spawnOrigin = tower.barrelTipPosition
            projectileManager.firePlaceholderProjectile(
                from: spawnOrigin,
                to: firePosition,
                behavior: tower.type.projectileBehavior,
                color: tower.type.projectileColor,
                radius: tower.type.projectileRadius,
                style: tower.type.projectileVisualStyle,
                speed: tower.type.projectileSpeed,
                targetPositionProvider: { [weak enemyManager, weak target] in
                    // Range is NOT checked here — in-flight homing missiles chase their
                    // target until impact regardless of the tower's attack range.
                    guard let enemyManager, let target else {
                        return nil
                    }

                    guard enemyManager.isTrackedAndAlive(target, lifeID: targetLock.lifeID) else {
                        return nil
                    }

                    return target.node.position
                },
                in: scene
            ) { [weak self, weak enemyManager, weak economyManager, weak uiManager, weak scene, weak target, weak tower] in
                guard let target else {
                    return
                }

                // Capture the death spot before applyDamage recycles (and repositions) the enemy.
                let deathPosition = target.node.position
                let killed = enemyManager?.applyDamage(towerDamage, to: target, matchingLifeID: targetLock.lifeID) ?? false

                if killed {
                    economyManager?.credit(killReward)
                    if let uiManager, let scene {
                        uiManager.flyCoinReward(from: deathPosition, in: scene)
                    }
                    if self?.isSoundEnabled == true {
                        tower?.node.run(SKAction.playSoundFileNamed("enemy_death.wav", waitForCompletion: false))
                    }
                } else if self?.isSoundEnabled == true {
                    tower?.node.run(SKAction.playSoundFileNamed("enemy_hit.wav", waitForCompletion: false))
                }
            }
        }
    }

    /// Drives one frame of mortar combat: tracks its committed target with the tube, and on
    /// each reload lobs an exploding shell onto where that enemy will be standing when the
    /// shell lands (current position + velocity × flight time). On impact, splash damage hits
    /// every enemy within the blast radius, each kill is credited + coin-flown, and the
    /// artillery boom plays *with the explosion* (not the launch) so the sound lands on the hit.
    private func updateMortarCombat(
        buildSpotID: Int,
        tower: PlaceholderTower,
        currentTime: TimeInterval,
        deltaTime: TimeInterval,
        enemyManager: EnemyManager,
        projectileManager: ProjectileManager,
        economyManager: EconomyManager,
        uiManager: UIManager,
        pathEndPoint: CGPoint,
        in scene: SKScene
    ) {
        // Commit to one target: keep shelling the locked enemy while it remains targetable
        // and in range; only when it dies, breaches, dives into the tunnel, or leaves range
        // does the mortar re-evaluate the front of the advance. (Re-picking the lead enemy
        // every frame made the heavy tube whip around whenever the lead changed — committing
        // gives it the deliberate, sluggish character a mortar should have.)
        let target: PlaceholderEnemy
        if let lock = targetLocksByBuildSpotID[buildSpotID],
           let lockedEnemy = lock.enemy,
           enemyManager.isValidTarget(lockedEnemy, lifeID: lock.lifeID, from: tower.node.position, within: tower.type.range) {
            target = lockedEnemy
        } else if let lead = enemyManager.leadEnemy(
            within: tower.type.range,
            from: tower.node.position,
            towardEnd: pathEndPoint
        ) {
            // Bombard the front of the advance, not whatever's nearest the tower.
            target = lead
            targetLocksByBuildSpotID[buildSpotID] = TargetLock(enemy: lead, lifeID: lead.lifeID)
        } else {
            targetLocksByBuildSpotID[buildSpotID] = nil
            return
        }

        // Predicted landing point: where the locked enemy will be when the shell touches down.
        let flightDuration = tower.type.mortarFlightDuration
        let landingPoint = CGPoint(
            x: target.node.position.x + target.velocity.x * CGFloat(flightDuration),
            y: target.node.position.y + target.velocity.y * CGFloat(flightDuration)
        )

        // Keep the tube traversing toward the landing bearing even while reloading — at the
        // Mortar's heavy `traverseSpeed`, so it visibly labors to come about.
        tower.aim(at: landingPoint, deltaTime: deltaTime)

        let nextAttackTime = nextAttackTimesByBuildSpotID[buildSpotID] ?? 0
        guard currentTime >= nextAttackTime else {
            return
        }

        nextAttackTimesByBuildSpotID[buildSpotID] = currentTime + tower.type.attackCooldown
        tower.playFireEffects()

        let splashDamage = tower.currentDamage
        let splashRadius = tower.type.splashRadius

        projectileManager.fireMortarShell(
            from: tower.barrelTipPosition,
            to: landingPoint,
            color: tower.type.projectileColor,
            radius: tower.type.projectileRadius,
            flightDuration: flightDuration,
            peakHeight: 70,
            explosionRadius: splashRadius,
            in: scene
        ) { [weak self, weak enemyManager, weak economyManager, weak uiManager, weak scene] in
            guard let enemyManager else { return }

            let kills = enemyManager.applyAreaDamage(splashDamage, at: landingPoint, radius: splashRadius)
            for kill in kills {
                economyManager?.credit(kill.reward)
                if let uiManager, let scene {
                    uiManager.flyCoinReward(from: kill.position, in: scene)
                }
            }

            if self?.isSoundEnabled == true, let scene {
                scene.run(SKAction.playSoundFileNamed("tower_shoot_blue.wav", waitForCompletion: false))
            }
        }
    }

    /// Drives one frame of continuous-beam combat for a locked-on laser tower: keeps the
    /// beam visual drawn from barrel tip to the target, drains the target's HP smoothly
    /// via fractional, deltaTime-scaled damage (see `PlaceholderEnemy.takeContinuousDamage`),
    /// and fires the one-shot "ignition" sound at the instant the beam first lights up.
    private func updateBeamCombat(
        buildSpotID: Int,
        tower: PlaceholderTower,
        target: PlaceholderEnemy,
        targetPosition: CGPoint,
        targetLock: TargetLock,
        deltaTime: TimeInterval,
        enemyManager: EnemyManager,
        economyManager: EconomyManager,
        uiManager: UIManager,
        scene: SKScene
    ) {
        tower.showBeam(to: targetPosition, color: tower.type.projectileColor)
        target.showBeamBurn(color: tower.type.projectileColor)
        triggerLaserIgnition(buildSpotID: buildSpotID, tower: tower)

        guard deltaTime > 0 else {
            return
        }

        let damageThisTick = tower.currentDPS * deltaTime
        let killReward = target.killReward
        let deathPosition = target.node.position

        let killed = enemyManager.applyContinuousDamage(damageThisTick, to: target, matchingLifeID: targetLock.lifeID)

        if killed {
            economyManager.credit(killReward)
            uiManager.flyCoinReward(from: deathPosition, in: scene)
            tower.hideBeam()
            target.hideBeamBurn()
            // Beam just went silent — mark it inactive so the next lock-on (a fresh target
            // acquired next frame, or a future one) ignites fresh rather than staying mute.
            beamActiveByBuildSpotID[buildSpotID] = false
            if isSoundEnabled {
                tower.node.run(SKAction.playSoundFileNamed("enemy_death.wav", waitForCompletion: false))
            }
        }
    }

    /// Fires a beam tower's one-shot "ignition" sound at the precise instant its beam
    /// transitions from off to on — "the laser starts heating" — and never again while
    /// that same lock holds. `beamActiveByBuildSpotID` is the off/on memory that makes the
    /// transition detectable: this only plays when the build spot's last-known state was
    /// "not active" (absent, the first time, or explicitly `false` after the beam went
    /// silent). The actual playback is the same fire-and-forget `playSoundFileNamed`
    /// mechanism every other tower sound uses (mirrors the regular shot-sound trigger in
    /// `updateCombat`) — beam towers just hang it on a state transition instead of a
    /// cooldown. `nil` `laserStartSound` (i.e. every non-beam type) makes this a no-op.
    private func triggerLaserIgnition(buildSpotID: Int, tower: PlaceholderTower) {
        guard let soundFile = tower.type.laserStartSound else {
            return
        }

        guard beamActiveByBuildSpotID[buildSpotID] != true else {
            return
        }

        beamActiveByBuildSpotID[buildSpotID] = true
        if isSoundEnabled {
            tower.node.run(SKAction.playSoundFileNamed(soundFile, waitForCompletion: false))
        }
    }

    private func targetLock(
        forBuildSpotID buildSpotID: Int,
        tower: PlaceholderTower,
        enemyManager: EnemyManager
    ) -> TargetLock? {
        if let currentTargetLock = targetLocksByBuildSpotID[buildSpotID],
           let currentTarget = currentTargetLock.enemy,
           enemyManager.isValidTarget(
               currentTarget,
               lifeID: currentTargetLock.lifeID,
               from: tower.node.position,
               within: placeholderAttackRange
           ) {
            return currentTargetLock
        }

        targetLocksByBuildSpotID[buildSpotID] = nil

        guard let target = enemyManager.nearestEnemy(to: tower.node.position, within: placeholderAttackRange) else {
            return nil
        }

        let targetLock = TargetLock(enemy: target, lifeID: target.lifeID)
        targetLocksByBuildSpotID[buildSpotID] = targetLock
        return targetLock
    }

    private func selectTower(withBuildSpotID buildSpotID: Int, tower: PlaceholderTower, in scene: SKScene) {
        if selectedBuildSpotID == buildSpotID {
            moveRangeIndicator(to: tower.node.position, in: scene)
            return
        }

        if let selectedBuildSpotID, let selectedTower = towersByBuildSpotID[selectedBuildSpotID] {
            selectedTower.setSelected(false, animated: true)
        }

        hideSellBadge()
        hideUpgradeBadge()
        selectedBuildSpotID = buildSpotID
        tower.setSelected(true, animated: true)
        moveRangeIndicator(to: tower.node.position, in: scene)
        showSellBadge(for: tower, in: scene)
        showUpgradeBadge(for: tower, in: scene)
    }

    /// Spends coins to bump the selected tower up one tier and refreshes its visuals —
    /// tier pips on the tower itself plus the badge (its cost changes, or it disappears
    /// entirely once the tower hits `TowerType.maxUpgradeLevel`). Returns `false` (and
    /// changes nothing) if no tower is selected, it's already maxed, or the player can't
    /// afford the next tier — mirrors `sellSelectedTower`'s "do it, or report that you
    /// can't" shape. Takes `economyManager` directly (as `updateCombat` already does)
    /// rather than round-tripping the cost through `GameScene`, since only this tower's
    /// own state determines what its next tier actually costs.
    @discardableResult
    func upgradeSelectedTower(economyManager: EconomyManager, in scene: SKScene) -> Bool {
        guard let buildSpotID = selectedBuildSpotID,
              let tower = towersByBuildSpotID[buildSpotID],
              let cost = tower.type.upgradeCost(fromLevel: tower.upgradeLevel),
              economyManager.canAfford(cost) else {
            return false
        }

        economyManager.spend(cost)
        tower.upgrade()

        // Rebuild in place — the badge's cost (or its very existence, if this was the
        // last affordable tier) just changed.
        hideUpgradeBadge()
        showUpgradeBadge(for: tower, in: scene)
        return true
    }

    private func showSellBadge(for tower: PlaceholderTower, in scene: SKScene) {
        let badge = makeSellBadgeNode(refund: tower.type.sellRefund(atUpgradeLevel: tower.upgradeLevel))
        badge.position = CGPoint(
            x: tower.node.position.x,
            y: tower.node.position.y + sellBadgeYOffset
        )
        scene.addChild(badge)
        sellBadgeNode = badge
    }

    private func hideSellBadge() {
        sellBadgeNode?.removeFromParent()
        sellBadgeNode = nil
    }

    /// Mirrors `showSellBadge` exactly, positioned above the tower instead of below.
    /// Stays absent (not just hidden) once the tower is already at `TowerType.maxUpgradeLevel`
    /// — `upgradeCost(fromLevel:)` returns `nil` there, so there's nothing to show or buy.
    private func showUpgradeBadge(for tower: PlaceholderTower, in scene: SKScene) {
        guard let cost = tower.type.upgradeCost(fromLevel: tower.upgradeLevel) else {
            return
        }

        let badge = makeUpgradeBadgeNode(cost: cost)
        badge.position = CGPoint(
            x: tower.node.position.x,
            y: tower.node.position.y + upgradeBadgeYOffset
        )
        scene.addChild(badge)
        upgradeBadgeNode = badge
    }

    private func hideUpgradeBadge() {
        upgradeBadgeNode?.removeFromParent()
        upgradeBadgeNode = nil
    }

    private func makeSellBadgeNode(refund: Int) -> SKNode {
        let root = SKNode()
        root.name = "SellBadge"
        root.zPosition = 33

        // Dark pill background
        let pill = SKShapeNode(rectOf: CGSize(width: 68, height: 28), cornerRadius: 14)
        pill.name = "SellBadge"
        pill.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.12, alpha: 0.90)
        pill.strokeColor = SKColor(red: 0.98, green: 0.80, blue: 0.12, alpha: 0.80)
        pill.lineWidth = 1.5
        root.addChild(pill)

        // Coin icon — filled yellow circle (matches HUD coin cluster, slightly smaller)
        let coinIcon = SKShapeNode(circleOfRadius: 7)
        coinIcon.name = "SellBadge"
        coinIcon.fillColor = SKColor(red: 0.98, green: 0.80, blue: 0.12, alpha: 1.0)
        coinIcon.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 1.0)
        coinIcon.lineWidth = 1
        coinIcon.position = CGPoint(x: -16, y: 0)
        root.addChild(coinIcon)

        // Inner coin detail ring
        let innerRing = SKShapeNode(circleOfRadius: 3.5)
        innerRing.name = "SellBadge"
        innerRing.fillColor = .clear
        innerRing.strokeColor = SKColor(red: 0.72, green: 0.56, blue: 0.06, alpha: 0.55)
        innerRing.lineWidth = 1
        innerRing.position = CGPoint(x: -16, y: 0)
        root.addChild(innerRing)

        // Refund amount label
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.name = "SellBadge"
        label.text = "\(refund)"
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.98, green: 0.90, blue: 0.60, alpha: 1.0)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -6, y: 0)
        root.addChild(label)

        return root
    }

    /// Mirrors `makeSellBadgeNode`'s pill/icon/label structure exactly — same shape, same
    /// dark fill, same font and label layout — but recolored from the sell badge's
    /// "cash-out gold" to a glowing cyan "spend to power up" accent, and swaps the coin
    /// icon for an up-chevron (this badge *costs* coins rather than refunding them, and
    /// makes the tower stronger rather than removing it). Position above vs. below the
    /// tower is the other half of the differentiation — together they read unambiguously
    /// even at a glance, without needing more visual noise crammed into a 68×28 pill.
    private func makeUpgradeBadgeNode(cost: Int) -> SKNode {
        let root = SKNode()
        root.name = "UpgradeBadge"
        root.zPosition = 33

        let accent = SKColor(red: 0.30, green: 0.86, blue: 0.98, alpha: 1.0)

        let pill = SKShapeNode(rectOf: CGSize(width: 68, height: 28), cornerRadius: 14)
        pill.name = "UpgradeBadge"
        pill.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.12, alpha: 0.90)
        pill.strokeColor = accent.withAlphaComponent(0.80)
        pill.lineWidth = 1.5
        root.addChild(pill)

        // Up-chevron — "this makes the tower better" — replaces the sell badge's coin
        // icon, since this badge represents added power, not cash returned to hand.
        let chevron = SKShapeNode(path: Self.upChevronPath())
        chevron.name = "UpgradeBadge"
        chevron.strokeColor = accent
        chevron.lineWidth = 2.4
        chevron.lineCap = .round
        chevron.lineJoin = .round
        chevron.fillColor = .clear
        chevron.position = CGPoint(x: -16, y: 0)
        root.addChild(chevron)

        // Cost label — what tapping this badge will spend.
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.name = "UpgradeBadge"
        label.text = "\(cost)"
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.80, green: 0.96, blue: 1.0, alpha: 1.0)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -6, y: 0)
        root.addChild(label)

        return root
    }

    /// A simple upward chevron ("^") — three hand-plotted points, no curve math needed at
    /// this size. Mirrors `PlaceholderTower`'s `radialArcPath`/`polygonPath` philosophy of
    /// building small custom shapes directly rather than reaching for image assets.
    private static func upChevronPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: -2.5))
        path.addLine(to: CGPoint(x: 0, y: 2.5))
        path.addLine(to: CGPoint(x: 4, y: -2.5))
        return path
    }

    private func moveRangeIndicator(to position: CGPoint, in scene: SKScene) {
        let indicator = makeRangeIndicator()
        indicator.position = position

        if indicator.parent == nil {
            scene.addChild(indicator)
        }
    }

    private func makeRangeIndicator() -> SKShapeNode {
        if let rangeIndicator {
            return rangeIndicator
        }

        let indicator = SKShapeNode(circleOfRadius: placeholderAttackRange)
        indicator.name = "TowerRangeIndicator"
        indicator.fillColor = .clear
        indicator.strokeColor = SKColor(white: 1.0, alpha: 0.34)
        indicator.lineWidth = 2
        indicator.zPosition = 13
        rangeIndicator = indicator
        return indicator
    }

    /// Solves for the earliest positive intercept time `t` where a projectile traveling at
    /// `projectileSpeed` can meet an enemy at `enemyPosition + enemyVelocity * t`.
    /// Returns nil if no valid intercept exists (e.g. enemy is faster than the projectile).
    private func predictedImpactPoint(
        enemyPosition: CGPoint,
        enemyVelocity: CGPoint,
        shooterPosition: CGPoint,
        projectileSpeed: CGFloat
    ) -> CGPoint? {
        let rpx = enemyPosition.x - shooterPosition.x
        let rpy = enemyPosition.y - shooterPosition.y
        let evx = enemyVelocity.x
        let evy = enemyVelocity.y

        let a = evx * evx + evy * evy - projectileSpeed * projectileSpeed
        let b = 2 * (rpx * evx + rpy * evy)
        let c = rpx * rpx + rpy * rpy

        let t: CGFloat

        if abs(a) < 0.01 {
            guard abs(b) > 0.01 else { return nil }
            let candidate = -c / b
            guard candidate > 0 else { return nil }
            t = candidate
        } else {
            let discriminant = b * b - 4 * a * c
            guard discriminant >= 0 else { return nil }
            let sqrtD = sqrt(discriminant)
            let t1 = (-b - sqrtD) / (2 * a)
            let t2 = (-b + sqrtD) / (2 * a)
            if t1 > 0 && t2 > 0 {
                t = min(t1, t2)
            } else if t1 > 0 {
                t = t1
            } else if t2 > 0 {
                t = t2
            } else {
                return nil
            }
        }

        return CGPoint(
            x: enemyPosition.x + enemyVelocity.x * t,
            y: enemyPosition.y + enemyVelocity.y * t
        )
    }

    private func tower(containing point: CGPoint) -> (buildSpotID: Int, tower: PlaceholderTower)? {
        towersByBuildSpotID
            .filter { _, tower in
                tower.node.position.distance(to: point) <= 32
            }
            .min { first, second in
                first.value.node.position.distance(to: point) < second.value.node.position.distance(to: point)
            }
            .map { buildSpotID, tower in
                (buildSpotID, tower)
            }
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
