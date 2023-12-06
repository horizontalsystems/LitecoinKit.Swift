import BitcoinCore
import Foundation
import HdWalletKit
import HsToolKit
import Scrypt

public class Kit: AbstractKit {
    private static let heightInterval = 2016 // Default block count in difficulty change circle
    private static let targetSpacing = Int(2.5 * 60) // Time to mining one block
    private static let maxTargetBits = 0x1E0F_FFFF // Initially and max. target difficulty for blocks

    public static let defaultScryptParams = (length: 32, N: UInt64(1024), r: UInt32(1), p: UInt32(1))
    static let defaultHasher: (Data) -> Data = { data in
        let pass = data.hs.bytes
        let bytes = try? Scrypt.scrypt(
            password: pass,
            salt: pass,
            length: defaultScryptParams.length,
            N: defaultScryptParams.N,
            r: defaultScryptParams.r,
            p: defaultScryptParams.p
        )
        return Data(bytes ?? [])
    }

    private static let name = "LitecoinKit"

    public enum NetworkType: String, CaseIterable {
        case mainNet, testNet

        var network: INetwork {
            switch self {
            case .mainNet:
                return MainNet()
            case .testNet:
                return TestNet()
            }
        }
    }

    public weak var delegate: BitcoinCoreDelegate? {
        didSet {
            bitcoinCore.delegate = delegate
        }
    }

    private init(extendedKey: HDExtendedKey?, watchAddressPublicKey: WatchAddressPublicKey?, purpose: Purpose, walletId: String, syncMode: BitcoinCore.SyncMode = .api, hasher: ((Data) -> Data)?, networkType: NetworkType = .mainNet, confirmationsThreshold: Int = 6, logger: Logger?) throws {
        let network = networkType.network
        let logger = logger ?? Logger(minLogLevel: .verbose)
        let databaseFilePath = try DirectoryHelper.directoryURL(for: Kit.name).appendingPathComponent(Kit.databaseFileName(walletId: walletId, networkType: networkType, purpose: purpose, syncMode: syncMode)).path
        let storage = GrdbStorage(databaseFilePath: databaseFilePath)
        let apiSyncStateManager = ApiSyncStateManager(storage: storage, restoreFromApi: network.syncableFromApi && syncMode != BitcoinCore.SyncMode.full)

        let apiTransactionProvider: IApiTransactionProvider
        switch networkType {
        case .mainNet:
            let apiTransactionProviderUrl = "https://ltc.blocksdecoded.com/api"

            if case let .blockchair(key) = syncMode {
                let blockchairApi = BlockchairApi(secretKey: key, chainId: network.blockchairChainId, logger: logger)
                let blockchairBlockHashFetcher = BlockchairBlockHashFetcher(blockchairApi: blockchairApi)
                let blockchairProvider = BlockchairTransactionProvider(blockchairApi: blockchairApi, blockHashFetcher: blockchairBlockHashFetcher)
                let bCoinApiProvider = BCoinApi(url: apiTransactionProviderUrl, logger: logger)

                apiTransactionProvider = BiApiBlockProvider(restoreProvider: bCoinApiProvider, syncProvider: blockchairProvider, apiSyncStateManager: apiSyncStateManager)
            } else {
                apiTransactionProvider = BCoinApi(url: apiTransactionProviderUrl, logger: logger)
            }

        case .testNet:
            apiTransactionProvider = BCoinApi(url: "", logger: logger)
        }

        let paymentAddressParser = PaymentAddressParser(validScheme: "litecoin", removeScheme: true)
        let difficultyEncoder = DifficultyEncoder()

        let blockValidatorSet = BlockValidatorSet()
        let hasher = hasher ?? Self.defaultHasher
        blockValidatorSet.add(blockValidator: ProofOfWorkValidator(hasher: hasher, difficultyEncoder: difficultyEncoder))

        let blockValidatorChain = BlockValidatorChain()
        let blockHelper = BlockValidatorHelper(storage: storage)

        let difficultyAdjustmentValidator = LegacyDifficultyAdjustmentValidator(
            encoder: difficultyEncoder,
            blockValidatorHelper: blockHelper,
            heightInterval: Kit.heightInterval,
            targetTimespan: Kit.heightInterval * Kit.targetSpacing,
            maxTargetBits: Kit.maxTargetBits
        )

        switch networkType {
        case .mainNet:
            blockValidatorChain.add(blockValidator: difficultyAdjustmentValidator)
            blockValidatorChain.add(blockValidator: BitsValidator())
        case .testNet:
            blockValidatorChain.add(blockValidator: difficultyAdjustmentValidator)
            blockValidatorChain.add(blockValidator: LegacyTestNetDifficultyValidator(blockHelper: blockHelper, heightInterval: Kit.heightInterval, targetSpacing: Kit.targetSpacing, maxTargetBits: Kit.maxTargetBits))
        }

        blockValidatorSet.add(blockValidator: blockValidatorChain)

        let bitcoinCore = try BitcoinCoreBuilder(logger: logger)
            .set(network: network)
            .set(apiTransactionProvider: apiTransactionProvider)
            .set(checkpoint: Checkpoint.resolveCheckpoint(network: network, syncMode: syncMode, storage: storage))
            .set(apiSyncStateManager: apiSyncStateManager)
            .set(extendedKey: extendedKey)
            .set(watchAddressPublicKey: watchAddressPublicKey)
            .set(paymentAddressParser: paymentAddressParser)
            .set(walletId: walletId)
            .set(confirmationsThreshold: confirmationsThreshold)
            .set(peerSize: 10)
            .set(syncMode: syncMode)
            .set(storage: storage)
            .set(blockValidator: blockValidatorSet)
            .set(purpose: purpose)
            .build()

        super.init(bitcoinCore: bitcoinCore, network: network)

        let base58AddressConverter = Base58AddressConverter(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash)

        switch purpose {
        case .bip44:
            bitcoinCore.add(restoreKeyConverter: Bip44RestoreKeyConverter(addressConverter: base58AddressConverter))
        case .bip49:
            bitcoinCore.add(restoreKeyConverter: Bip49RestoreKeyConverter(addressConverter: base58AddressConverter))
        case .bip84:
            bitcoinCore.add(restoreKeyConverter: KeyHashRestoreKeyConverter(scriptType: .p2wpkh))
        case .bip86:
            bitcoinCore.add(restoreKeyConverter: KeyHashRestoreKeyConverter(scriptType: .p2tr))
        }
    }

