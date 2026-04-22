import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var nodes: NodeSelectionStore
    @EnvironmentObject private var coil: WiSessionCoordinator
    @State private var path: [WiRoute] = []
    @State private var progressTimeoutTask: DispatchWorkItem?
    @State private var didPrimeOnMainEnter = false
    private let progressAutoCloseSeconds: TimeInterval = 30

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
        .onAppear {
            guard !didPrimeOnMainEnter else { return }
            didPrimeOnMainEnter = true
            FluxAdManager.shared.primeInt(trigger: .manual)
        }
        .onChange(of: coil.showProgressPage) { show in
            if show {
                if path.last != .progress {
                    path.append(.progress)
                }
                progressTimeoutTask?.cancel()
                let task = DispatchWorkItem { [weak coil] in
                    coil?.handleProgressPageTimeout()
                }
                progressTimeoutTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + progressAutoCloseSeconds, execute: task)
            } else if path.last == .progress {
                path.removeLast()
                progressTimeoutTask?.cancel()
                progressTimeoutTask = nil
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
            switch v {
            case .linkedOK:
                _ = FluxAdManager.shared.presentIntIfReady(trigger: .connect)
            case .unpluggedOK:
                _ = FluxAdManager.shared.presentIntIfReady(trigger: .disconnect)
            case .linkedFail:
                break
            }
        }
        .overlay {
            Group {
                if appLanguage.isApplyingLanguage {
                    LanguageApplyingOverlay()
                }
            }
            .animation(.easeInOut(duration: 0.22), value: appLanguage.isApplyingLanguage)
        }
        .onDisappear {
            progressTimeoutTask?.cancel()
            progressTimeoutTask = nil
        }
    }
}

/// 应用内切换语言时的全屏遮罩（文案仍用切换前语言，直到 `preference` 更新）。
private struct LanguageApplyingOverlay: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(L10n.Settings.languageApplying(appLanguage))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
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
