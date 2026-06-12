import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var sceneManager = SceneManager()
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            // SpriteView is always present once the scene exists so that
            // didMove(to:) fires, which builds the scene and calls markSceneLoaded().
            if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
            }

            // Loading overlay — shown until scene finishes didMove(to:)
            if gameStateManager.state.phase == .booting {
                LoadingView()
                    .transition(.opacity)
            }

            // Main menu — shown over the idle battlefield until the player taps PLAY
            if gameStateManager.state.phase == .mainMenu {
                MainMenuView(gameStateManager: gameStateManager)
                    .transition(.opacity)
            }

            // Pause overlay — shown while game is paused
            if gameStateManager.state.phase == .paused {
                PauseMenuView(gameStateManager: gameStateManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.22), value: gameStateManager.state.phase == .paused)
        .animation(.easeOut(duration: 0.35), value: gameStateManager.state.phase == .mainMenu)
        .animation(.easeOut(duration: 0.55), value: gameStateManager.state.phase == .booting)
        .onAppear {
            loadInitialSceneIfNeeded()
        }
    }

    private func loadInitialSceneIfNeeded() {
        guard scene == nil else { return }
        scene = sceneManager.makeInitialScene(gameStateManager: gameStateManager)
    }
}

// MARK: - Main Menu

private struct MainMenuView: View {
    @ObservedObject var gameStateManager: GameStateManager
    @State private var pulse = false

    // Match game scene palette (same family as LoadingView / PauseMenuView)
    private let bg     = Color(red: 0.07, green: 0.15, blue: 0.16)
    private let card   = Color(red: 0.08, green: 0.13, blue: 0.15)
    private let accent = Color(red: 0.52, green: 0.60, blue: 0.54)
    private let titleC = Color(red: 0.86, green: 0.95, blue: 0.78)
    private let dim    = Color(red: 0.86, green: 0.95, blue: 0.78).opacity(0.55)

    var body: some View {
        ZStack {
            // Dimmed backdrop — the idle battlefield shows through faintly underneath.
            bg.opacity(0.88)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                titleBlock

                Spacer().frame(height: 56)

                playButton

                Spacer().frame(height: 28)

                taglineRow

                Spacer()

                settingsCard
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 42)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("PLASTIKA TD")
                .font(.custom("AvenirNext-Heavy", size: 38))
                .foregroundColor(titleC)
                .tracking(5)

            Text("TOWER DEFENSE")
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundColor(accent)
                .tracking(6)
        }
    }

    private var playButton: some View {
        Button(action: { gameStateManager.startGame() }) {
            Text("PLAY")
                .font(.custom("AvenirNext-Heavy", size: 22))
                .foregroundColor(bg)
                .tracking(6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(titleC)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: titleC.opacity(pulse ? 0.45 : 0.15), radius: pulse ? 18 : 8)
        }
        .scaleEffect(pulse ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }

    private var taglineRow: some View {
        Text("10 WAVES  ·  3 LIVES  ·  NO MERCY")
            .font(.custom("AvenirNext-DemiBold", size: 11))
            .foregroundColor(dim)
            .tracking(2)
    }

    // Sound + haptics toggles — same controls the pause menu offers, reachable before a run.
    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingsRow(
                icon: gameStateManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                label: "Sound Effects",
                isOn: Binding(
                    get: { gameStateManager.isSoundEnabled },
                    set: { gameStateManager.setSoundEnabled($0) }
                )
            )

            Rectangle()
                .fill(accent.opacity(0.18))
                .frame(height: 1)

            settingsRow(
                icon: gameStateManager.isHapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                label: "Haptics",
                isOn: Binding(
                    get: { gameStateManager.isHapticsEnabled },
                    set: { gameStateManager.setHapticsEnabled($0) }
                )
            )
        }
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.30), lineWidth: 1)
        )
    }

    private func settingsRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accent)
                .frame(width: 22)

            Text(label)
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(titleC)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

// MARK: - Loading Screen

private struct LoadingView: View {
    @State private var pulse = false
    @State private var dotIndex = 0

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // Match game scene colours exactly
    private let bg      = Color(red: 0.07, green: 0.15, blue: 0.16)
    private let accent  = Color(red: 0.52, green: 0.60, blue: 0.54)
    private let titleC  = Color(red: 0.86, green: 0.95, blue: 0.78)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 32) {
                reticle
                titleBlock
                loadingDots
            }
        }
    }

    // MARK: Reticle

    private var reticle: some View {
        ZStack {
            // Sonar-ping outer ring — expands outward and fades
            Circle()
                .stroke(accent.opacity(0.55), lineWidth: 1.5)
                .frame(width: 90, height: 90)
                .scaleEffect(pulse ? 1.22 : 1.0)
                .opacity(pulse ? 0.0 : 1.0)
                .animation(
                    .easeOut(duration: 1.7).repeatForever(autoreverses: false),
                    value: pulse
                )

            // Static middle ring
            Circle()
                .stroke(accent.opacity(0.55), lineWidth: 1.5)
                .frame(width: 66, height: 66)

            // Inner ring
            Circle()
                .stroke(accent, lineWidth: 2)
                .frame(width: 44, height: 44)

            // Crosshair — horizontal
            Rectangle()
                .fill(accent.opacity(0.75))
                .frame(width: 22, height: 1.5)

            // Crosshair — vertical
            Rectangle()
                .fill(accent.opacity(0.75))
                .frame(width: 1.5, height: 22)

            // Centre dot
            Circle()
                .fill(accent)
                .frame(width: 5, height: 5)
        }
        .onAppear { pulse = true }
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("PLASTIKA TD")
                .font(.custom("AvenirNext-Heavy", size: 30))
                .foregroundColor(titleC)
                .tracking(5)

            Text("TOWER DEFENSE")
                .font(.custom("AvenirNext-Medium", size: 11))
                .foregroundColor(accent)
                .tracking(4)
        }
    }

    // MARK: Dots

    private var loadingDots: some View {
        HStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(accent.opacity(dotIndex == i ? 1.0 : 0.22))
                    .frame(width: 7, height: 7)
                    .scaleEffect(dotIndex == i ? 1.25 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: dotIndex)
            }
        }
        .onReceive(ticker) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}
