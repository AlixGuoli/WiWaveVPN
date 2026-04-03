import SwiftUI

enum WiRoute: Hashable {
    case progress
    case verdict(WiVerdict)
}

struct WiProgressScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("连接中")
                .font(.title2.weight(.semibold))
            Text("请稍候…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WiOutcomeScreen: View {
    let verdict: WiVerdict
    @EnvironmentObject private var coil: WiSessionCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(tint)
            Text(title)
                .font(.title2.weight(.bold))
            Button("知道了") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            coil.clearVerdict()
        }
    }

    private var title: String {
        switch verdict {
        case .linkedOK: return "连接成功"
        case .linkedFail: return "连接失败"
        case .unpluggedOK: return "已断开"
        }
    }

    private var icon: String {
        switch verdict {
        case .linkedOK: return "checkmark.circle.fill"
        case .linkedFail: return "xmark.circle.fill"
        case .unpluggedOK: return "bolt.horizontal.circle"
        }
    }

    private var tint: Color {
        switch verdict {
        case .linkedOK: return .green
        case .linkedFail: return .red
        case .unpluggedOK: return .secondary
        }
    }
}
