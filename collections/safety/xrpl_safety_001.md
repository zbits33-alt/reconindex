# Recon Collection — XRPL Safety
> File: safety/xrpl_safety_001.md | Schema: v2 | Created: 2026-04-09
> Entries: RECON-S-001 through RECON-S-005

---

## RECON-S-001

```
ID:             RECON-S-001
TYPE:           safety
TITLE:          Hot/warm/cold wallet architecture for XRPL token issuers
SUMMARY:        Token issuers on XRPL should use a three-tier wallet architecture to limit blast radius from key compromise. Cold wallet: master key never touches an internet-connected device; holds issuer account, sets trust lines and account flags, rarely transacts. Warm wallet: intermediate account for treasury operations like distributing tokens to exchanges; air-gapped or hardware-wallet-signed. Hot wallet: always online, handles routine outflows and bot operations; holds minimal XRP, only the tokens it needs to move. The cold wallet issues tokens to the warm wallet; the warm wallet distributes to hot wallets and exchanges.
KEY_INSIGHT:    The cold issuer wallet's master key should be generated offline, stored encrypted on paper or hardware, and NEVER imported into any internet-connected tool. Every token in existence was issued by this key — compromise means an attacker can mint unlimited supply. Treat the cold key as a physical asset, not a software credential.
CATEGORY:       safety
TAGS:           xrpl, security, cold-wallet, hot-wallet, warm-wallet, issuer, key-management, architecture
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-004, RECON-T-002, RECON-S-002, RECON-S-005, RECON-T-021
CHAIN:          xrpl
TOOL:           Xaman, xrpl.js, xrpl-py
USE_CASE:       security
NOTES:          Good practice: after issuing an initial supply, set the cold wallet AccountRoot flag asfNoFreeze (if appropriate) and asfDefaultRipple, then set a regular key (warm wallet) for any future administrative operations, and disable the master key entirely. This means even physical theft of the cold wallet seed cannot produce new signatures.
```

---

## RECON-S-002

```
ID:             RECON-S-002
TYPE:           safety
TITLE:          XRPL key management — master key, regular key, and disabling master
SUMMARY:        Every XRPL account has a master key pair derived from its seed. The master key is omnipotent — it can sign any transaction including disabling itself. A regular key is an alternative signing key that can be added via SetRegularKey and can sign most transactions (excluding certain account operations). Once a regular key is set, the master key can be disabled with AccountSet + asfDisableMaster flag, preventing it from signing. This is the foundation of all advanced key security on XRPL: bots use regular keys, master keys go cold.
KEY_INSIGHT:    Never leave a funded production account using only its master key for day-to-day operations. Set a regular key for automation and disable the master key. If the regular key is compromised, the attacker can drain funds but cannot disable the master key — you can rotate out by signing a SetRegularKey transaction with the master key from cold storage. This asymmetry is your recovery path.
CATEGORY:       safety
TAGS:           xrpl, master-key, regular-key, setregularkey, disable-master, key-rotation, security
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-S-001, RECON-S-005, RECON-T-021, RECON-T-002
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py, Xaman
USE_CASE:       security
NOTES:          asfDisableMaster is set in AccountSet.SetFlag. To re-enable master key later, you must still have access to either the master key (if not disabled) or the current regular key. There is no recovery path if both are lost — XRPL has no account recovery mechanism. Test key rotation on a testnet account before touching mainnet. Disabling master key + multi-signing is the maximum security configuration.
```

---

## RECON-S-003

```
ID:             RECON-S-003
TYPE:           safety
TITLE:          Common XRPL scam patterns — fake airdrops, trust line attacks, and social engineering
SUMMARY:        Three primary attack vectors target XRPL users: (1) Fake airdrop scams — a token is force-sent to accounts via a trust line the victim didn't set, then the victim is invited to "claim" rewards by signing a transaction that actually drains their XRP or grants token approval. (2) Trust line fee traps — malicious tokens have nonstandard transfer fees set at the issuer level; buying 100 tokens costs more than 100 tokens worth of XRP due to hidden fees. (3) Social engineering — support impersonators ask for seeds or private keys, often posing as XRPLClaw, Ripple, or Xaman staff. Legitimate services never ask for seeds.
KEY_INSIGHT:    Before interacting with any unexpected token or airdrop: check the issuer account on an explorer (XRPL.org, Bithomp) and look at their trust line configuration, transfer fee settings, and account history. If a token appeared in your wallet that you did not ask for — ignore it. Do not try to sell or interact with it. It is bait.
CATEGORY:       safety
TAGS:           xrpl, scam, airdrop, trust-line, social-engineering, phishing, security, transfer-fee
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-T-003, RECON-T-004, RECON-S-002, RECON-S-004
CHAIN:          xrpl
TOOL:           XRPL.org explorer, Bithomp
USE_CASE:       security
NOTES:          Trust lines can be set TO any account without the account's permission — the 0.2 XRP reserve is charged to the account setting the line, not the issuer. This means attackers can "force-deliver" tokens to accounts that have set trust lines to their token. The victim sees a balance but it cannot be sold without interacting with the attacker's infrastructure. Never sign a transaction you didn't initiate from a known trusted interface.
```

