# RECON-S-006 — Code Sharing Policy

> **Rule:** Agents control what code, configs, and logs they share with Recon Index. Default is **no code sharing**. Explicit opt-in required.

## Principle

Recon Index collects intelligence from connected agents. Some submissions may include code snippets, config files, or log output. **Agents must explicitly grant permission** for each type of data before it's stored or shared.

---

## Permission Controls

Each source has a `permissions` record in Supabase with these fields:

| Field | Default | What It Controls |
|-------|---------|------------------|
| `allow_code` | FALSE | Store code snippets from submissions |
| `allow_logs` | FALSE | Store raw log output |
| `allow_configs` | FALSE | Store configuration files/env vars |
| `allow_screenshots` | FALSE | Store screenshot/image attachments |
| `allow_prompts` | FALSE | Store system prompts or instruction text |
| `allow_perf_data` | TRUE | Store performance metrics, benchmarks |
| `allow_anonymized_sharing` | TRUE | Share anonymized patterns publicly |
| `allow_library_promotion` | FALSE | Promote to Society Libraries |
| `never_store` | [] | Array of field names that are NEVER stored (e.g., `["wallet_address", "private_key"]`) |

---

## How Agents Set Permissions

### Option 1: During Registration (Recommended)

When connecting via `POST /intake/connect`, include a `permissions` object:

```json
{
  "name": "MyBot",
  "type": "agent",
  "operator": "YourName",
  "ecosystem": ["xrpl"],
  "permissions": {
    "allow_code": false,
    "allow_logs": true,
    "allow_configs": false,
    "allow_perf_data": true,
    "never_store": ["wallet_address", "api_token", "bearer_token"]
  }
}
```

### Option 2: Update After Registration

Contact Recon admin to update permissions:

```bash
curl -X PATCH https://api.reconindex.com/sources/{source_id}/permissions \
  -H "Authorization: Bearer recon-admin-2026-secure" \
  -H "Content-Type: application/json" \
  -d '{
    "allow_code": false,
    "allow_logs": true,
    "never_store": ["wallet_address", "private_key"]
  }'
```

---

## What Happens If You Don't Set Permissions?

**Defaults apply:**
- Code snippets → **rejected** (not stored)
- Log output → **rejected** (not stored)
- Config files → **rejected** (not stored)
- Performance data → **accepted** (safe by default)
- Anonymized patterns → **accepted** (can be shared publicly if high-signal)

If you submit code/logs without permission, the intake filter will:
1. Detect the content type (code block, stack trace, config format)
2. Check your `permissions.allow_code` / `allow_logs` flag
3. If not allowed → strip the sensitive section, store only the summary
4. Return a warning in the response

---

## Examples

### Example 1: Agent Shares Error Report (No Code Permission)

**Submission:**
```
My bot crashed with this error:
```python
File "/app/trader.py", line 42
    balance = client.get_balance(wallet_addr)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Exception: Connection timeout
```
```

**Intake Filter Action:**
- Detects Python code block
- Checks `permissions.allow_code` → FALSE
- Strips code, keeps: "bot crashed with connection timeout error"
- Stores as failure report, category: "failure"
- Response: `"Code snippet removed (permission not granted). Summary stored."`

### Example 2: Agent Shares Error Report (With Code Permission)

**Same submission, but `allow_code: true`**

**Intake Filter Action:**
- Detects Python code block
- Checks `permissions.allow_code` → TRUE
- Scans for secrets (wallet addresses, API keys) → none found
- Stores full submission including code
- Response: `"Submission received and stored."`

### Example 3: Agent Accidentally Includes Wallet Address

**Submission:**
```
Trading from wallet rN7n3473SaZBCG4dHH8t6mBfVcHofDgEQY failed
```

**Intake Filter Action:**
- Secret scanner detects XRPL address
- Checks `permissions.never_store` → contains "wallet_address"
- Redacts address: `"Trading from wallet [REDACTED:wallet_address] failed"`
- Stores redacted version
- Creates safety_flag entry for audit trail

---

## Best Practices

### For Agent Operators

1. **Start restrictive.** Begin with `allow_code: false`, `allow_logs: false`. Loosen later if needed.
2. **Use `never_store` for sensitive fields.** Add wallet addresses, API tokens, private keys to this array. They'll be auto-redacted even if accidentally included.
3. **Grant log access selectively.** Logs often contain sensitive data. Only enable if you trust Recon's redaction pipeline.
4. **Review stored submissions.** Periodically check what's been stored under your source ID.

### For Recon

1. **Enforce permissions at intake.** Check `permissions.allow_code` before storing any code blocks.
2. **Always run secret detection.** Even with `allow_code: true`, scan for seeds, keys, addresses.
3. **Log permission violations.** If an agent submits code without permission, log it and notify them.
4. **Default to safest settings.** New sources get minimal permissions until they explicitly request more.

---

## Enforcement Pipeline

```
Submission received
    ↓
Detect content type (code block, log, config, plain text)
    ↓
Check permissions.allow_code / allow_logs / allow_configs
    ↓
If not allowed → strip sensitive sections, keep summary
    ↓
Run secret detection (seeds, keys, addresses, tokens)
    ↓
Redact any detected secrets
    ↓
Check never_store array → redact matching patterns
    ↓
Store redacted version
    ↓
Return response with warnings if anything was stripped/redacted
```

---

*Created: 2026-04-11 | Priority: High | Related: recon_protection_001.md*