    public convenience init(seed: Data, purpose: Purpose, walletId: String, syncMode: BitcoinCore.SyncMode = .api, hasher: ((Data) -> Data)?, networkType: NetworkType = .mainNet, confirmationsThreshold: Int = 6, logger: Logger?) throws {
        let version: HDExtendedKeyVersion
        switch purpose {
        case .bip44: version = .Ltpv
        case .bip49: version = .Mtpv
        case .bip84: version = .zprv
        case .bip86: version = .xprv
        }
        let masterPrivateKey = HDPrivateKey(seed: seed, xPrivKey: version.rawValue)

        try self.init(
            extendedKey: .private(key: masterPrivateKey),
            purpose: purpose,
            walletId: walletId,
            syncMode: syncMode,
            hasher: hasher,
            networkType: networkType,
            confirmationsThreshold: confirmationsThreshold,
            logger: logger
        )
    }

    public convenience init(extendedKey: HDExtendedKey, purpose: Purpose, walletId: String, syncMode: BitcoinCore.SyncMode = .api, hasher: ((Data) -> Data)?, networkType: NetworkType = .mainNet, confirmationsThreshold: Int = 6, logger: Logger?) throws {
        let network = networkType.network

        try self.init(extendedKey: extendedKey, watchAddressPublicKey: nil,
                      purpose: purpose,
                      walletId: walletId,
                      syncMode: syncMode,
                      hasher: hasher,
                      networkType: networkType,
                      confirmationsThreshold: confirmationsThreshold,
                      logger: logger)

        let scriptConverter = ScriptConverter()
        let bech32AddressConverter = SegWitBech32AddressConverter(prefix: network.bech32PrefixPattern, scriptConverter: scriptConverter)

        bitcoinCore.prepend(addressConverter: bech32AddressConverter)
    }

    public convenience init(watchAddress: String, purpose: Purpose, walletId: String, syncMode: BitcoinCore.SyncMode = .api, hasher: ((Data) -> Data)?, networkType: NetworkType = .mainNet, confirmationsThreshold: Int = 6, logger: Logger?) throws {
        let network = networkType.network
        let scriptConverter = ScriptConverter()
        let bech32AddressConverter = SegWitBech32AddressConverter(prefix: network.bech32PrefixPattern, scriptConverter: scriptConverter)
        let base58AddressConverter = Base58AddressConverter(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash)
        let parserChain = AddressConverterChain()
        parserChain.prepend(addressConverter: base58AddressConverter)
        parserChain.prepend(addressConverter: bech32AddressConverter)

        let address = try parserChain.convert(address: watchAddress)
        let publicKey = try WatchAddressPublicKey(data: address.lockingScriptPayload, scriptType: address.scriptType)

        try self.init(extendedKey: nil, watchAddressPublicKey: publicKey,
                      purpose: purpose,
                      walletId: walletId,
                      syncMode: syncMode,
                      hasher: hasher,
                      networkType: networkType,
                      confirmationsThreshold: confirmationsThreshold,
                      logger: logger)

        bitcoinCore.prepend(addressConverter: bech32AddressConverter)
    }
}

extension Kit {
    public static func clear(exceptFor walletIdsToExclude: [String] = []) throws {
        try DirectoryHelper.removeAll(inDirectory: Kit.name, except: walletIdsToExclude)
    }

    private static func databaseFileName(walletId: String, networkType: NetworkType, purpose: Purpose, syncMode: BitcoinCore.SyncMode) -> String {
        "\(walletId)-\(networkType.rawValue)-\(purpose.description)-\(syncMode)"
    }
}
