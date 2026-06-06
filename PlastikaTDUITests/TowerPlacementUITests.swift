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

    func testTapBuildSpotPlacesOnePlaceholderTowerOnlyOnce() {
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot = CGVector(dx: 0.74, dy: 0.26)
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

        let topRightBuildSpot = CGVector(dx: 0.74, dy: 0.26)
        let middleRightBuildSpot = CGVector(dx: 0.74, dy: 0.57)
        let lowerRightBuildSpot = CGVector(dx: 0.74, dy: 0.77)
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

        let earlyBuildSpot = CGVector(dx: 0.21, dy: 0.66)
        placeTower(app, at: earlyBuildSpot, option: .green)

        var sawProjectile = false

        for _ in 0..<16 {
            Thread.sleep(forTimeInterval: 0.25)

            let projectilePixels = countPixels(in: XCUIScreen.main.screenshot()) { red, green, blue in
                isProjectilePixel(red: red, green: green, blue: blue)
            }

            if projectilePixels > 16 {
                sawProjectile = true
                break
            }
        }

        XCTAssertTrue(sawProjectile)

        Thread.sleep(forTimeInterval: 4.5)

        let remainingEnemyPixels = countPixels(in: XCUIScreen.main.screenshot()) { red, green, blue in
            isEnemyPixel(red: red, green: green, blue: blue)
        }

        XCTAssertLessThan(remainingEnemyPixels, 500)
    }

    func testPlacedTowerAimsBarrelTowardLockedTarget() {
        let app = XCUIApplication()
        app.launch()

        let earlyBuildSpot = CGVector(dx: 0.21, dy: 0.66)
        placeTower(app, at: earlyBuildSpot, option: .blue)
        Thread.sleep(forTimeInterval: 0.25)

        let aimedTower = XCUIScreen.main.screenshot()
        let lowerBarrelPixels = countPixels(
            in: aimedTower,
            around: earlyBuildSpot,
            xOffsetRange: -0.04...0.04,
            yOffsetRange: 0.02...0.08
        ) { red, green, blue in
            isBarrelPixel(red: red, green: green, blue: blue)
        }
        let upperBarrelPixels = countPixels(
            in: aimedTower,
            around: earlyBuildSpot,
            xOffsetRange: -0.04...0.04,
            yOffsetRange: -0.08 ... -0.02
        ) { red, green, blue in
            isBarrelPixel(red: red, green: green, blue: blue)
        }

        XCTAssertGreaterThan(lowerBarrelPixels, upperBarrelPixels + 30)
    }

    func testTowerSelectionShowsRangeSwitchesAndClears() {
        let app = XCUIApplication()
        app.launch()

        let firstTower = CGVector(dx: 0.74, dy: 0.26)
        let secondTower = CGVector(dx: 0.74, dy: 0.77)
        let firstRangeSample = CGVector(dx: 0.30, dy: 0.26)
        let secondRangeSample = CGVector(dx: 0.30, dy: 0.77)
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

    private func placeTower(_ app: XCUIApplication, at buildSpot: CGVector, option: TestTowerOption) {
        app.coordinate(withNormalizedOffset: buildSpot).tap()
        Thread.sleep(forTimeInterval: 0.15)
        app.coordinate(withNormalizedOffset: menuOption(for: buildSpot, option: option)).tap()
        Thread.sleep(forTimeInterval: 0.25)
    }

    private func menuOption(for buildSpot: CGVector, option: TestTowerOption) -> CGVector {
        let xOffset: CGFloat

        switch option {
        case .red:
            xOffset = -menuOptionSpacing
        case .green:
            xOffset = 0
        case .blue:
            xOffset = menuOptionSpacing
        }

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

    private func isProjectilePixel(red: Int, green: Int, blue: Int) -> Bool {
        red > 210
            && green < 120
            && blue > 170
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
