import Foundation
import BitcoinCore
import HsExtensions
import Scrypt


class ScryptHasher: IHasher {

    init() {}

    func hash(data: Data) -> Data {
        let pass = data.hs.bytes
        let bytes = try? Scrypt.scrypt(password: pass, salt: pass, length: 32, N: 1024, r: 1, p: 1)
        return Data(bytes ?? [])
    }

}
