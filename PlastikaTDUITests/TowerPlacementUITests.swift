import CoreGraphics
import ImageIO
import XCTest

final class TowerPlacementUITests: XCTestCase {
    func testTapBuildSpotPlacesOnePlaceholderTowerOnlyOnce() {
        let app = XCUIApplication()
        app.launch()

        let topRightBuildSpot = CGVector(dx: 0.74, dy: 0.26)
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

    private func countTowerPixels(in screenshot: XCUIScreenshot, near normalizedPoint: CGVector) -> Int {
        countPixels(in: screenshot, near: normalizedPoint) { red, green, blue in
            isPlaceholderTowerPixel(red: red, green: green, blue: blue)
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
}
