---
name: sol-parser-sdk-account-subscription
description: "Account subscription with sol-parser-sdk: token balance, nonce, pool account, ATA by mint, memcmp filters. sol-parser-sdk 账户订阅：代币余额、nonce、池账户、按 mint 的 ATA、memcmp 过滤。Use when: monitoring account changes, balance listen, pool state, ATA subscription; 监控账户变化、余额监听、池状态、ATA 订阅时使用。"
---

# 账户订阅场景 / Account subscription scenario

除**交易订阅**（按程序/钱包过滤 tx 并解析 DEX 事件）外，sol-parser-sdk 支持**账户订阅**：当指定账户数据变化时收到事件，用于余额监听、池状态、nonce、某 mint 下所有 ATA 等。Besides **transaction subscription**, sol-parser-sdk supports **account subscription**: receive events when specified account data changes (balance, pool, nonce, ATA).

---

## 与交易订阅的区别 / Account vs transaction subscription

- **交易订阅**：`TransactionFilter` 按程序 ID 或钱包过滤**交易**，解析出 DexEvent（Trade、Create 等）。适合监听成交、创建、跟单。
- **账户订阅**：`AccountFilter` 指定要监听的**账户**（或 owner + memcmp），收到该账户更新时推送 **TokenAccount**、**NonceAccount**、**AccountPumpSwapPool** 等事件。适合监听余额变化、池状态、nonce 变化。

两者可同时使用：同一 `subscribe_dex_events` 调用中传入 tx 过滤器 + 账户过滤器，并设 `EventTypeFilter` 包含所需事件类型（如 `TokenAccount`、`AccountPumpSwapPool`）。

---

## 常用事件类型 / Event types for account

- **EventType::TokenAccount**：代币账户余额等变化。
- **EventType::NonceAccount**：Nonce 账户状态变化。
- **EventType::AccountPumpSwapPool**：PumpSwap 池账户。
- **EventType::AccountPumpSwapGlobalConfig**：全局配置账户。  
在 `EventTypeFilter::include_only` 中按需包含以上类型。

---

## 账户过滤器构造 / AccountFilter

- **按账户地址**：`AccountFilter { account: vec![account_pubkey_base58], owner: vec![], filters: vec![] }`，订阅单个账户更新。
- **按 owner**：`AccountFilter::for_protocols(&[Protocol::PumpFun])` 等，订阅该程序下的账户；或 `add_owner(program_id)`。
- **memcmp**：用 **account_filter_memcmp(offset, bytes)** 加入 `filters`，按数据段过滤。例如：
  - **ATA**：mint 在 offset 0，传入 mint 的 32 字节即可订阅该 mint 的所有 ATA（或单账户时指定 ATA 地址）。
  - **PumpSwap 池**：常见为 mint 或某字段在 offset 32，按项目 IDL 确定 offset 与 bytes。

---

## 示例场景与示例 / Example scenarios and examples

| 场景 | EventType | AccountFilter 要点 | 示例 |
|------|-----------|---------------------|------|
| 单个代币账户余额 | TokenAccount | account = [token_account_pubkey] | token_balance_listen |
| Nonce 账户状态 | NonceAccount | account = [nonce_account_pubkey] | nonce_listen |
| Mint 信息（decimals/supply） | 订阅 mint 账户 | account = [mint_pubkey] | token_decimals_listen |
| PumpSwap 池账户 | AccountPumpSwapPool | memcmp 或 owner + 程序 | pumpswap_pool_account_listen |
| 某 mint 下所有 ATA | TokenAccount | memcmp offset 0 = mint 的 32 字节 | mint_all_ata_account_listen |

以上示例位于 `sol-parser-sdk/examples/`。运行方式见 README，如：  
`TOKEN_ACCOUNT=<pubkey> cargo run --example token_balance_listen --release`  
`NONCE_ACCOUNT=<pubkey> cargo run --example nonce_listen --release`

---

## 无交易过滤时 / Transaction filter empty

若只做账户订阅、不关心交易流，可传 **TransactionFilter::default()**（空），仅靠 `AccountFilter` 与 `EventTypeFilter` 收账户类事件，减少无关数据。

---

## 参考 / References

- 类型定义：`sol-parser-sdk/src/grpc/types.rs`（AccountFilter、account_filter_memcmp）
- 示例：`sol-parser-sdk/examples/token_balance_listen.rs`、`nonce_listen.rs`、`pumpswap_pool_account_listen.rs`、`mint_all_ata_account_listen.rs`
- gRPC 订阅流程：sol-parser-sdk-grpc-usage skill
