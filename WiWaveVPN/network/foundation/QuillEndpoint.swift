import Foundation

/// 描述单个接口的最小信息。
struct QuillEndpoint: Hashable {
    let path: String
    let extraQuery: [String: String]

    init(path: String, extraQuery: [String: String] = [:]) {
        self.path = path
        self.extraQuery = extraQuery
    }
}
