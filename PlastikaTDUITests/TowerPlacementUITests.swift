import CoreGraphics
import ImageIO
import XCTest

private enum TestTowerOption {
    case red
    case green
    case blue
}

final class TowerPlacementUITests: XCTestCase {
    private let sceneWidth: CGFloat = 390
    private let sceneHeight: CGFloat = 844
    private let menuYOffset: CGFloat = 54
    private let menuOptionSpacing: CGFloat = 52

    // Normalized coordinates for the serpentine layout's build spots (scene 390×844,
    // normalized dx = x/390, dy = (844 - y)/844). Spots chosen so each test's pixel-count
    // windows stay over grass — away from road lanes (where enemy hulls can pollute color
    // counts) and from scenery. The "middle" spot (id 5, above the tunnel lane) is special:
    // its build menu opens over the buried stretch, where enemies are invisible.

    func testTapBuildSpotPlacesOnePlaceholderTowerOnlyOnce() {
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot = CGVector(dx: 0.628, dy: 0.275)   // spot id 7 (245, 612)
        let emptyBattlefield = CGVector(dx: 0.50, dy: 0.88)
        let tapTarget = app.coordinate(withNormalizedOffset: topRightBuildSpot)

        let baselineTowerPixels = countRedTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        tapTarget.tap()

        let afterMenuTapPixels = countRedTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        app.coordinate(withNormalizedOffset: menuOption(for: topRightBuildSpot, option: .red)).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let afterPlacementPixels = countRedTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        tapTarget.tap()
        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let afterSecondTapPixels = countRedTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        XCTAssertLessThan(baselineTowerPixels, 120)
        XCTAssertLessThanOrEqual(abs(afterMenuTapPixels - baselineTowerPixels), 150)
        XCTAssertGreaterThan(afterPlacementPixels, baselineTowerPixels + 500)
        XCTAssertLessThanOrEqual(abs(afterSecondTapPixels - afterPlacementPixels), 150)
    }

    func testBuildSpotMenuShowsMovesHidesAndPlacesTypedTowers() {
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot = CGVector(dx: 0.628, dy: 0.275)     // spot id 7 (245, 612)
        let middleRightBuildSpot = CGVector(dx: 0.628, dy: 0.429)  // spot id 5 (245, 482)
        let lowerRightBuildSpot = CGVector(dx: 0.628, dy: 0.725)   // spot id 1 (245, 232)
        let emptyBattlefield = CGVector(dx: 0.50, dy: 0.88)

        app.coordinate(withNormalizedOffset: topRightBuildSpot).tap()

        var menuScreenshot = XCUIScreen.main.screenshot()
        let topRedOptionPixels = countRedTowerPixels(in: menuScreenshot, near: menuOption(for: topRightBuildSpot, option: .red))
        let topGreenOptionPixels = countGreenTowerPixels(in: menuScreenshot, near: menuOption(for: topRightBuildSpot, option: .green))
        let topBlueOptionPixels = countBlueTowerPixels(in: menuScreenshot, near: menuOption(for: topRightBuildSpot, option: .blue))

        XCTAssertGreaterThan(topRedOptionPixels, 200)
        XCTAssertGreaterThan(topGreenOptionPixels, 200)
        XCTAssertGreaterThan(topBlueOptionPixels, 200)

        app.coordinate(withNormalizedOffset: middleRightBuildSpot).tap()

        menuScreenshot = XCUIScreen.main.screenshot()
        let movedTopRedOptionPixels = countRedTowerPixels(in: menuScreenshot, near: menuOption(for: topRightBuildSpot, option: .red))
        let middleRedOptionPixels = countRedTowerPixels(in: menuScreenshot, near: menuOption(for: middleRightBuildSpot, option: .red))

        XCTAssertLessThan(movedTopRedOptionPixels, topRedOptionPixels - 100)
        XCTAssertGreaterThan(middleRedOptionPixels, 200)

        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()

        let hiddenMenuScreenshot = XCUIScreen.main.screenshot()
        let hiddenMiddleRedOptionPixels = countRedTowerPixels(in: hiddenMenuScreenshot, near: menuOption(for: middleRightBuildSpot, option: .red))

        XCTAssertLessThan(hiddenMiddleRedOptionPixels, middleRedOptionPixels - 100)

        placeTower(app, at: topRightBuildSpot, option: .red)
        placeTower(app, at: middleRightBuildSpot, option: .green)
        placeTower(app, at: lowerRightBuildSpot, option: .blue)

        let typedTowers = XCUIScreen.main.screenshot()
        let redTowerPixels = countRedTowerPixels(in: typedTowers, near: topRightBuildSpot)
        let greenTowerPixels = countGreenTowerPixels(in: typedTowers, near: middleRightBuildSpot)
        let blueTowerPixels = countBlueTowerPixels(in: typedTowers, near: lowerRightBuildSpot)

        XCTAssertGreaterThan(redTowerPixels, 500)
        XCTAssertGreaterThan(greenTowerPixels, 500)
        XCTAssertGreaterThan(blueTowerPixels, 500)
    }

