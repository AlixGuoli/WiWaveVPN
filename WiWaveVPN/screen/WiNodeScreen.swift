import Combine
import Foundation
import SwiftUI

// MARK: - 接口形态（与后台契约一致；后台只认各节点的 `id`）

struct NodeCatalogDTO: Decodable {
    var categories: [NodeCategoryDTO]
}

struct NodeCategoryDTO: Decodable {
    var name: String
    var nodes: [NodeItemDTO]
}

struct NodeItemDTO: Decodable {
    var id: Int
    var name: String
    var country: String?
}

// MARK: - 业务模型

/// 单条线路。`serverNodeId == -1` 为自动（随机）；连后台时只传这个 id 即可。
struct WiNode: Identifiable, Hashable {
    let uiID: UUID
    let serverNodeId: Int
    var id: UUID { uiID }

    let name: String
    let country: String?
    let subtitle: String

    static let autoServerNodeId = -1

    var isAuto: Bool { serverNodeId == Self.autoServerNodeId }

    static func autoDefault(using app: AppLanguageStore) -> WiNode {
        WiNode(
            serverNodeId: autoServerNodeId,
            name: L10n.Nodes.autoName(app),
            country: nil,
            subtitle: L10n.Nodes.autoSubtitle(app)
        )
    }

    init(serverNodeId: Int, name: String, country: String?, subtitle: String = "") {
        self.uiID = UUID()
        self.serverNodeId = serverNodeId
        self.name = name
        self.country = country
        self.subtitle = subtitle
    }

    init(apiItem: NodeItemDTO) {
        self.uiID = UUID()
        self.serverNodeId = apiItem.id
        self.name = apiItem.name
        self.country = apiItem.country
        self.subtitle = ""
    }

    /// 按 `categories` 顺序摊平；若接口未带 `id == -1` 的自动项，则在列表**最前**补一条，方便用户随时切回自动。
    static func flattenedNodes(from dto: NodeCatalogDTO) -> [WiNode] {
        let flat = dto.categories.flatMap { category in
            category.nodes.map { WiNode(apiItem: $0) }
        }
        if flat.contains(where: { $0.isAuto }) { return flat }
        return [autoDefault(using: AppLanguageStore())] + flat
    }

    /// 内置线路目录（含 `id == -1` 智能优选）。有远程目录时通过 `applyCatalog` 替换。
    static func bundledNodes(using app: AppLanguageStore) -> [WiNode] {
        [
            autoDefault(using: app),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.germany(app), country: "DE"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.netherlands(app), country: "NL"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.uk(app), country: "GB"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.finland(app), country: "FI"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.france(app), country: "FR"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.japan(app), country: "JP"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.singapore(app), country: "SG"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.usa(app), country: "US"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.canada(app), country: "CA"),
            WiNode(serverNodeId: autoServerNodeId, name: L10n.Nodes.australia(app), country: "AU"),
        ]
    }
}

// MARK: - Store

final class NodeSelectionStore: ObservableObject {
    private let selectedNodeIDKey = "WiWaveVPN.SelectedServerNodeID"
    private let selectedNodeSnapshotKey = "WiWaveVPN.SelectedServerNodeSnapshot"
    @Published var nodes: [WiNode]
    @Published var selected: WiNode
    private var pendingServerNodeID: Int?

    init(appLanguage: AppLanguageStore = AppLanguageStore()) {
        let n = WiNode.bundledNodes(using: appLanguage)
        self.nodes = n
        let savedID = UserDefaults.standard.object(forKey: selectedNodeIDKey) as? Int
        if let savedID,
           let localMatch = n.first(where: { $0.serverNodeId == savedID }) {
            self.selected = localMatch
        } else if let snapshot = Self.loadPersistedSelection(from: UserDefaults.standard, key: selectedNodeSnapshotKey),
                  let savedID,
                  snapshot.serverNodeId == savedID {
            self.selected = snapshot
            self.pendingServerNodeID = savedID
        } else {
            self.selected = n.first(where: { $0.isAuto })
                ?? n.first
                ?? WiNode.autoDefault(using: appLanguage)
            if let savedID, savedID != WiNode.autoServerNodeId {
                self.pendingServerNodeID = savedID
            }
        }
    }

