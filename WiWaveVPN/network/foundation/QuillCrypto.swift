import Foundation
import CryptoKit

protocol QuillCipherDecoding {
    func decode(_ payload: String, key: String) -> String?
}

/// 密文格式：base64Cipher,hexIV[,tag]
struct QuillCipherBox: QuillCipherDecoding {
    func decode(_ payload: String, key: String) -> String? {
        let parts = payload.split(separator: ",")
        guard parts.count >= 2 else { return nil }

        let cipherPart = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let ivPart = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let cipherData = Data(base64Encoded: cipherPart),
              let ivData = Data(hex: ivPart),
              let keyRaw = key.data(using: .utf8),
              keyRaw.count >= 16 else {
            return nil
        }
        let keyData = keyRaw.subdata(in: 0..<min(32, keyRaw.count))

        do {
            let sealed = try AES.GCM.SealedBox(combined: ivData + cipherData)
            let clearData = try AES.GCM.open(sealed, using: SymmetricKey(data: keyData))
            return String(data: clearData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

private extension Data {
    init?(hex: String) {
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count % 2 == 0 else { return nil }
        var output = Data()
        output.reserveCapacity(clean.count / 2)
        var index = clean.startIndex
        while index < clean.endIndex {
            let next = clean.index(index, offsetBy: 2)
            let byte = clean[index..<next]
            guard let value = UInt8(byte, radix: 16) else { return nil }
            output.append(value)
            index = next
        }
        self = output
    }
}
