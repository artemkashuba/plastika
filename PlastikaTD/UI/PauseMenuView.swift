import SwiftUI

struct PauseMenuView: View {
    @ObservedObject var gameStateManager: GameStateManager

    // Match game scene palette
    private let bg     = Color(red: 0.07, green: 0.15, blue: 0.16)
    private let card   = Color(red: 0.08, green: 0.13, blue: 0.15)
    private let accent = Color(red: 0.52, green: 0.60, blue: 0.54)
    private let title  = Color(red: 0.86, green: 0.95, blue: 0.78)
    private let dim    = Color(red: 0.86, green: 0.95, blue: 0.78).opacity(0.55)

    var body: some View {
        ZStack {
            // Backdrop — tap anywhere to resume
            bg.opacity(0.80)
                .ignoresSafeArea()
                .onTapGesture { gameStateManager.resume() }

            panel
                // Block backdrop tap from passing through the card itself
                .contentShape(Rectangle())
                .onTapGesture { }
        }
    }

    // MARK: - Card

    private var panel: some View {
        VStack(spacing: 0) {
            headerRow

            divider

            soundRow

            if let stats = gameStateManager.pauseStats {
                divider
                enemySection(stats)
                divider
                towerSection(stats)
            }

            divider

            resumeButton
        }
        .frame(width: 306)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(accent.opacity(0.30), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.55), radius: 28, x: 0, y: 8)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accent)
            Text("PAUSED")
                .font(.custom("AvenirNext-Heavy", size: 20))
                .foregroundColor(title)
                .tracking(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Sound

    private var soundRow: some View {
        HStack(spacing: 12) {
            Image(systemName: gameStateManager.isSoundEnabled
                  ? "speaker.wave.2.fill"
                  : "speaker.slash.fill")
                .font(.system(size: 16))
                .foregroundColor(accent)
                .frame(width: 22)

            Text("Sound Effects")
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(title)

            Spacer()

            Toggle("", isOn: Binding(
                get: { gameStateManager.isSoundEnabled },
                set: { gameStateManager.setSoundEnabled($0) }
            ))
            .labelsHidden()
            .tint(accent)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    // MARK: - Enemy section

    private func enemySection(_ stats: PauseStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ENEMIES")

            HStack(spacing: 0) {
                statCell(
                    value: "\(stats.activeEnemies)",
                    label: "on field",
                    color: title
                )
                statDivider
                statCell(
                    value: "\(stats.spawnedEnemies)/\(stats.totalEnemies)",
                    label: "spawned",
                    color: title
                )
                statDivider
                statCell(
                    value: "\(stats.killCount)",
                    label: "destroyed",
                    color: Color(uiColor: UIColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1))
                )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    // MARK: - Tower section

    private func towerSection(_ stats: PauseStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("TOWERS")

            // Deployed count + coins summary
            HStack(spacing: 18) {
                ForEach(TowerType.allCases, id: \.self) { type in
                    towerBadge(type: type, count: stats.towerCounts[type, default: 0])
                }
                Spacer()
                Text("\(stats.coinsInvested) coins invested")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(dim)
            }

            // Arsenal reference
            sectionHeader("ARSENAL")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(TowerType.allCases, id: \.self) { type in
                        towerSpecCard(type)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private func towerSpecCard(_ type: TowerType) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Colour-coded icon
            Circle()
                .fill(Color(uiColor: type.baseColor))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color(uiColor: type.turretColor).opacity(0.85), lineWidth: 2)
                )
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(type.displayName)
                    .font(.custom("AvenirNext-Heavy", size: 13))
                    .foregroundColor(title)

                Text(type.towerDescription)
                    .font(.custom("AvenirNext-Regular", size: 11))
                    .foregroundColor(dim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    specChip(label: "DMG",    value: "\(type.damage)")
                    specChip(label: "RELOAD", value: String(format: "%gs", type.attackCooldown))
                    specChip(label: "RANGE",  value: "\(Int(type.range))")
                    specChip(label: "DPS",    value: String(format: "%.1f", type.dps))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: type.baseColor).opacity(0.30), lineWidth: 1)
        )
    }

    private func specChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(title)
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 8))
                .foregroundColor(accent)
                .tracking(0.5)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Resume

    private var resumeButton: some View {
        Button(action: { gameStateManager.resume() }) {
            Text("RESUME")
                .font(.custom("AvenirNext-Heavy", size: 16))
                .foregroundColor(title)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(accent.opacity(0.18))
            .frame(height: 1)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(accent.opacity(0.18))
            .frame(width: 1, height: 36)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.custom("AvenirNext-Bold", size: 10))
            .foregroundColor(accent)
            .tracking(2)
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("AvenirNext-Heavy", size: 22))
                .foregroundColor(color)
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 10))
                .foregroundColor(dim)
        }
        .frame(maxWidth: .infinity)
    }

    private func towerBadge(type: TowerType, count: Int) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color(uiColor: type.baseColor))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color(uiColor: type.turretColor).opacity(0.75), lineWidth: 1.5)
                )

            Text("×\(count)")
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(count > 0 ? title : dim)
        }
    }
}