    func testPlacedTowerFiresProjectilesAndDestroysEnemies() {
        let app = XCUIApplication()
        app.launch()

        let earlyBuildSpot = CGVector(dx: 0.308, dy: 0.725)   // spot id 0 (120, 232)
        placeTower(app, at: earlyBuildSpot, option: .green)

        // Missiles in flight and their impact flashes make the screen's lime pixel count
        // fluctuate sharply from frame to frame, while a silent battlefield holds it nearly
        // constant (the tower's own static lime pixels cancel out). Sampling over ~4s and
        // asserting real variance avoids racing the tower's fire cycle — a single "baseline"
        // screenshot can accidentally catch a missile or flash already mid-flight.
        var projectileSamples: [Int] = []

        for _ in 0..<16 {
            Thread.sleep(forTimeInterval: 0.25)

            projectileSamples.append(countPixels(in: XCUIScreen.main.screenshot()) { red, green, blue in
                isProjectilePixel(red: red, green: green, blue: blue)
            })
        }

        let sawProjectile = (projectileSamples.max() ?? 0) - (projectileSamples.min() ?? 0) > 16
        XCTAssertTrue(sawProjectile)

        // Reinforce with the remaining 100 coins (another Missile Pod and a Mortar — never
        // Red, whose deep-red livery itself matches isEnemyPixel) so wave 1 reliably dies
        // on the battlefield instead of draining lives toward a DEFEAT overlay.
        placeTower(app, at: CGVector(dx: 0.628, dy: 0.725), option: .green)  // spot id 1
        placeTower(app, at: CGVector(dx: 0.628, dy: 0.573), option: .blue)   // spot id 3

        // The serpentine path takes ~19s to traverse, and the field only fully clears in the
        // brief gap between wave 1 dying and the larger wave 2 spawning — so poll for a clean
        // frame over a generous window rather than sleeping a fixed interval. Under full-suite
        // load each screenshot is slower (fewer game-seconds elapse per iteration), so the
        // window is sized with margin to reliably catch that inter-wave gap. The scan covers
        // the table but excludes the top HUD bar, whose red hearts match this deep-red predicate.
        var sawClearField = false

        for _ in 0..<70 {
            Thread.sleep(forTimeInterval: 0.5)

            let remainingEnemyPixels = countPixels(
                in: XCUIScreen.main.screenshot(),
                around: CGVector(dx: 0.5, dy: 0.55),
                xOffsetRange: -0.5...0.5,
                yOffsetRange: -0.42...0.44
            ) { red, green, blue in
                isEnemyPixel(red: red, green: green, blue: blue)
            }

            if remainingEnemyPixels < 500 {
                sawClearField = true
                break
            }
        }

        XCTAssertTrue(sawClearField)
    }

    func testPlacedTowerAimsBarrelTowardLockedTarget() {
        let app = XCUIApplication()
        app.launch()

        // Spot id 0 (120, 232): for the first ~7s of wave 1, the furthest-along enemy in
        // range is always to this spot's RIGHT — on the first lane's right stretch, the
        // right-side climb, or the second lane's right half — so the mortar tube should
        // traverse rightward, never left. The sleep covers the Mortar's deliberately slow
        // traverse (1.8 rad/s — about a second to come about from its initial upward facing).
        let earlyBuildSpot = CGVector(dx: 0.308, dy: 0.725)
        placeTower(app, at: earlyBuildSpot, option: .blue)
        Thread.sleep(forTimeInterval: 1.3)

        let aimedTower = XCUIScreen.main.screenshot()
        let rightBarrelPixels = countPixels(
            in: aimedTower,
            around: earlyBuildSpot,
            xOffsetRange: 0.02...0.08,
            yOffsetRange: -0.04...0.04
        ) { red, green, blue in
            isBarrelPixel(red: red, green: green, blue: blue)
        }
        let leftBarrelPixels = countPixels(
            in: aimedTower,
            around: earlyBuildSpot,
            xOffsetRange: -0.08 ... -0.02,
            yOffsetRange: -0.04...0.04
        ) { red, green, blue in
            isBarrelPixel(red: red, green: green, blue: blue)
        }

        XCTAssertGreaterThan(rightBarrelPixels, leftBarrelPixels + 30)
    }

