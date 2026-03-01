---
name: sol-parser-sdk-grpc-usage
description: "How to use sol-parser-sdk gRPC client, filters, order modes, and RPC parsing. gRPC 客户端、过滤器、顺序模式与 RPC 解析使用指南。Use when: subscribing to DEX events, OrderMode, transaction/account/event filters, RPC parsing; 订阅 DEX 事件、选择顺序模式、配置过滤器、从 RPC 解析交易时使用。"
---

# Sol Parser SDK gRPC 与 RPC 使用指南 / gRPC and RPC usage

## 基本流程 / Basic flow

1. 创建 `YellowstoneGrpc` 客户端（端点 + 可选鉴权 + 可选 `ClientConfig`）。Create client (endpoint, optional auth, optional ClientConfig).
2. 构造 `TransactionFilter`、`AccountFilter`，以及可选的 `EventTypeFilter`。Build transaction/account/event filters.
3. 调用 `subscribe_dex_events(...)` 得到无锁队列 `Arc<ArrayQueue<DexEvent>>`。Call subscribe_dex_events to get lock-free queue.
4. 在单独任务中循环 `queue.pop()` 消费事件；可配合自旋 + `yield_now` 做低延迟消费。Consume via queue.pop() in a dedicated task; use spin + yield_now for low latency.

## 客户端创建 / Client creation

```rust
use sol_parser_sdk::grpc::{YellowstoneGrpc, ClientConfig, OrderMode};

// 默认（Unordered，低延迟）
let grpc = YellowstoneGrpc::new(
    "https://solana-yellowstone-grpc.publicnode.com:443".to_string(),
    Some(auth_token), // Option<String>
)?;

// 自定义配置（有序、超时、指标等）
let config = ClientConfig {
    order_mode: OrderMode::MicroBatch,
    micro_batch_us: 100,
    order_timeout_ms: 100,
    enable_metrics: true,
    ..ClientConfig::default()
};
let grpc = YellowstoneGrpc::new_with_config(endpoint, auth_token, config)?;
```

预设：`ClientConfig::low_latency()`、`ClientConfig::high_throughput()` 可按需使用。Presets: low_latency(), high_throughput().

## 顺序模式 / Order mode（OrderMode）

| 模式 / Mode | 延迟 / Latency | 顺序保证 / Order | 适用场景 / Use case |
|------|------|----------|----------|
| **Unordered** | 10–20μs | 无 / none | 纯延迟敏感 / latency-only |
| **MicroBatch** | 50–200μs | 时间窗内有序 / batch order | 低延迟 + 弱顺序 |
| **StreamingOrdered** | 0.1–5ms | 连续 slot 内有序 | slot/tx_index 顺序 |
| **Ordered** | 1–50ms | 完整 slot 有序 | 强顺序、可接受更高延迟 |

配置项：`order_timeout_ms`（有序模式超时）、`micro_batch_us`（MicroBatch 窗口）。Config: order_timeout_ms, micro_batch_us.

## 过滤器 / Filters

**TransactionFilter**  
按程序 ID 过滤交易。Filter by program ID: `TransactionFilter::for_protocols(&[Protocol::PumpFun, ...])`；或手写 account_include/exclude/required.

**AccountFilter**  
按程序/账户过滤账户订阅。`AccountFilter::for_protocols(&protocols)` 或 `add_owner`、`add_filter(account_filter_memcmp(offset, bytes))`；memcmp 常用于按 mint（ATA offset 0、池 offset 32）过滤。

**EventTypeFilter**  
- `include_only(vec![...])`：只解析并输出这些事件，降低 CPU 与带宽。Only parse and emit these events.
- `exclude_types(vec![...])`：排除指定类型。Exclude types.

组合示例 / Example：只收 PumpFun 的 Buy/Sell/Create：

```rust
let tx_filter = TransactionFilter::for_protocols(&[Protocol::PumpFun]);
let account_filter = AccountFilter::for_protocols(&[Protocol::PumpFun]);
let event_filter = EventTypeFilter::include_only(vec![
    EventType::PumpFunBuy,
    EventType::PumpFunSell,
    EventType::PumpFunCreate,
]);
let queue = grpc.subscribe_dex_events(vec![tx_filter], vec![account_filter], Some(event_filter)).await?;
```

## 消费队列 / Consuming the queue

队列为 `Arc<ArrayQueue<DexEvent>>`，无锁。推荐在独立 task 中循环 pop，并配合自旋减少延迟。Queue is lock-free; loop pop in a dedicated task; use spin for lower latency:

```rust
while let Some(event) = queue.pop() {
    // 处理 event
}
// 或混合自旋
let mut spin_count = 0;
loop {
    if let Some(event) = queue.pop() {
        spin_count = 0;
        // process event
    } else {
        spin_count += 1;
        if spin_count < 1000 {
            std::hint::spin_loop();
        } else {
            tokio::task::yield_now().await;
            spin_count = 0;
        }
    }
}
```

## 动态更新订阅 / Dynamic subscription update

无需断开连接即可更新过滤条件。Update filters without reconnecting:

```rust
grpc.update_subscription(
    vec![new_transaction_filter],
    vec![new_account_filter],
).await?;
```

## 从 RPC 解析交易 / Parse transaction from RPC

不经过 gRPC 流，直接按签名从 RPC 拿交易并解析为 DEX 事件。Parse by signature without gRPC stream:

```rust
use sol_parser_sdk::{parse_transaction_from_rpc, parse_rpc_transaction, ParseError};

// 按签名解析
let events = parse_transaction_from_rpc(rpc_client, &signature).await?;
// 或已有 Transaction 时
let events = parse_rpc_transaction(&transaction)?;
```

用于回放、单笔调试或与 gRPC 混合使用。For replay, single-tx debug, or mixed with gRPC. `convert_rpc_to_grpc` converts RPC data to gRPC form when needed.

## 账户订阅示例 / Account subscription examples

订阅单个 token 余额、nonce、mint 信息、PumpSwap 池账户、某 mint 下所有 ATA 等，见 `examples/`。Subscribe token balance, nonce, mint, pool, or all ATAs for a mint:

- `token_balance_listen`（TOKEN_ACCOUNT）
- `nonce_listen`（NONCE_ACCOUNT）
- `token_decimals_listen`（MINT_ACCOUNT）
- `pumpswap_pool_account_listen`
- `mint_all_ata_account_listen`

memcmp: `account_filter_memcmp(offset, bytes)`；ATA mint at 0，池 mint at 32。

## 性能建议 / Performance tips

- 用 `EventTypeFilter::include_only` 只订阅需要的类型，可明显降低负载。Use include_only to reduce load.
- 延迟敏感用 `OrderMode::Unordered` + Release 构建；需要顺序再选 MicroBatch 或 StreamingOrdered。Latency-sensitive: Unordered + release; need order: MicroBatch or StreamingOrdered.
- 生产监控 `metadata.grpc_recv_us` 与队列积压；按吞吐调整 `ArrayQueue` 容量与自旋次数。Monitor grpc_recv_us and queue backlog; tune queue size and spin count.

## 参考 / References

- 类型与配置：`sol-parser-sdk/src/grpc/types.rs`
- 客户端与订阅：`sol-parser-sdk/src/grpc/client.rs`
- RPC 解析：`sol-parser-sdk/src/rpc_parser.rs`
- 示例：`examples/pumpfun_trade_filter.rs`、`pumpswap_ordered.rs`、`dynamic_subscription.rs`
