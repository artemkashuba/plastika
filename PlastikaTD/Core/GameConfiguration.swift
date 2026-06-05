import CoreGraphics

struct GameConfiguration {
    let sceneSize: CGSize
    let preferredFramesPerSecond: Int

    static let standard = GameConfiguration(
        sceneSize: CGSize(width: 390, height: 844),
        preferredFramesPerSecond: 60
    )
}
