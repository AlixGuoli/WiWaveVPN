import SwiftUI

/// WiWave 深色科技风向导（连接页先行，后续 Tab 可逐步对齐）。
enum WiTheme {

    static let bgDeep = Color(red: 0.06, green: 0.07, blue: 0.12)
    static let bgElevated = Color(red: 0.11, green: 0.13, blue: 0.20)
    static let bgTile = Color(red: 0.14, green: 0.16, blue: 0.24)

    static let accent = Color(red: 0.35, green: 0.88, blue: 0.98)
    static let accentMuted = Color(red: 0.35, green: 0.88, blue: 0.98).opacity(0.45)
    static let accentDeep = Color(red: 0.18, green: 0.42, blue: 0.55)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    static let borderSubtle = Color.white.opacity(0.14)
    static let success = Color(red: 0.38, green: 0.92, blue: 0.68)
    static let warning = Color(red: 0.98, green: 0.74, blue: 0.38)
    static let error = Color(red: 0.98, green: 0.45, blue: 0.52)
    /// 点缀用暖色，只宜小面积，避免「AI 紫粉渐变」感。
    static let accentHot = Color(red: 1.0, green: 0.48, blue: 0.35)
    static let glowTeal = Color(red: 0.35, green: 0.88, blue: 0.98).opacity(0.22)

    static var connectBackdrop: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.035, green: 0.055, blue: 0.095),
                Color(red: 0.07, green: 0.085, blue: 0.14),
                Color(red: 0.055, green: 0.07, blue: 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func heroGradient(for phase: WiPhase) -> LinearGradient {
        switch phase {
        case .offline:
            return LinearGradient(
                colors: [accentDeep.opacity(0.95), bgElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .busy:
            return LinearGradient(
                colors: [accent.opacity(0.55), accentDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .online:
            return LinearGradient(
                colors: [success.opacity(0.65), Color(red: 0.12, green: 0.32, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [error.opacity(0.55), Color(red: 0.35, green: 0.14, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func statusTint(for phase: WiPhase) -> Color {
        switch phase {
        case .offline: return textTertiary
        case .busy: return accent
        case .online: return success
        case .error: return error
        }
    }

    // MARK: - 流程页背景（与连接页一致）

    struct FlowBackdrop: View {
        var body: some View {
            ZStack {
                WiTheme.connectBackdrop

                RadialGradient(
                    colors: [WiTheme.glowTeal.opacity(0.65), Color.clear],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 280
                )

                FlowDotGrid(opacity: 0.04, step: 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
    }

    struct FlowDotGrid: View {
        var opacity: Double = 0.05
        var step: CGFloat = 16

        var body: some View {
            GeometryReader { geo in
                Canvas { context, size in
                    for x in stride(from: 0, to: size.width + step, by: step) {
                        for y in stride(from: 0, to: size.height + step, by: step) {
                            let rect = CGRect(x: x, y: y, width: 1.1, height: 1.1)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(opacity)))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
