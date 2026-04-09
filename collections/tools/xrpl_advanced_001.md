# Recon Collection — XRPL Advanced Features
> File: tools/xrpl_advanced_001.md | Schema: v2 | Created: 2026-04-09
> Entries: RECON-T-017 through RECON-T-021

---

## RECON-T-017

```
ID:             RECON-T-017
TYPE:           tool
TITLE:          XRPL Escrow — time-based and condition-based locking
SUMMARY:        Escrow locks XRP (not tokens) in a ledger object that releases only when specified conditions are met. Two condition types: (1) time-based — uses FinishAfter and/or CancelAfter fields with ledger close time (Unix seconds); (2) condition-based — uses a crypto-condition (RFC 3005 PREIMAGE-SHA-256) where the escrow is released by providing the preimage that hashes to the stored condition. Both types can be combined. Escrow is created with EscrowCreate, completed with EscrowFinish, and cancelled after expiry with EscrowCancel. The locked XRP is removed from the creator's spendable balance but still counts against reserve thresholds.
KEY_INSIGHT:    Use time-based escrow for vesting schedules, grant cliffs, or delayed payments. Use condition-based escrow for atomic swaps — the fulfillment preimage is revealed only when the counterparty action is verified off-chain. Always set CancelAfter for condition-based escrows or the XRP can be locked permanently if the preimage is lost.
CATEGORY:       knowledge
TAGS:           xrpl, escrow, escrowcreate, escrowfinish, time-lock, crypto-condition, atomic-swap, xrp
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-002, RECON-T-007, RECON-T-018
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development, automation
NOTES:          Escrow only works for XRP — not tokens. Each EscrowCreate costs the standard transaction fee plus increases the owner reserve by 1 object (2 XRP). The Condition field accepts a hex-encoded PREIMAGE-SHA-256 crypto-condition. Use the five-bells/crypto-conditions library (JS) or cryptoconditions (Python) to generate conditions and fulfillments. Ledger time is not wall time — use rippled's ledger_time, not system clock, for FinishAfter calculations.
```

---

## RECON-T-018

```
ID:             RECON-T-018
TYPE:           tool
TITLE:          XRPL Payment Channels — streaming micropayments off-ledger
SUMMARY:        Payment channels allow two parties to stream XRP micropayments off-ledger, settling only the final net balance on-chain. The sender opens a channel with PaymentChannelCreate (depositing XRP into it), then issues signed claims off-ledger incrementing the cumulative amount. The recipient can submit any claim to the ledger at any time via PaymentChannelClaim to collect XRP. The sender can close the channel after an expiry window with PaymentChannelFund or PaymentChannelCreate's Expiration. Net cost: 2 transactions (open + close) regardless of how many off-chain payments occurred.
KEY_INSIGHT:    Payment channels are XRPL's solution for pay-per-use APIs, streaming media, and high-frequency micropayments — anything where per-transaction fees would make individual payments uneconomical. The sender issues claims (signatures over cumulative amount); the recipient collects by submitting the highest claim they hold. Always verify the claim signature off-chain before delivering the service.
CATEGORY:       knowledge
TAGS:           xrpl, payment-channel, micropayment, streaming, off-chain, claim, paychan
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-007, RECON-T-017, RECON-T-002
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development, automation
NOTES:          Payment channels are directional — sender → recipient. For bidirectional streaming, open two channels. Claims are cumulative: a claim for 100 XRP supersedes one for 50 XRP. The recipient should track the highest valid claim received; submitting lower claims wastes fees. Channel expiry requires sender to explicitly close; the channel stays open until closed even after Expiration if neither party acts.
```

---

## RECON-T-019