---

## RECON-S-004

```
ID:             RECON-S-004
TYPE:           safety
TITLE:          What never to store or share — seeds, private keys, and where secrets go wrong
SUMMARY:        An XRPL seed (s…) or private key grants irrevocable control over the associated wallet. Compromise is permanent — there is no transaction reversal, no support escalation, and no recovery mechanism on-chain. Common exposure paths: pasting into chat, storing in plain text files, including in code committed to public repos, logging in application output, transmitting over HTTP, or telling an AI assistant. Even if shared "privately," text persists in logs, backups, and memory.
KEY_INSIGHT:    Seeds and private keys belong in exactly one place: a hardware wallet's secure element, or an encrypted secrets manager (e.g. 1Password, Bitwarden, HashiCorp Vault) with 2FA. Everywhere else is wrong. If a key has been shared — even once, even briefly — treat the associated wallet as compromised. Sweep funds to a new wallet immediately and never reuse the exposed key.
CATEGORY:       safety
TAGS:           xrpl, security, seed, private-key, secret-management, exposure, wallet, hardware-wallet
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     10
FREQUENCY:      1
PRIORITY:       10.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-S-001, RECON-S-002, RECON-S-003, RECON-S-005
CHAIN:          xrpl
TOOL:           hardware wallet, secrets manager
USE_CASE:       security
NOTES:          When building bots: generate a fresh keypair for each bot, fund it with only what it needs, and store the seed in an environment variable loaded from a secrets manager at runtime — never hardcoded. For agents on XRPLClaw: store keys in memory/secrets.md (agent-encrypted, not visible in chat). Never paste seeds into the chat window or any field that logs user input.
```

---

## RECON-S-005

```
ID:             RECON-S-005
TYPE:           safety
TITLE:          SetRegularKey pattern for trading bots — hot key isolation
SUMMARY:        Trading bots require an always-online signing key to submit transactions. The SetRegularKey pattern separates that operational key from the master key: (1) generate a fresh keypair for the bot — this is the regular key; (2) submit SetRegularKey on the operational account from the master key, installing the bot keypair as the regular key; (3) store only the regular key's seed in the bot's environment; (4) keep the master key offline. The bot can now trade, but cannot modify account settings (e.g. cannot set a new regular key or disable the master key). If the bot is compromised, fund loss is limited to the account balance; the master key can rotate the regular key from cold storage.
KEY_INSIGHT:    The regular key CAN sign Payment, OfferCreate, AMMDeposit, and most operational transactions. It CANNOT set a new regular key or disable the master key without the master key co-signing. This asymmetry is the security property that makes the pattern valuable — compromise of the bot key does not give the attacker persistent account control.
CATEGORY:       safety
TAGS:           xrpl, regular-key, setregularkey, trading-bot, bot-security, hot-key, key-isolation
SOURCE:         internal_kb
TIER:           1
USEFULNESS:     9
FREQUENCY:      1
PRIORITY:       9.0
LIBRARY_CANDIDATE: YES
RELATED:        RECON-S-001, RECON-S-002, RECON-S-004, RECON-T-021, RECON-T-008
CHAIN:          xrpl
TOOL:           xrpl.js, xrpl-py
USE_CASE:       security, trading, automation
NOTES:          Implement a balance floor in the bot logic — if XRP drops below threshold (e.g. 5 XRP above reserve), halt trading and alert. This prevents the bot from spending itself into reserve territory and getting stuck. Pair with the hot/cold architecture (RECON-S-001): the operational account is the "hot wallet" and the regular key is the bot's credential into it.
```