    /// 切换应用内语言后刷新内置目录文案，并尽量保持同一 `serverNodeId`。
    func applyLocalization(_ app: AppLanguageStore) {
        let next = WiNode.bundledNodes(using: app)
        let serverID = selected.serverNodeId
        nodes = next
        if let matched = next.first(where: { $0.serverNodeId == serverID }) {
            selected = matched
            persistSelection(matched)
            pendingServerNodeID = nil
            return
        }
        if serverID != WiNode.autoServerNodeId {
            pendingServerNodeID = serverID
            return
        }
        let auto = next.first(where: { $0.isAuto }) ?? next[0]
        selected = auto
        persistSelection(auto)
        pendingServerNodeID = nil
    }

    func pick(_ node: WiNode) {
        selected = node
        pendingServerNodeID = nil
        persistSelection(node)
    }

    func applyCatalog(_ dto: NodeCatalogDTO) {
        let targetServerID = pendingServerNodeID ?? selected.serverNodeId
        nodes = WiNode.flattenedNodes(from: dto)
        let app = AppLanguageStore()
        selected = nodes.first(where: { $0.serverNodeId == targetServerID })
            ?? nodes.first(where: { $0.isAuto })
            ?? nodes.first
            ?? WiNode.autoDefault(using: app)
        pendingServerNodeID = nil
        persistSelection(selected)
    }

    func applyCatalogJSON(_ jsonText: String) {
        guard let data = jsonText.data(using: .utf8) else {
            AppLogger.log(.connection, tag: "Quill", "节点列表 JSON 编码失败")
            return
        }
        guard let dto = try? JSONDecoder().decode(NodeCatalogDTO.self, from: data) else {
            AppLogger.log(.connection, tag: "Quill", "节点列表 JSON 解析失败（结构不匹配）")
            return
        }
        applyCatalog(dto)
        AppLogger.log(.connection, tag: "Quill", "节点列表已应用 total=\(nodes.count)")
    }

    private struct PersistedNodeSnapshot: Codable {
        let serverNodeId: Int
        let name: String
        let country: String?
        let subtitle: String
    }

    private func persistSelection(_ node: WiNode) {
        UserDefaults.standard.set(node.serverNodeId, forKey: selectedNodeIDKey)
        let snapshot = PersistedNodeSnapshot(
            serverNodeId: node.serverNodeId,
            name: node.name,
            country: node.country,
            subtitle: node.subtitle
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: selectedNodeSnapshotKey)
    }

    private static func loadPersistedSelection(from defaults: UserDefaults, key: String) -> WiNode? {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(PersistedNodeSnapshot.self, from: data) else {
            return nil
        }
        return WiNode(
            serverNodeId: snapshot.serverNodeId,
            name: snapshot.name,
            country: snapshot.country,
            subtitle: snapshot.subtitle
        )
    }
}

// MARK: - 页面

struct WiNodeListView: View {
    @EnvironmentObject private var store: NodeSelectionStore
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    Text(L10n.Nodes.navTitle(appLanguage))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WiTheme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(WiTheme.accent)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(WiTheme.bgTile.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(WiTheme.accent.opacity(0.45), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Nodes.closeListA11y(appLanguage))
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                List {
                    Section {
                        Text(L10n.Nodes.footerNote(appLanguage))
                            .font(.footnote)
                            .foregroundStyle(WiTheme.textSecondary)
                            .listRowBackground(WiTheme.bgElevated.opacity(0.45))
                    }
                    Section {
                        ForEach(store.nodes) { node in
                            Button {
                                store.pick(node)
                                dismiss()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(node.name)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(WiTheme.textPrimary)
                                        if !node.subtitle.isEmpty {
                                            Text(node.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(WiTheme.textTertiary)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    if let cc = node.country, !cc.isEmpty {
                                        Text(cc.uppercased())
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(WiTheme.accent.opacity(0.9))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .stroke(WiTheme.borderSubtle, lineWidth: 1)
                                                    .background(Capsule().fill(WiTheme.bgElevated.opacity(0.5)))
                                            )
                                    } else if node.isAuto {
                                        Text(L10n.Nodes.autoBadge(appLanguage))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(WiTheme.accent.opacity(0.9))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .stroke(WiTheme.borderSubtle, lineWidth: 1)
                                                    .background(Capsule().fill(WiTheme.bgElevated.opacity(0.5)))
                                            )
                                    }
                                    if store.selected.id == node.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(WiTheme.success)
                                    }
                                }
                            }
                            .listRowBackground(WiTheme.bgTile.opacity(0.55))
                        }
                    } header: {
                        Text(L10n.Nodes.sectionRoutes(appLanguage))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(WiTheme.textTertiary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowSeparatorTint(WiTheme.borderSubtle)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await QuillNodeCatalogFlow().refresh(into: store)
        }
    }
}
