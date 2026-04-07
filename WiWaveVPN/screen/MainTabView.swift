import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var nodes: NodeSelectionStore
    @EnvironmentObject private var coil: WiSessionCoordinator
    @State private var path: [WiRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TabView {
                ConnectRootView(path: $path)
                    .tabItem {
                        Label(L10n.Tab.connect(appLanguage), systemImage: "bolt.horizontal.circle")
                    }

                DashboardPanelView()
                    .tabItem {
                        Label(L10n.Tab.panel(appLanguage), systemImage: "square.grid.2x2")
                    }

                AppSettingsView(path: $path)
                    .tabItem {
                        Label(L10n.Tab.settings(appLanguage), systemImage: "gearshape")
                    }
            }
            .navigationDestination(for: WiRoute.self) { step in
                switch step {
                case .progress:
                    WiProgressScreen()
                case .verdict(let v):
                    WiOutcomeScreen(verdict: v)
                case .nodeList:
                    WiNodeListView()
                case .helpManual:
                    HelpManualScreen()
                }
            }
            .tint(WiTheme.accent)
        }
        .onChange(of: appLanguage.preference) { _ in
            nodes.applyLocalization(appLanguage)
        }
        .onChange(of: coil.showProgressPage) { show in
            if show {
                if path.last != .progress {
                    path.append(.progress)
                }
            } else if path.last == .progress {
                path.removeLast()
            }
        }
        .onChange(of: coil.verdict) { newVal in
            guard let v = newVal else { return }
            if path.last == .progress {
                path.removeLast()
            }
            if let last = path.last, case .verdict = last {
                path.removeLast()
            }
            path.append(.verdict(v))
        }
    }
}

/// 无外层 per-tab `NavigationStack` 时，各 Tab 首页共用的标题条（非系统导航栏）。
struct TabTopChrome: View {
    let title: String
    /// 与 `WiTheme.FlowBackdrop` 等深色页搭配时使用主文字色。
    var flowStyle: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(flowStyle ? WiTheme.textPrimary : Color.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}
