import BitcoinCore
import Combine
import Foundation
import HsToolKit

class Manager {
    static let shared = Manager()
    private static let syncModes: [BitcoinCore.SyncMode] = [.full, .api, .newWallet]

    private let keyWords = "mnemonic_words"
    private let syncModeKey = "syncMode"

    let adapterSubject = PassthroughSubject<Void, Never>()
    var adapters = [BaseAdapter]()

    init() {
        if let words = savedWords, let syncModeIndex = savedSyncModeIndex {
            DispatchQueue.global(qos: .userInitiated).async {
                self.initAdapters(words: words, syncMode: Manager.syncModes[syncModeIndex])
            }
        }
    }

    func login(words: [String], syncModeIndex: Int) {
        save(words: words)
        save(syncModeIndex: syncModeIndex)
        clearKits()

        DispatchQueue.global(qos: .userInitiated).async {
            self.initAdapters(words: words, syncMode: Manager.syncModes[syncModeIndex])
        }
    }

    func logout() {
        clearUserDefaults()
        adapters = []
    }

    private func initAdapters(words: [String], syncMode: BitcoinCore.SyncMode) {
        let configuration = Configuration.shared
        let logger = Logger(minLogLevel: Configuration.shared.minLogLevel)

        adapters = [
            LitecoinAdapter(words: words, purpose: .bip44, testMode: configuration.testNet, syncMode: syncMode, logger: logger),
        ]

        adapterSubject.send()
    }

    var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    var savedSyncModeIndex: Int? {
        if let syncModeIndex = UserDefaults.standard.value(forKey: syncModeKey) as? Int {
            return syncModeIndex
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(syncModeIndex: Int) {
        UserDefaults.standard.set(syncModeIndex, forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearKits() {
        LitecoinAdapter.clear()
    }
}
