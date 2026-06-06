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
    private var targetLocksByBuildSpotID: [Int: TargetLock] = [:]
    private var selectedBuildSpotID: Int?
    private var rangeIndicator: SKShapeNode?
    private var sellBadgeNode: SKNode?
    private let sellBadgeYOffset: CGFloat = -50

    func resetForNewScene() {
        clearSelection(animated: false)
        rangeIndicator?.removeFromParent()
        rangeIndicator = nil
        sellBadgeNode?.removeFromParent()
        sellBadgeNode = nil

        towersByBuildSpotID.values.forEach { tower in
            tower.reset()
        }
        towersByBuildSpotID.removeAll(keepingCapacity: true)
        nextAttackTimesByBuildSpotID.removeAll(keepingCapacity: true)
        targetLocksByBuildSpotID.removeAll(keepingCapacity: true)
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
    }

    /// Removes the selected tower, frees its dictionaries, clears selection, and returns the
    /// build spot id and refund amount so the caller can credit the economy and free the build spot.
    /// Returns nil if no tower is currently selected.
    func sellSelectedTower(in scene: SKScene) -> (buildSpotID: Int, refund: Int)? {
        guard let buildSpotID = selectedBuildSpotID,
              let tower = towersByBuildSpotID[buildSpotID] else {
            return nil
        }

        let refund = tower.type.sellRefund
        tower.node.removeFromParent()
        towersByBuildSpotID[buildSpotID] = nil
        nextAttackTimesByBuildSpotID[buildSpotID] = nil
        targetLocksByBuildSpotID[buildSpotID] = nil
        clearSelection(animated: false)
        return (buildSpotID, refund)
    }

    func updateCombat(
        currentTime: TimeInterval,
        enemyManager: EnemyManager,
        projectileManager: ProjectileManager,
        economyManager: EconomyManager,
        in scene: SKScene
    ) {
        towersByBuildSpotID.forEach { buildSpotID, tower in
            guard let targetLock = targetLock(
                forBuildSpotID: buildSpotID,
                tower: tower,
                enemyManager: enemyManager
            ), let target = targetLock.enemy else {
                return
            }

            let targetPosition = target.node.position
            tower.aim(at: targetPosition)

            let nextAttackTime = nextAttackTimesByBuildSpotID[buildSpotID] ?? 0

            guard currentTime >= nextAttackTime else {
                return
            }

            nextAttackTimesByBuildSpotID[buildSpotID] = currentTime + tower.type.attackCooldown

            let killReward = target.killReward
            let towerDamage = tower.type.damage

            // For predictive-aiming towers (Blue), fire at the enemy's projected intercept position.
            let firePosition: CGPoint
            if tower.type.usesPredictiveAiming,
               let intercept = predictedImpactPoint(
                   enemyPosition: target.node.position,
                   enemyVelocity: target.velocity,
                   shooterPosition: tower.node.position,
                   projectileSpeed: tower.type.projectileSpeed
               ) {
                firePosition = intercept
            } else {
                firePosition = targetPosition
            }

            projectileManager.firePlaceholderProjectile(
                from: tower.node.position,
                to: firePosition,
                behavior: tower.type.projectileBehavior,
                color: tower.type.projectileColor,
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
            ) { [weak enemyManager, weak economyManager, weak target] in
                guard let target else {
                    return
                }

                let killed = enemyManager?.applyDamage(towerDamage, to: target, matchingLifeID: targetLock.lifeID) ?? false

                if killed {
                    economyManager?.credit(killReward)
                }
            }
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
        selectedBuildSpotID = buildSpotID
        tower.setSelected(true, animated: true)
        moveRangeIndicator(to: tower.node.position, in: scene)
        showSellBadge(for: tower, in: scene)
    }

    private func showSellBadge(for tower: PlaceholderTower, in scene: SKScene) {
        let badge = makeSellBadgeNode(refund: tower.type.sellRefund)
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
