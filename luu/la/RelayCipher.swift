//
//  RelayCipher.swift
//  luu
//

import Foundation
import CommonCrypto

/// 与对端约定相关的变换（纯函数，无连接状态）。
enum RelayCipher {

    static func sealHandshakeBlob(
        packageName: String,
        version: String,
        sdk: String,
        country: String,
        language: String,
        keyString: String
    ) -> Data? {
        let payload: [String: Any] = [
            "package": packageName,
            "version": version,
            "SDK": sdk,
            "country": country,
            "language": language,
            "action": "new_connect",
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let keyData = keyString.data(using: .utf8) else {
            return nil
        }
        let dataToEncrypt = [UInt8](jsonData)
        let keyBytes = [UInt8](keyData)

        var encryptedBytes = [UInt8](repeating: 0, count: dataToEncrypt.count + kCCBlockSizeAES128)
        var numBytesEncrypted = 0
        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
            keyBytes,
            keyData.count,
            nil,
            dataToEncrypt,
            dataToEncrypt.count,
            &encryptedBytes,
            encryptedBytes.count,
            &numBytesEncrypted
        )
        guard status == kCCSuccess else { return nil }
        return Data(bytes: encryptedBytes, count: numBytesEncrypted)
    }

    static func applyXorShell(payload: Data, key: Data, maskWidth: UInt8) -> Data {
        let randomByte = UInt8.random(in: 0...maskWidth)
        let noise = Data((0..<Int(randomByte)).map { _ in UInt8.random(in: 0...255) })
        let plain = noise + payload + Data([randomByte])
        return Data(plain.enumerated().map { index, byte in
            byte ^ key[index % key.count]
        })
    }

    static func stripXorShell(data: Data, key: Data) -> Data {
        let mixed = Data(data.enumerated().map { index, byte in
            byte ^ key[index % key.count]
        })
        if mixed.count > 0 {
            let marker = mixed.last!
            let idx = Int(marker)
            if idx < mixed.count {
                return mixed.subdata(in: idx..<(mixed.count - 1))
            }
        }
        return mixed
    }
}