    func testTowerSelectionShowsRangeSwitchesAndClears() {
        let app = XCUIApplication()
        app.launch()

        let firstTower = CGVector(dx: 0.628, dy: 0.275)         // spot id 7 (245, 612)
        let secondTower = CGVector(dx: 0.628, dy: 0.725)        // spot id 1 (245, 232)
        // Each sample sits on its tower's 175pt range circle, over grass in the tunnel's
        // quiet middle band (enemies there are underground and invisible, roads are unmarked).
        let firstRangeSample = CGVector(dx: 0.628, dy: 0.482)   // (245, 437) = id 7 - 175
        let secondRangeSample = CGVector(dx: 0.628, dy: 0.518)  // (245, 407) = id 1 + 175
        let emptyBattlefield = CGVector(dx: 0.50, dy: 0.88)

        placeTower(app, at: firstTower, option: .blue)
        placeTower(app, at: secondTower, option: .blue)

        let beforeSelection = XCUIScreen.main.screenshot()
        let beforeFirstHighlightPixels = countSelectionHighlightPixels(in: beforeSelection, near: firstTower)
        let beforeSecondHighlightPixels = countSelectionHighlightPixels(in: beforeSelection, near: secondTower)
        let beforeFirstRangeSamplePixels = countRangePixels(in: beforeSelection, near: firstRangeSample)
        let beforeSecondRangeSamplePixels = countRangePixels(in: beforeSelection, near: secondRangeSample)

        app.coordinate(withNormalizedOffset: firstTower).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let firstSelected = XCUIScreen.main.screenshot()
        let firstSelectedHighlightPixels = countSelectionHighlightPixels(in: firstSelected, near: firstTower)
        let firstSelectedRangeSamplePixels = countRangePixels(in: firstSelected, near: firstRangeSample)

        XCTAssertGreaterThan(firstSelectedHighlightPixels, beforeFirstHighlightPixels + 40)
        XCTAssertGreaterThan(firstSelectedRangeSamplePixels, beforeFirstRangeSamplePixels + 18)

        app.coordinate(withNormalizedOffset: secondTower).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let secondSelected = XCUIScreen.main.screenshot()
        let firstAfterSwitchHighlightPixels = countSelectionHighlightPixels(in: secondSelected, near: firstTower)
        let secondSelectedHighlightPixels = countSelectionHighlightPixels(in: secondSelected, near: secondTower)
        let firstAfterSwitchRangeSamplePixels = countRangePixels(in: secondSelected, near: firstRangeSample)
        let secondSelectedRangeSamplePixels = countRangePixels(in: secondSelected, near: secondRangeSample)

        XCTAssertLessThan(firstAfterSwitchHighlightPixels, firstSelectedHighlightPixels - 30)
        XCTAssertGreaterThan(secondSelectedHighlightPixels, beforeSecondHighlightPixels + 40)
        XCTAssertLessThan(firstAfterSwitchRangeSamplePixels, firstSelectedRangeSamplePixels)
        XCTAssertGreaterThan(secondSelectedRangeSamplePixels, beforeSecondRangeSamplePixels + 18)

        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let cleared = XCUIScreen.main.screenshot()
        let clearedSecondRangeSamplePixels = countRangePixels(in: cleared, near: secondRangeSample)
        let clearedSecondHighlightPixels = countSelectionHighlightPixels(in: cleared, near: secondTower)

        XCTAssertLessThan(clearedSecondRangeSamplePixels, secondSelectedRangeSamplePixels)
        XCTAssertLessThan(clearedSecondHighlightPixels, secondSelectedHighlightPixels - 30)
    }

