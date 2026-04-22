import Foundation
import os

enum NodeCapsule {
    private static let directiveFile = "core.route.json"
    private static let relayFile = "core.relay.dat"
    private static let packedSeedText = [
        "OR2W43TFNQ5AUIBANV2HKORAHEYDAMAKONXWG23TGU5AUIBAOBXXE5B2EA4DAOBQBIQCAYLEMRZGK43THIQDUORRBIQCA5LEOA5CAJ3VMRYCOCTNNFZWGOQKEAQHIYLTNMWXG5DBMNVS243JPJSTUIBSGA2DQMAKEAQGG33ONZSWG5BNORUW2ZLPOV2DUIBVGAYDACRAEBZGKYLEFV3XE2LUMUWXI2LNMVXXK5B2EA3DAMBQGAFCAIDMN5TS2ZTJNRSTUIDTORSGK4TSBIQCA3DPM4WWYZLWMVWDUIDFOJZG64QK",
        "EAQGY2LNNF2C23TPMZUWYZJ2EA3DKNJTGU======",
    ].joined()

    static func composeDirective() -> String {
        composeDirectiveInner()
    }

    static func composeRelayPath() -> String {
        composeRelayPathInner()
    }

    private static var seedPlainText: String? {
        decodeSeed(packedSeedText)
    }

    private static func decodeSeed(_ source: String) -> String? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bitCount = 0
        var accumulator = 0
        var output = Data()
        for symbol in source.uppercased() {
            if symbol == "=" { break }
            guard let idx = alphabet.firstIndex(of: symbol)?.encodedOffset else { return nil }
            accumulator = (accumulator << 5) | idx
            bitCount += 5
            while bitCount >= 8 {
                bitCount -= 8
                output.append(UInt8((accumulator >> bitCount) & 0xFF))
            }
        }
        return String(data: output, encoding: .utf8)
    }

    private static func sharedRoutePayload() -> String {
        let laneDefaults = UserDefaults(suiteName: FluxLatch.lane)
        return laneDefaults?.string(forKey: FluxLatch.payloadSlot) ?? ""
    }

    private static func seedBlob() -> Data? {
        seedPlainText?.data(using: .utf8)
    }

    private static func documentsRoot() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static func writeBlob(name: String, data: Data?) -> URL {
        let target = documentsRoot().appendingPathComponent(name)
        do {
            try data?.write(to: target)
        } catch {
            os_log("[nc] %{public}@", log: OSLog.default, type: .error, "write fail: \(error.localizedDescription)")
        }
        return target
    }

    private static func persistDirective(_ routeRaw: String) -> URL {
        writeBlob(name: directiveFile, data: routeRaw.data(using: .utf8))
    }

    private static func persistRelay(_ relayData: Data?) -> URL {
        writeBlob(name: relayFile, data: relayData)
    }

    private static func envelope(path: URL) -> String {
        """
        {
            "datDir": "",
            "configPath": "\(path.path)",
            "maxMemory": \(31457280)
        }
        """
    }

    private static func composeDirectiveInner() -> String {
        let routeRaw = sharedRoutePayload()
        let routeURL = persistDirective(routeRaw)
        return envelope(path: routeURL)
    }

    private static func composeRelayPathInner() -> String {
        let relayData = seedBlob()
        let relayURL = persistRelay(relayData)
        return relayURL.path
    }
}
