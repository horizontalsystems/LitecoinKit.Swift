import Foundation
import LitecoinKit
import BitcoinCore
import HdWalletKit
import HsToolKit
import RxSwift

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
        transactionsSignal.notify()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSignal.notify()
    }

    func balanceUpdated(balance: BalanceInfo) {
        balanceSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSignal.notify()
    }

}
