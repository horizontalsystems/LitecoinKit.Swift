import BitcoinCore

class TestNet: INetwork {
    let bundleName = "Litecoin"

    let pubKeyHash: UInt8 = 0x6F
    let privateKey: UInt8 = 0xEF
    let scriptHash: UInt8 = 0x3A
    let bech32PrefixPattern: String = "tltc"
    let xPubKey: UInt32 = 0x0435_87CF
    let xPrivKey: UInt32 = 0x0435_8394
    let magic: UInt32 = 0xFDD2_C8F1
    let port = 19335
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = false
    var blockchairChainId: String = ""

    let dnsSeeds = [
        "testnet-seed.ltc.xurious.com",
        "seed-b.litecoin.loshan.co.uk",
        "dnsseed-testnet.thrasher.io",
    ]

    let dustRelayTxFee = 3000 // https://github.com/bitcoin/bitcoin/blob/c536dfbcb00fb15963bf5d507b7017c241718bf6/src/policy/policy.h#L50
}
