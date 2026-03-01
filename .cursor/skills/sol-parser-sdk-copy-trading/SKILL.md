---
name: sol-parser-sdk-copy-trading
description: "Copy trading: requires both sol-parser-sdk and sol-trade-sdk. 跟单需同时使用 sol-parser-sdk 与 sol-trade-sdk。Parser: filter tx by wallet, parse buys/sells; Trade: build and send copy orders. Use when: copy trading, follow wallet; 跟单、跟踪某钱包交易时使用。"
---

# 跟单场景 / Copy trading scenario

**依赖 / Dependencies**：跟单场景**必须同时使用** **sol-parser-sdk** 与 **sol-trade-sdk**。Copy trading **requires both** sol-parser-sdk and sol-trade-sdk.

- **sol-parser-sdk**：按钱包地址过滤交易（TransactionFilter）、解析买卖事件，得到被跟单方的 **mint、方向、金额、user** 等；负责「发现」与「解析」。Filter tx by wallet, parse trade events (mint, direction, amount, user); **discovery + parsing**.
- **sol-trade-sdk**：根据解析结果用己方钱包构造并发送同方向、同标的（及可选同比例）的买卖；负责「复制下单」。Build and submit your own buy/sell from parsed data; **placing the copy order**.

跟单即跟踪指定钱包的买卖并选择复制下单或仅记录：用 parser 发现目标钱包的成交，用 trade-sdk 执行复制单。Copy trading = follow a wallet’s trades and optionally replicate; use parser to detect, trade-sdk to send.

---

## 按钱包过滤交易 / Filter transactions by wallet

Yellowstone gRPC 的订阅支持按账户过滤：交易中**出现**某账户（作为 signer 或 account key）即会推送。用 `TransactionFilter` 的 **account_include** 传入要跟单的钱包地址（base58 字符串）：

```rust
use sol_parser_sdk::grpc::{TransactionFilter, AccountFilter, EventTypeFilter, EventType, Protocol, YellowstoneGrpc};

// 只接收「交易中涉及这些钱包」的 tx
let wallet1 = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU".to_string();
let wallet2 = "AnotherWalletBase58...".to_string();

let tx_filter = TransactionFilter {
    account_include: vec![wallet1, wallet2],
    account_exclude: vec![],
    account_required: vec![],
};

// 若仍要限制在 DEX 协议内，可再组合协议过滤（需根据实际 API 支持情况）：
// 多数场景仅 account_include 即可，事件解析时会得到 program 与事件类型
let account_filter = AccountFilter::for_protocols(&[
    Protocol::PumpFun,
    Protocol::PumpSwap,
]);
```

说明：**account_include** = 交易涉及其中任一账户即订阅；**account_required** = 交易必须包含所列账户（更严格）。跟单一般用 **account_include** 包含被跟单钱包即可。account_include = tx touches any of these; account_required = tx must include all; for copy trading use account_include with followed wallet(s).

---

## 只解析买卖事件 / Subscribe only to trade events

跟单只关心「某钱包的买/卖」，因此用 **EventTypeFilter::include_only** 只收交易类事件，减少无关解析：

```rust
let event_filter = EventTypeFilter::include_only(vec![
    EventType::PumpFunBuy,
    EventType::PumpFunSell,
    EventType::PumpFunBuyExactSolIn,
    EventType::PumpSwapBuy,
    EventType::PumpSwapSell,
    // 按需加 Raydium、Meteora、Orca 等
]);

let queue = grpc.subscribe_dex_events(vec![tx_filter], vec![account_filter], Some(event_filter)).await?;
```

---

## 解析后识别「谁买的/谁卖的」/ Match event to followed wallet

事件里的 **user** 字段即交易的用户（钱包）。收到事件后与跟单列表比对，只处理被跟单钱包的交易：

```rust
let followed_wallets: std::collections::HashSet<Pubkey> = [
    wallet_pubkey_1,
    wallet_pubkey_2,
].into_iter().collect();

while let Some(event) = queue.pop() {
    let (user, mint, is_buy, sol_amount, token_amount) = match &event {
        DexEvent::PumpFunBuy(e) => (e.user, e.mint, true, e.sol_amount, e.token_amount),
        DexEvent::PumpFunSell(e) => (e.user, e.mint, false, e.sol_amount, e.token_amount),
        DexEvent::PumpSwapBuy(e) => (e.user, e.mint, true, e.sol_amount, e.token_amount),
        DexEvent::PumpSwapSell(e) => (e.user, e.mint, false, e.sol_amount, e.token_amount),
        _ => continue,
    };
    if !followed_wallets.contains(&user) {
        continue;
    }
    // 跟单逻辑：记录或复制下单（复制下单必须用 sol-trade-sdk 构造并发送）
    // Copy logic: log or submit your own order (replicate order must use sol-trade-sdk to build and send)
}
```

不同协议事件结构见 `sol-parser-sdk/src/core/events.rs`（如 `PumpFunTradeEvent`、PumpSwap 事件等）；字段名可能略有差异，用 `user`/`mint`/`is_buy`/金额字段即可。

---

## 组合示例 / Full example sketch

```rust
// 1) 按钱包过滤 tx
let tx_filter = TransactionFilter {
    account_include: vec![followed_wallet_base58],
    account_exclude: vec![],
    account_required: vec![],
};
// 2) 账户订阅可按协议收（或空，仅靠 tx_filter 也可）
let account_filter = AccountFilter::for_protocols(&[Protocol::PumpFun, Protocol::PumpSwap]);
// 3) 只收买卖事件
let event_filter = EventTypeFilter::include_only(vec![
    EventType::PumpFunBuy, EventType::PumpFunSell, EventType::PumpFunBuyExactSolIn,
    EventType::PumpSwapBuy, EventType::PumpSwapSell,
]);
let queue = grpc.subscribe_dex_events(vec![tx_filter], vec![account_filter], Some(event_filter)).await?;

// 4) 消费时 match DexEvent，取 user/mint/is_buy/amount，若 user 在跟单列表则执行跟单逻辑
```

---

## 顺序与延迟 / Ordering and latency

- 跟单若需按时间顺序处理同一钱包的多笔，可用 **OrderMode::MicroBatch** 或 **StreamingOrdered**，在顺序与延迟之间折中。
- 若只做「发现即跟」、对严格顺序要求不高，用 **Unordered** 延迟最低。

---

## 关键字段（跟单决策用）/ Key fields for copy logic

- **user**：交易用户（钱包），用于判断是否为目标跟单地址。
- **mint**：代币，决定跟单标的是什么。
- **is_buy** / **ix_name**：买还是卖。
- **sol_amount**、**token_amount**：金额，可用于按比例或固定金额跟单。
- **metadata.signature**、**metadata.slot**：去重、日志与审计。
- **bonding_curve** / **pool** 等：复制下单时由 **sol-trade-sdk** 使用这些账户信息构造同协议订单。Used by sol-trade-sdk when building the copy order.

---

## 参考 / References

- **双 SDK**：解析与订阅用 sol-parser-sdk；复制下单用 sol-trade-sdk（同仓库 `sol-trade-sdk/`）。Both SDKs: sol-parser-sdk for parse/subscribe, sol-trade-sdk for placing copy orders.
- 事件结构：`sol-parser-sdk/src/core/events.rs`
- 过滤器与 gRPC：`sol-parser-sdk-grpc-usage`、`sol-parser-sdk-dex-events` skills
- 下单 API 与示例：`sol-trade-sdk/`
