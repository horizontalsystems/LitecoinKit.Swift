# LitecoinKit.Swift

Litecoin wallet toolkit for Swift. This is a full implementation of SPV node including wallet creation/restore, synchronization with network, send/receive transactions, and more.

## Features

- Full SPV implementation for fast mobile performance
- [BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) hierarchical deterministic wallets implementation.
- [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) mnemonic code for generating deterministic keys.
- [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) multi-account hierarchy for deterministic wallets.
- [BIP21](https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki) URI schemes, which include payment address, amount, label and other params

### LitecoinKit.swift
- base58

## Usage

### Initialization

*Kit* requires you to provide mnemonic phrase when it is initialized:

```swift
let words = ["word1", ... , "word12"]
```

#### Litecoin

```swift
let litecoinKit = LitecoinKit(withWords: words, walletId: "bitcoin-wallet-id", syncMode: .api, networkType: .mainNet)
```

*Kit* can be configured to work in `.mainNet` or `.testNet`. 

##### `syncMode` parameter
*Kit* can restore existing wallet or create a new one. When restoring, it generates addresses for given wallet according to bip44 protocol, then it pulls all historical transactions for each of those addresses. This is done only once on initial sync. `syncMode` parameter defines where it pulls historical transactions from. When they are pulled, it continues to sync according to [SPV](https://en.bitcoinwiki.org/wiki/Simplified_Payment_Verification) protocol no matter which syncMode was used for initial sync. There are 3 modes available:

- `.full`: Fully synchronizes from peer-to-peer network starting from the block when bip44 was introduced. This mode is the most private (since it fully complies with [SPV](https://en.bitcoinwiki.org/wiki/Simplified_Payment_Verification) protocol), but it takes approximately 2 hours to sync up to now (June 10, 2019).
- `.api`: Transactions before checkpoint are pulled from API(currently [Insight API](https://github.com/bitpay/insight-api) or [BcoinAPI](http://bcoin.io/api-docs/)). Then the rest is synchronized from peer-to-peer network. This is the fastest one, but it's possible for an attacker to learn which addresses you own. Checkpoints are updated with each new release and hardcoded so the blocks validation is not broken.
- `.newWallet`: No need to pull transactions.

##### Additional parameters:
- `confirmationsThreshold`: Minimum number of confirmations required for an unspent output in incoming transaction to be spent (*default: 6*)
- `minLogLevel`: Can be configured for debug purposes if required.

### Starting and Stopping

*Kit* require to be started with `start` command. It will be in synced state as long as it is possible. You can call `stop` to stop it

```swift
litecoinKit.start()
litecoinKit.stop()
```

### Getting wallet data

*Kit* hold all kinds of data obtained from and needed for working with blockchain network

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 13+

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code
and is integrated into the `swift` compiler. It is in early development, but DashCryptoKit does support its use on
supported platforms.

Once you have your Swift package set up, adding DashCryptoKit as a dependency is as easy as adding it to
the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/LitecoinKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Example Project

All features of the library are used in example project. It can be referred as a starting point for usage of the library.

## License

The `LitecoinKit` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/LitecoinKit.Swift/blob/master/LICENSE).

