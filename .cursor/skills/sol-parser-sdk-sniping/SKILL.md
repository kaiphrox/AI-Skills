---
name: sol-parser-sdk-sniping
description: "Sniping new tokens: requires both sol-parser-sdk and sol-trade-sdk. 狙击需同时使用 sol-parser-sdk 与 sol-trade-sdk。Parser: subscribe Create/first-buy, is_created_buy; Trade: build and send buy tx. Use when: sniper bot, new token first buy; 狙击机器人、新币首买时使用。"
---

# 狙击场景 / Sniping scenario

**依赖 / Dependencies**：狙击场景**必须同时使用** **sol-parser-sdk** 与 **sol-trade-sdk**。Sniping **requires both** sol-parser-sdk and sol-trade-sdk.

- **sol-parser-sdk**：订阅链上事件（PumpFun Create、Buy）、解析出新币/首买，得到 `mint`、`bonding_curve` 等；负责「发现」与「解析」。Subscribe to and parse events (Create, Buy); get mint, bonding_curve, etc.; **discovery + parsing**.
- **sol-trade-sdk**：根据解析结果构造买入指令并发送交易；负责「下单」。Build and submit the buy transaction from parsed data; **placing the order**.

狙击指在新币创建或池子刚出现时抢先买入：用 parser 发现首买事件，用 trade-sdk 立即发单。Sniping = buy as soon as a new token or pool appears; use parser to detect, trade-sdk to send.

---

## 订阅事件 / Events to subscribe

- **PumpFunCreate**：新币创建，可拿到 `mint`、创建者等。
- **PumpFunBuy** / **PumpFunBuyExactSolIn**：首笔或后续买入；需与 Create 结合判断是否为「创建同 tx 首买」。
- 可选 **PumpSwapCreatePool**：迁移到 AMM 后的池创建，用于狙击迁移后的第一笔。

事件定义与字段见 `sol-parser-sdk/src/core/events.rs`（如 `PumpFunTradeEvent`、Create 事件结构）。

---

## 首买识别 / First-buy detection（is_created_buy）

解析器在**同一笔交易**中若检测到 Create + Buy，会在 Trade 事件上设置 `is_created_buy = true`。用于狙击时只处理「新币首买」：

```rust
// 只处理「创建同 tx 内的首买」
if let DexEvent::PumpFunBuy(e) = &event {
    if e.is_created_buy {
        // 新币首买：e.mint, e.bonding_curve, e.sol_amount, e.token_amount, ...
        // 此处发起你的买入 tx（用 sol-trade-sdk 或直接组指令）
    }
}
```

也可先订阅 Create，收到 Create 后记录 `mint`，再在后续 Buy 事件里匹配同一 `mint` 做首买逻辑（延迟会略高）。Prefer `is_created_buy` for single-tx detection with minimal latency.

---

## 事件过滤示例 / Event filter example

```rust
use sol_parser_sdk::grpc::{EventType, EventTypeFilter, Protocol, TransactionFilter, AccountFilter, YellowstoneGrpc, ClientConfig, OrderMode};

// 只收 Create + 各类 Buy，减少无关事件
let event_filter = EventTypeFilter::include_only(vec![
    EventType::PumpFunCreate,
    EventType::PumpFunBuy,
    EventType::PumpFunBuyExactSolIn,
    // 若也要狙击 PumpSwap 新池首笔，可加：
    // EventType::PumpSwapCreatePool,
    // EventType::PumpSwapBuy,
]);

let tx_filter = TransactionFilter::for_protocols(&[Protocol::PumpFun]);
let account_filter = AccountFilter::for_protocols(&[Protocol::PumpFun]);
let queue = grpc.subscribe_dex_events(vec![tx_filter], vec![account_filter], Some(event_filter)).await?;
```

---

## 延迟优化 / Latency optimization

- **OrderMode**：用 **Unordered**，不等待排序，延迟最低（约 10–20μs 解析端）。
- **ClientConfig**：`ClientConfig::low_latency()` 或手设 `order_mode: OrderMode::Unordered`，必要时缩短 `connection_timeout_ms` / `request_timeout_ms`。
- **消费队列**：单独 task 里循环 `queue.pop()`，配合短自旋再 `yield_now`，避免阻塞。
- **构建**：`cargo build --release`；可考虑 `parse-zero-copy` feature 进一步降低解析延迟。
- **节点**：使用延迟低的 Yellowstone gRPC 端点；自建或付费端点通常比公共端点更快。

---

## 关键字段（下单用）/ Key fields for placing orders

从 `PumpFunTradeEvent` / Create 事件中取：

- **mint**：代币 mint，下单与风控必备。
- **bonding_curve** / **associated_bonding_curve**：PumpFun 曲线账户，构造 buy 指令需要。
- **user**：当前交易用户；狙击时你用自己的钱包发 tx。
- **sol_amount**、**token_amount**、**is_buy**、**virtual_sol_reserves**、**virtual_token_reserves**：用于计算金额或校验。
- **metadata.signature**、**metadata.slot**：去重或日志。

**下单必须用 sol-trade-sdk**：用解析到的事件字段（mint、bonding_curve 等）调用 sol-trade-sdk 构造并发送买入交易。本 skill 侧重 parser 侧（发现与解析）；发单实现见 sol-trade-sdk 文档与示例。Order placement must use sol-trade-sdk; this skill focuses on the parser side (discovery + parsing).

---

## 流程小结 / Workflow summary

1. 用 **Unordered** + **EventTypeFilter** 只订阅 Create + Buy（+ 可选 PumpSwapCreatePool/PumpSwapBuy）。
2. 在 `queue.pop()` 的循环里解析出 `DexEvent`，对 `PumpFunBuy` 检查 `is_created_buy`，或对 Create 记录 mint 再匹配后续 Buy。
3. 从事件中取出 `mint`、`bonding_curve` 等，调用你的下单模块（如 sol-trade-sdk）发送买入 tx。
4. 监控 `metadata.grpc_recv_us` 与下单到上链的延迟，优化节点与网络。

---

## 参考 / References

- **双 SDK**：解析与订阅用 sol-parser-sdk；下单用 sol-trade-sdk（同仓库 `sol-trade-sdk/`）。Both SDKs: sol-parser-sdk for parse/subscribe, sol-trade-sdk for order.
- 事件与字段：`sol-parser-sdk/src/core/events.rs`
- 过滤与 gRPC：`sol-parser-sdk-grpc-usage`、`sol-parser-sdk-dex-events` skills
- 下单 API 与示例：`sol-trade-sdk/`