    func testEconomyBlocksTowerPlacementWhenInsufficientFunds() {
        // Starting coins: 150. Each tower costs 50. After 3 placements the player is broke.
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot    = CGVector(dx: 0.628, dy: 0.275)  // spot id 7 (245, 612)
        let middleRightBuildSpot = CGVector(dx: 0.628, dy: 0.429)  // spot id 5 (245, 482)
        let lowerRightBuildSpot  = CGVector(dx: 0.628, dy: 0.725)  // spot id 1 (245, 232)
        let topLeftBuildSpot     = CGVector(dx: 0.308, dy: 0.275)  // spot id 6 (120, 612)
        let emptyBattlefield     = CGVector(dx: 0.50, dy: 0.88)

        // Spend all 150 coins.
        placeTower(app, at: topRightBuildSpot, option: .red)
        placeTower(app, at: middleRightBuildSpot, option: .red)
        placeTower(app, at: lowerRightBuildSpot, option: .red)

        // Tap an empty build spot to open the menu.
        app.coordinate(withNormalizedOffset: topLeftBuildSpot).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let beforePixels = countRedTowerPixels(in: XCUIScreen.main.screenshot(), near: topLeftBuildSpot)

        // Tap where the Red option would be — should be blocked (player is broke).
        app.coordinate(withNormalizedOffset: menuOption(for: topLeftBuildSpot, option: .red)).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let afterPixels = countRedTowerPixels(in: XCUIScreen.main.screenshot(), near: topLeftBuildSpot)

        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()

        // No new red tower should have appeared at this build spot.
        XCTAssertLessThanOrEqual(abs(afterPixels - beforePixels), 200)
    }

    private func placeTower(_ app: XCUIApplication, at buildSpot: CGVector, option: TestTowerOption) {
        app.coordinate(withNormalizedOffset: buildSpot).tap()
        Thread.sleep(forTimeInterval: 0.15)
        app.coordinate(withNormalizedOffset: menuOption(for: buildSpot, option: option)).tap()
        Thread.sleep(forTimeInterval: 0.25)
    }

    private func menuOption(for buildSpot: CGVector, option: TestTowerOption) -> CGVector {
        // Mirrors BuildSpotManager.menuOffset: all 4 tower types (Red/Green/Blue/Pink) are
        // spaced evenly and centered on the build spot, so with 4 options the offsets are
        // (index - 1.5) × spacing — Red -78, Green -26, Blue +26 (Pink +78, unused here).
        let towerTypeCount: CGFloat = 4
        let optionIndex: CGFloat

        switch option {
        case .red:
            optionIndex = 0
        case .green:
            optionIndex = 1
        case .blue:
            optionIndex = 2
        }

        let xOffset = (optionIndex - (towerTypeCount - 1) / 2) * menuOptionSpacing

        return CGVector(
            dx: buildSpot.dx + (xOffset / sceneWidth),
            dy: buildSpot.dy + (menuYOffset / sceneHeight)
        )
    }

