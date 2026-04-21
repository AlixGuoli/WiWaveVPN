import Foundation

/// 节点目录拉取流程：请求 category 接口并将结果交给 Store 应用。
@MainActor
final class QuillNodeCatalogFlow {
    private let probe: QuillProbe

    init(probe: QuillProbe) {
        self.probe = probe
    }

    convenience init() {
        self.init(probe: QuillProbe())
    }

    func refresh(into store: NodeSelectionStore) async {
        AppLogger.log(.connection, tag: "Quill", "准备请求节点列表 /academy/category/subject")
        guard let body = await probe.pingCategoryAndLog() else {
            AppLogger.log(.connection, tag: "Quill", "节点列表接口请求失败或无内容")
            return
        }
        store.applyCatalogJSON(body)
    }
}
