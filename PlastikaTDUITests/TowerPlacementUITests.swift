import CoreGraphics
import ImageIO
import XCTest

final class TowerPlacementUITests: XCTestCase {
    func testTapBuildSpotPlacesOnePlaceholderTowerOnlyOnce() {
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot = CGVector(dx: 0.74, dy: 0.26)
        let emptyBattlefield = CGVector(dx: 0.50, dy: 0.88)
        let tapTarget = app.coordinate(withNormalizedOffset: topRightBuildSpot)

        let baselineTowerPixels = countTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        tapTarget.tap()

        let afterFirstTapPixels = countTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        tapTarget.tap()
        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let afterSecondTapPixels = countTowerPixels(
            in: XCUIScreen.main.screenshot(),
            near: topRightBuildSpot
        )

        XCTAssertLessThan(baselineTowerPixels, 120)
        XCTAssertGreaterThan(afterFirstTapPixels, baselineTowerPixels + 500)
        XCTAssertLessThanOrEqual(abs(afterSecondTapPixels - afterFirstTapPixels), 150)
    }

    func testPlacedTowerFiresProjectilesAndDestroysEnemies() {
        let app = XCUIApplication()
        app.launch()

        let earlyBuildSpot = CGVector(dx: 0.21, dy: 0.66)
        app.coordinate(withNormalizedOffset: earlyBuildSpot).tap()

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
        app.coordinate(withNormalizedOffset: earlyBuildSpot).tap()
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

        let firstTower = CGVector(dx: 0.74, dy: 0.57)
        let secondTower = CGVector(dx: 0.74, dy: 0.77)
        let firstRangeSample = CGVector(dx: 0.30, dy: 0.57)
        let secondRangeSample = CGVector(dx: 0.30, dy: 0.77)
        let emptyBattlefield = CGVector(dx: 0.50, dy: 0.88)

        app.coordinate(withNormalizedOffset: firstTower).tap()
        app.coordinate(withNormalizedOffset: secondTower).tap()

        let beforeSelection = XCUIScreen.main.screenshot()
        let beforeRangePixels = countRangePixels(in: beforeSelection)
        let beforeFirstHighlightPixels = countSelectionHighlightPixels(in: beforeSelection, near: firstTower)

        app.coordinate(withNormalizedOffset: firstTower).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let firstSelected = XCUIScreen.main.screenshot()
        let firstSelectedRangePixels = countRangePixels(in: firstSelected)
        let firstSelectedHighlightPixels = countSelectionHighlightPixels(in: firstSelected, near: firstTower)
        let firstSelectedRangeSamplePixels = countRangePixels(in: firstSelected, near: firstRangeSample)

        XCTAssertGreaterThan(firstSelectedRangePixels, beforeRangePixels + 700)
        XCTAssertGreaterThan(firstSelectedHighlightPixels, beforeFirstHighlightPixels + 40)
        XCTAssertGreaterThan(firstSelectedRangeSamplePixels, 18)

        app.coordinate(withNormalizedOffset: secondTower).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let secondSelected = XCUIScreen.main.screenshot()
        let firstAfterSwitchHighlightPixels = countSelectionHighlightPixels(in: secondSelected, near: firstTower)
        let secondSelectedHighlightPixels = countSelectionHighlightPixels(in: secondSelected, near: secondTower)
        let firstAfterSwitchRangeSamplePixels = countRangePixels(in: secondSelected, near: firstRangeSample)
        let secondSelectedRangeSamplePixels = countRangePixels(in: secondSelected, near: secondRangeSample)

        XCTAssertLessThan(firstAfterSwitchHighlightPixels, firstSelectedHighlightPixels - 30)
        XCTAssertGreaterThan(secondSelectedHighlightPixels, beforeFirstHighlightPixels + 40)
        XCTAssertLessThan(firstAfterSwitchRangeSamplePixels, firstSelectedRangeSamplePixels)
        XCTAssertGreaterThan(secondSelectedRangeSamplePixels, 18)

        app.coordinate(withNormalizedOffset: emptyBattlefield).tap()
        Thread.sleep(forTimeInterval: 0.25)

        let cleared = XCUIScreen.main.screenshot()
        let clearedRangePixels = countRangePixels(in: cleared)
        let clearedSecondHighlightPixels = countSelectionHighlightPixels(in: cleared, near: secondTower)

        XCTAssertLessThan(clearedRangePixels, firstSelectedRangePixels - 700)
        XCTAssertLessThan(clearedSecondHighlightPixels, secondSelectedHighlightPixels - 30)
    }

    private func countTowerPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isPlaceholderTowerPixel(red: red, green: green, blue: blue)
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

    private func isPlaceholderTowerPixel(red: Int, green: Int, blue: Int) -> Bool {
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
