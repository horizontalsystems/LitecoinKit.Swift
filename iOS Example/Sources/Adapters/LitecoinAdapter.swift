import LitecoinKit
import BitcoinCore
import HsToolKit
import HdWalletKit

class LitecoinAdapter: BaseAdapter {
    let litecoinKit: Kit

    init(words: [String], purpose: Purpose, testMode: Bool, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        guard let seed = Mnemonic.seed(mnemonic: words) else {
            fatalError("Can't Create Seed")
        }

        litecoinKit = try! Kit(seed: seed, purpose: purpose, walletId: "walletId", syncMode: syncMode, networkType: networkType, confirmationsThreshold: 1, logger: logger.scoped(with: "LitecoinKit"))

        super.init(name: "Litecoin", coinCode: "LTC", abstractKit: litecoinKit)
        litecoinKit.delegate = self
    }

    class func clear() {
        try? Kit.clear()
    }
}

extension LitecoinAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSubject.send()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSubject.send()
    }

    func balanceUpdated(balance: BalanceInfo) {
        balanceSubject.send()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSubject.send()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSubject.send()
    }

}
