# Collection: XRPL EVM Sidechain
> File: tools/xrpl_evm_001.md | Schema: v2 | Date: 2026-04-09
> Source: Official XRPL EVM docs (docs.xrplevm.org) — Tier 1 primary reference
> Purpose: Foundation knowledge for Society Libraries — XRPL EVM bucket

---

## RECON-T-009

```
ID:             RECON-T-009
TYPE:           platform
TITLE:          XRPL EVM Sidechain — what it is and how it differs from XRPL mainnet
SUMMARY:        The XRPL EVM Sidechain is a standalone Layer 1 blockchain built on Cosmos SDK, EVM-compatible, using XRP as its native gas token. It is a separate chain from XRPL mainnet — not a layer-2 or rollup. It supports Solidity smart contracts, Ethereum-compatible tooling (MetaMask, Hardhat, Foundry, ethers.js, viem), and connects to XRPL mainnet via bridges.
KEY_INSIGHT:    XRPL EVM and XRPL mainnet are two separate chains. Value moves between them via bridges — it does not exist on both simultaneously. Builders must choose their environment deliberately: mainnet for native XRPL primitives, EVM for smart contract flexibility.
CATEGORY:       onboarding
TAGS:           xrpl-evm, sidechain, cosmos-sdk, evm, solidity, xrp-gas, layer1, bridge
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-010, RECON-T-011, RECON-T-001
CHAIN:          evm
TOOL:           xrpl-evm
USE_CASE:       onboarding
NOTES:          The mainnet vs EVM distinction is the #1 conceptual blocker for new XRPL ecosystem builders. Must be clear in all onboarding content.
```

---

## RECON-T-010

```
ID:             RECON-T-010
TYPE:           guide
TITLE:          XRPL EVM user setup — wallet, network, and gas
SUMMARY:        XRPL EVM users need an EVM-compatible wallet (MetaMask, Keplr, or similar). Add the XRPL EVM network configuration (RPC URL, chain ID, currency symbol XRP). Obtain XRP on the sidechain for gas — either via bridge from XRPL mainnet or from an exchange/faucet. Then interact with contracts and apps as with any EVM chain.
KEY_INSIGHT:    The XRPL EVM user experience is familiar to any Ethereum user — same wallets, same tooling, same mental model. The only friction point is getting XRP onto the sidechain for gas, which requires either bridge usage or a direct sidechain source.
CATEGORY:       onboarding
TAGS:           xrpl-evm, metamask, keplr, network-config, gas, xrp, bridge, user-setup
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-009, RECON-T-011
CHAIN:          evm
TOOL:           xrpl-evm, metamask
USE_CASE:       onboarding
NOTES:          Network config (RPC URL, chain ID) should be documented with current mainnet and testnet values. These change — always reference official docs for current values.
```

---

## RECON-T-011

```
ID:             RECON-T-011
TYPE:           platform
TITLE:          XRPL EVM builder setup — tooling and deployment
SUMMARY:        XRPL EVM supports standard EVM developer tooling: Hardhat, Foundry, Remix, ethers.js, viem, wagmi. Smart contracts are Solidity. Deploy using standard EVM deployment flows pointed at XRPL EVM RPC. XRP is the gas token. Official deployed contract addresses (bridges, wrapped tokens) are documented in the XRPL EVM docs for mainnet and testnet.
KEY_INSIGHT:    For Ethereum builders, XRPL EVM requires almost no new learning — existing tooling works as-is. The adjustment is understanding XRP as gas (not ETH) and being aware of the bridge infrastructure for cross-chain value movement.
CATEGORY:       tools
TAGS:           xrpl-evm, solidity, hardhat, foundry, ethers-js, viem, deployment, smart-contracts, xrp-gas
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-009, RECON-T-010, RECON-T-012
CHAIN:          evm
TOOL:           xrpl-evm, hardhat, foundry
USE_CASE:       development
NOTES:          Always reference official deployed contract addresses from docs.xrplevm.org — do not hardcode from memory.
```

---

## RECON-T-012

```
ID:             RECON-T-012
TYPE:           platform
TITLE:          XRPL ↔ XRPL EVM bridge — moving value between chains
SUMMARY:        Value moves between XRPL mainnet and XRPL EVM via bridges. The bridge locks assets on one side (locking chain) and issues wrapped representations on the other (issuing chain). XRP can be bridged in both directions. The Axelar bridge handles cross-chain messaging. Bridge transactions require specific memo formats and gas awareness on both sides.
KEY_INSIGHT:    Bridging is not instant or free — it requires gas on both chains, has specific transaction formats, and introduces latency. Applications that depend on bridged assets must account for bridge delays and potential failures in their UX and error handling.
CATEGORY:       tools
TAGS:           xrpl, xrpl-evm, bridge, axelar, locking-chain, issuing-chain, cross-chain, wrapped-tokens
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     8
FREQUENCY:      1
PRIORITY:       8.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-009, RECON-T-011
CHAIN:          multi
TOOL:           xrpl-evm, axelar
USE_CASE:       development
NOTES:          Bridge failures are a confirmed failure pattern in cross-chain applications. Future RECON-F entry needed on bridge error handling.
```
