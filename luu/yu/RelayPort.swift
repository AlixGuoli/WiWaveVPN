import Foundation
import os

public enum RelayPort {
    private enum Valve {
        static let maxFd: Int32 = 1024
        static let familyNeed = AF_SYSTEM
    }
    
    @discardableResult
    public static func engage(path: String) -> Int32 {
        return engageInner(path: path)
    }
    
    public static func disengage() {
        disengageInner()
    }
    
    private static var selectedFd: Int32? {
        return resolveTokenPipe()
    }
    
    private static func resolveTokenPipe() -> Int32? {
        var stem = ArcStem()
        withUnsafeMutablePointer(to: &stem.stemRune) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: $0.pointee)) {
                _ = strcpy($0, ctlLabel())
            }
        }
        
        for fdMark: Int32 in 0...Valve.maxFd {
            if let hitFd = scanEndpoint(fdMark, stem: &stem) {
                return hitFd
            }
        }
        return nil
    }
    
    private static func scanEndpoint(_ fdMark: Int32, stem: inout ArcStem) -> Int32? {
        var glyph = ArcGlyph()
        var probeState: Int32 = -1
        var sockSpan = socklen_t(MemoryLayout.size(ofValue: glyph))
        withUnsafeMutablePointer(to: &glyph) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                probeState = getpeername(fdMark, $0, &sockSpan)
            }
        }
        if probeState != 0 || glyph.glyphKind != Valve.familyNeed {
            return nil
        }
        if stem.stemKey == 0 {
            probeState = ioctl(fdMark, CTLIOCGINFO, &stem)
            if probeState != 0 {
                return nil
            }
        }
        if glyph.glyphKey == stem.stemKey {
            return fdMark
        }
        return nil
    }

    private static func ctlLabel() -> String {
        ["com.apple.net", "utun_control"].joined(separator: ".")
    }

    @discardableResult
    private static func engageInner(path: String) -> Int32 {
        guard let descriptor = selectedFd else {
            fatalError("Tunnel fd unavailable.")
        }

        let result = startBridge(path: path, fd: descriptor)

        if result != 0 {
            os_log("[rp] %{public}@", log: OSLog.default, type: .error, "engage fail: \(result)")
        }

        return result
    }
    
    private static func disengageInner() {
        stopBridge()
    }

    private static func startBridge(path: String, fd: Int32) -> Int32 {
        WiwaveRunBlockingOnConfigPath(path.cString(using: .utf8), fd)
    }

    private static func stopBridge() {
        WiwaveRequestGracefulShutdown()
    }
}
