import Foundation

enum QuillError: Error, Equatable {
    case invalidURL
    case timeout
    case nonHTTPResponse
    case badStatus(Int)
    case emptyBody
    case transport(String)
    case noAvailableHost
    case gitRefreshFailed
}