    private func countRedTowerPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isRedTowerPixel(red: red, green: green, blue: blue)
        }
    }

    private func countGreenTowerPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isGreenTowerPixel(red: red, green: green, blue: blue)
        }
    }

    private func countBlueTowerPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isBlueTowerPixel(red: red, green: green, blue: blue)
        }
    }

    private func countSelectionHighlightPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        guard let image = makeCGImage(from: screenshot.pngRepresentation) else {
            XCTFail("Could not decode UI test screenshot.")
            return 0
        }

        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Could not create screenshot pixel context.")
            return 0
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let centerX = Int(CGFloat(width) * normalizedPoint.dx)
        let centerY = Int(CGFloat(height) * normalizedPoint.dy)
        let ringRadius = CGFloat(min(width, height)) * 0.056
        let ringHalfWidth = max(CGFloat(10), ringRadius * 0.35)
        let minRadiusSquared = (ringRadius - ringHalfWidth) * (ringRadius - ringHalfWidth)
        let maxRadiusSquared = (ringRadius + ringHalfWidth) * (ringRadius + ringHalfWidth)
        let sampleRadius = Int(ceil(ringRadius + ringHalfWidth))
        let minX = max(0, centerX - sampleRadius)
        let maxX = min(width - 1, centerX + sampleRadius)
        let minY = max(0, centerY - sampleRadius)
        let maxY = min(height - 1, centerY + sampleRadius)

        var count = 0

        for y in minY...maxY {
            for x in minX...maxX {
                let dx = CGFloat(x - centerX)
                let dy = CGFloat(y - centerY)
                let distanceSquared = dx * dx + dy * dy

                guard distanceSquared >= minRadiusSquared, distanceSquared <= maxRadiusSquared else {
                    continue
                }

                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let red = Int(pixels[offset])
                let green = Int(pixels[offset + 1])
                let blue = Int(pixels[offset + 2])

                if isSelectionHighlightPixel(red: red, green: green, blue: blue) {
                    count += 1
                }
            }
        }

        return count
    }

    private func countRangePixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector? = nil) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isRangeIndicatorPixel(red: red, green: green, blue: blue)
        }
    }

    private func countPixels(
        in screenshot: XCUIScreenshot,
        near normalizedPoint: CGVector? = nil,
        matches predicate: (Int, Int, Int) -> Bool
    ) -> Int {
        guard let image = makeCGImage(from: screenshot.pngRepresentation) else {
            XCTFail("Could not decode UI test screenshot.")
            return 0
        }

        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Could not create screenshot pixel context.")
            return 0
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let minX: Int
        let maxX: Int
        let minY: Int
        let maxY: Int

        if let normalizedPoint {
            let centerX = Int(CGFloat(width) * normalizedPoint.dx)
            let centerY = Int(CGFloat(height) * normalizedPoint.dy)
            let sampleRadius = max(54, min(width, height) / 16)
            minX = max(0, centerX - sampleRadius)
            maxX = min(width - 1, centerX + sampleRadius)
            minY = max(0, centerY - sampleRadius)
            maxY = min(height - 1, centerY + sampleRadius)
        } else {
            minX = 0
            maxX = width - 1
            minY = 0
            maxY = height - 1
        }

        var count = 0

        for y in minY...maxY {
            for x in minX...maxX {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let red = Int(pixels[offset])
                let green = Int(pixels[offset + 1])
                let blue = Int(pixels[offset + 2])

                if predicate(red, green, blue) {
                    count += 1
                }
            }
        }

        return count
    }

    private func countPixels(
        in screenshot: XCUIScreenshot,
        around normalizedPoint: CGVector,
        xOffsetRange: ClosedRange<CGFloat>,
        yOffsetRange: ClosedRange<CGFloat>,
        matches predicate: (Int, Int, Int) -> Bool
    ) -> Int {
        guard let image = makeCGImage(from: screenshot.pngRepresentation) else {
            XCTFail("Could not decode UI test screenshot.")
            return 0
        }

        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Could not create screenshot pixel context.")
            return 0
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let minX = max(0, Int(CGFloat(width) * (normalizedPoint.dx + xOffsetRange.lowerBound)))
        let maxX = min(width - 1, Int(CGFloat(width) * (normalizedPoint.dx + xOffsetRange.upperBound)))
        let minY = max(0, Int(CGFloat(height) * (normalizedPoint.dy + yOffsetRange.lowerBound)))
        let maxY = min(height - 1, Int(CGFloat(height) * (normalizedPoint.dy + yOffsetRange.upperBound)))

        var count = 0

        for y in minY...maxY {
            for x in minX...maxX {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let red = Int(pixels[offset])
                let green = Int(pixels[offset + 1])
                let blue = Int(pixels[offset + 2])

                if predicate(red, green, blue) {
                    count += 1
                }
            }
        }

        return count
    }

    private func makeCGImage(from pngData: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func isRedTowerPixel(red: Int, green: Int, blue: Int) -> Bool {
        red > 135
            && green < 105
            && blue < 105
    }

    private func isGreenTowerPixel(red: Int, green: Int, blue: Int) -> Bool {
        green > 130
            && red < 125
            && blue < 125
    }

    private func isBlueTowerPixel(red: Int, green: Int, blue: Int) -> Bool {
        blue > 130
            && blue > red * 2
            && blue > green
    }

    // The Green tower's lime missiles/impact flashes (projectileColor ≈ (71, 255, 46)).
    // Thresholds sit well above grass/tree greens so terrain never counts.
    private func isProjectilePixel(red: Int, green: Int, blue: Int) -> Bool {
        green > 220
            && red < 150
            && blue < 150
    }

    private func isEnemyPixel(red: Int, green: Int, blue: Int) -> Bool {
        red > 210
            && green < 100
            && blue < 100
    }

    private func isBarrelPixel(red: Int, green: Int, blue: Int) -> Bool {
        red >= 20
            && red <= 70
            && green >= 45
            && green <= 110
            && blue >= 95
            && blue <= 175
            && blue > red * 2
            && blue > green
    }

    private func isSelectionHighlightPixel(red: Int, green: Int, blue: Int) -> Bool {
        red > 205
            && green > 205
            && blue > 205
    }

    private func isRangeIndicatorPixel(red: Int, green: Int, blue: Int) -> Bool {
        red >= 112
            && red <= 155
            && green >= 145
            && green <= 190
            && blue >= 130
            && blue <= 175
            && green > red
            && blue > red
    }
}
