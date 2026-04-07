import Foundation

/// 设置页「隐私政策 / 用户条款」跳转地址。
enum AppLegalURLs {
    static let privacyPolicy = URL(string: "https://tunnelnova.xyz/p.html")!
    /// App Store 常用：Apple 标准最终用户许可协议（如你在 App Store Connect 选用标准许可）。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
