import SwiftUI

/// 面板：只读展示会话状态与装饰模块（与主隧道写入路径隔离）。
struct DashboardPanelView: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var coil: WiSessionCoordinator
    @EnvironmentObject private var nodes: NodeSelectionStore

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                TabTopChrome(title: L10n.Chrome.panel(appLanguage), flowStyle: true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        DashboardSessionStrip(
                            phase: coil.phase,
                            phaseLabel: phaseLabel,
                            tunnelConnectedSince: coil.tunnelConnectedSince
                        )

                        DashboardRouteDigestCard(
                            nodeName: nodes.selected.name,
                            seed: nodes.selected.serverNodeId
                        )

                        DashboardSparklineCard()

                        DashboardFakeCheckCard()

                        DashboardSecurityCard()

                        DashboardTipsCarousel()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 32)
                    .id(appLanguage.contentRefreshIdentity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(WiTheme.accent)
    }

    private var phaseLabel: String {
        switch coil.phase {
        case .offline: return L10n.Dashboard.sessionOffline(appLanguage)
        case .busy: return L10n.Dashboard.sessionBusy(appLanguage)
        case .online: return L10n.Dashboard.sessionOnline(appLanguage)
        case .error: return L10n.Dashboard.sessionError(appLanguage)
        }
    }
}
