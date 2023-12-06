import BigInt
import BitcoinCore
import Foundation

class ProofOfWorkValidator: IBlockValidator {
    var hasher: (Data) -> Data
    private let difficultyEncoder: IDifficultyEncoder

    init(hasher: @escaping (Data) -> Data, difficultyEncoder: IDifficultyEncoder) {
        self.hasher = hasher
        self.difficultyEncoder = difficultyEncoder
    }

    private func serializeHeader(block: Block) -> Data {
        var data = Data()

        data.append(Data(from: UInt32(block.version)))
        data += block.previousBlockHash
        data += block.merkleRoot
        data.append(Data(from: UInt32(block.timestamp)))
        data.append(Data(from: UInt32(block.bits)))
        data.append(Data(from: UInt32(block.nonce)))

        return data
    }

    func validate(block: Block, previousBlock _: Block) throws {
        let header = serializeHeader(block: block)
        let hash = hasher(header)

        guard difficultyEncoder.compactFrom(hash: hash) < block.bits else {
            throw BitcoinCoreErrors.BlockValidation.invalidProofOfWork
        }
    }
}