```
ID:             RECON-T-019
TYPE:           tool
TITLE:          XRPL NFTs — XLS-20 minting, offers, and royalties
SUMMARY:        XLS-20 (live on mainnet since 2022) adds native NFT support to XRPL via four transaction types: NFTokenMint, NFTokenBurn, NFTokenCreateOffer, and NFTokenAcceptOffer. Each NFToken is stored on the minter's account in a NFTokenPage ledger object (fits up to 32 tokens; additional pages cost 2 XRP reserve each). Royalties (transfer fees) are set at mint as a per-mil value (0–50,000 = 0%–50%) applied on every secondary sale when transferable flag is set. The Taxon field is a free-form integer for collection grouping. Transfers require a broker or direct offer-accept flow — there is no single transfer transaction.
KEY_INSIGHT:    Minting an NFT is cheap (standard tx fee) but HOLDING NFTs costs reserve: each NFTokenPage holds up to 32 NFTs and costs 2 XRP reserve. A collection of 33 NFTs = 4 XRP in locked reserve (2 pages). Build this into mint UX so buyers know what to expect. For marketplaces, use brokered offers: buyer creates an NFTokenCreateOffer (buy offer), seller creates a sell offer, and the marketplace submits NFTokenAcceptOffer with both offer IDs to collect a broker fee.
CATEGORY:       knowledge
TAGS:           xrpl, nft, xls-20, nftokenmint, royalty, transfer-fee, marketplace, nftokenpage
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-002, RECON-T-004, RECON-T-007
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       development
NOTES:          NFTokenID is deterministic: minter address + flags + transfer fee + taxon + sequence. The Flags field at mint is permanent — tfTransferable, tfBurnable, tfOnlyXRP cannot be changed after minting. tfOnlyXRP means offers must be denominated in XRP, not tokens. URI field is optional but standard for pointing to IPFS/Arweave metadata. Use xrpl.convertStringToHex for URI encoding.
```

---

## RECON-T-020

```
ID:             RECON-T-020
TYPE:           tool
TITLE:          XRPL Hooks — smart contract layer on Xahau (not XRPL mainnet)
SUMMARY:        Hooks are small WebAssembly programs that execute on-ledger in response to transactions. They are the primary smart contract mechanism on Xahau (the XRPL sidechain that forked to run Hooks natively) but are NOT live on XRPL mainnet as of 2026. The Hooks amendment for XRPL mainnet has been under development and review for several years but has not yet achieved validator consensus for mainnet activation. On Xahau, hooks can be installed on accounts and fire on incoming or outgoing transactions, executing logic like auto-forwarding, fee collection, allowlisting, or custom settlement rules.
KEY_INSIGHT:    Do not build production systems on XRPL mainnet that depend on Hooks — they do not exist there yet. If you need programmable on-ledger logic on an XRPL-derived chain NOW, build on Xahau. If you need smart contracts on XRP-denominated rails and are willing to use Solidity, use XRPL EVM. Track the Hooks amendment status at xrpl.org/known-amendments before choosing an architecture.
CATEGORY:       knowledge
TAGS:           xrpl, hooks, xahau, smart-contracts, wasm, amendment, mainnet, evm-alternative
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-007, RECON-T-009, RECON-T-011
CHAIN:          xahau
TOOL:           xrpl.js, Hooks Builder (Xahau)
USE_CASE:       development
NOTES:          Xahau is a distinct ledger from XRPL mainnet — separate validators, separate XAH token (though XRP can be bridged). The XRPL Foundation has indicated Hooks remain a high priority but the amendment requires broad validator consensus. Hooks are written in C (compiled to WASM) or can use the hooks-builder toolkit. Hook execution is gas-metered to prevent infinite loops.
```

---

## RECON-T-021

```
ID:             RECON-T-021
TYPE:           tool
TITLE:          XRPL Multi-signing — threshold signatures for account security
SUMMARY:        Multi-signing on XRPL allows a set of authorized signers to collectively authorize a transaction, requiring a threshold (quorum) of signatures to meet a minimum weight. Configured via SignerListSet transaction which installs a SignerList object on the account — listing signer addresses and their weights. A quorum is the minimum total weight required. Transactions signed with a SignerList include each signer's signature in a Signers array field. Multi-signing increases transaction size and therefore fee (approximately +15 drops per signer). Can be combined with disabling the master key for true multi-party control.
KEY_INSIGHT:    Use multi-signing for any wallet that controls significant funds or issues tokens. A 2-of-3 SignerList means no single compromised key can drain the account. The standard pattern: one hot signer (automated trading key), two cold signers (hardware wallets held by different people), quorum = 2. Disable the master key after confirming the signer list works — any mistake in the list before disabling the master key can be recovered; after disabling, it cannot.
CATEGORY:       knowledge
TAGS:           xrpl, multi-signing, signerset, signerlist, quorum, security, key-management, multisig
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-002, RECON-S-001, RECON-S-002, RECON-S-005
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py, Xaman
USE_CASE:       security, development
NOTES:          Each signer in a SignerList must have a funded XRPL account — but the signing keys used do not have to be the account master keys; they can be regular keys set on each signer account. Maximum 8 signers per list. The SignerList itself costs 2 XRP owner reserve. When multi-signing is active and master key is disabled, even the account owner cannot act unilaterally — this is the point.
```
