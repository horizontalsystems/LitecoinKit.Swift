import Foundation
import BitcoinCore
import Scrypt


class ScryptHasher: IHasher {

    init() {}

    func hash(data: Data) -> Data {
        let bytes = try? Scrypt.scrypt(password: data.bytes, salt: data.bytes, length: 32, N: 1024, r: 1, p: 1)
        
        return Data(bytes ?? [])
    }

}
