import BitcoinCore

public class MainNet: INetwork {
    public let bundleName = "Litecoin"

    public let pubKeyHash: UInt8 = 0x30
    public let privateKey: UInt8 = 0xB0
    public let scriptHash: UInt8 = 0x32
    public let bech32PrefixPattern: String = "ltc"
    public let xPubKey: UInt32 = 0x0488_B21E
    public let xPrivKey: UInt32 = 0x0488_ADE4
    public let magic: UInt32 = 0xFBC0_B6DB
    public let port = 9333
    public let coinType: UInt32 = 2
    public let sigHash: SigHashType = .bitcoinAll
    public var syncableFromApi: Bool = true
    public var blockchairChainId: String = "litecoin"

    public let dnsSeeds = [
        "x5.dnsseed.thrasher.io",
        "x5.dnsseed.litecointools.com",
        "x5.dnsseed.litecoinpool.org",
        "seed-a.litecoin.loshan.co.uk",
    ]

    public let dustRelayTxFee = 3000

    public init() {}
}
