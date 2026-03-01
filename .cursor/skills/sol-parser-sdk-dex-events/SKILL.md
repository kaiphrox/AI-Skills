---
name: sol-parser-sdk-dex-events
description: "DEX event types, supported protocols, and business scenarios for sol-parser-sdk. DEX 事件类型、协议与业务场景。Use when: filtering events for trading bots, pool monitors, interpreting PumpFun/PumpSwap/Raydium/Meteora/Orca fields; 交易机器人、池监控、事件过滤、解读各协议事件字段时使用。"
---

# Sol Parser SDK DEX 事件与业务场景 / DEX events and business scenarios

## 支持的协议与事件概览 / Supported protocols and events

| 协议 / Protocol | 典型事件 / Events | 用途 / Use |
|------|----------|------|
| **PumpFun** | Trade(Create/Buy/Sell/BuyExactSolIn)、Migrate、Complete | Meme 币创建与交易 / Meme create & trade |
| **PumpSwap** | Buy、Sell、CreatePool、LiquidityAdded、LiquidityRemoved | AMM 交易与池 / AMM trade & pool |
| **Bonk (Raydium Launchpad)** | BonkTrade、BonkPoolCreate、BonkMigrateAmm | 发射与迁移 / Launch & migrate |
| **Raydium** | AMM V4 / CLMM / CPMM Swap、池与仓位 | AMM/CLMM 交易与流动性 |
| **Orca Whirlpool** | Swap、流动性、池初始化 | 集中流动性 AMM |
| **Meteora** | AMM/DAMM/DLMM Swap、流动性、仓位 | 动态 AMM、仓位管理 |

事件定义在 `core/events.rs`；过滤用 `grpc/types.rs` 的 `EventType` 与 `EventTypeFilter`。Event defs in core/events.rs; filter via EventType and EventTypeFilter in grpc/types.rs.

## 常用 EventType / Common EventType（过滤用 / for filtering）

- **PumpFun**: `PumpFunTrade`（所有交易）、`PumpFunBuy`、`PumpFunSell`、`PumpFunBuyExactSolIn`、`PumpFunCreate`、`PumpFunComplete`、`PumpFunMigrate`
- **PumpSwap**: `PumpSwapBuy`、`PumpSwapSell`、`PumpSwapCreatePool`、`PumpSwapLiquidityAdded`、`PumpSwapLiquidityRemoved`
- **Bonk**: `BonkTrade`、`BonkPoolCreate`、`BonkMigrateAmm`
- **Meteora DAMM V2**: `MeteoraDammV2Swap`、`MeteoraDammV2AddLiquidity`、`MeteoraDammV2RemoveLiquidity`、`MeteoraDammV2CreatePosition`、`MeteoraDammV2ClosePosition`
- **其他**: `BlockMeta`；账户类如 `TokenAccount`、`NonceAccount`、`AccountPumpSwapPool` 等按需使用

`PumpFunTrade` 与 Buy/Sell/BuyExactSolIn 共享同一 discriminator；包含任一分类型即会收到 Trade，解析后可用 `ix_name` 或变体区分。PumpFunTrade shares discriminator with Buy/Sell/BuyExactSolIn; filter by subtype or use ix_name after parse.

## 事件通用元数据 / Event metadata（EventMetadata）

所有事件都带 `metadata`：`signature`、`slot`、`tx_index`、`block_time_us`、`grpc_recv_us`。延迟监控或排序用 `grpc_recv_us`、`slot`、`tx_index`。All events have metadata: signature, slot, tx_index, block_time_us, grpc_recv_us; use for latency and ordering.

## 业务场景与过滤示例 / Scenarios and filter examples

**交易机器人 / Trading bot（只关心成交 / swaps only）**  
只订阅各协议 Swap/Trade，减少无关事件与解析开销。Subscribe only Swap/Trade to reduce load:

```rust
EventTypeFilter::include_only(vec![
    EventType::PumpFunTrade,  // 或 PumpFunBuy + PumpFunSell + PumpFunBuyExactSolIn
    EventType::PumpSwapBuy,
    EventType::PumpSwapSell,
    EventType::MeteoraDammV2Swap,
    // 按需加 Raydium/Orca 等
])
```

**新币/池监控 / New token & pool monitor（Create + 首买）**  
订阅 Create 与首笔买。Subscribe Create and first buy:

```rust
EventTypeFilter::include_only(vec![
    EventType::PumpFunCreate,
    EventType::PumpFunBuy,
    EventType::PumpFunBuyExactSolIn,
    EventType::PumpSwapCreatePool,
])
```

解析后通过 `PumpFunTradeEvent.is_created_buy` 可识别「创建同 tx 内的首买」。Use is_created_buy for create-same-tx first buy.

**流动性监控 / Liquidity monitor**  
只订阅加撤流动性与建池。Subscribe add/remove liquidity and pool creation:

```rust
EventTypeFilter::include_only(vec![
    EventType::PumpSwapLiquidityAdded,
    EventType::PumpSwapLiquidityRemoved,
    EventType::PumpSwapCreatePool,
    EventType::MeteoraDammV2AddLiquidity,
    EventType::MeteoraDammV2RemoveLiquidity,
    EventType::MeteoraDammV2CreatePosition,
    EventType::MeteoraDammV2ClosePosition,
])
```

**PumpFun 交易类型区分 / PumpFun trade types**  
PumpFunBuy / PumpFunSell / PumpFunBuyExactSolIn 与 PumpFunTrade 对应同一笔交易的不同视图；只关心买/卖/精确 SOL 进可用分类型过滤；要完整字段用 PumpFunTrade 再按 ix_name 处理。

## 关键业务字段 / Key fields（PumpFunTradeEvent 示例）

- `mint`、`user`、`is_buy`、`is_created_buy`、`sol_amount`、`token_amount`、`virtual_sol_reserves`、`virtual_token_reserves`、`fee`、`creator`、`creator_fee`、`ix_name`、`mayhem_mode`、`cashback_*`、`is_cashback_coin` 等；账户类如 `bonding_curve`、`associated_bonding_curve` 从指令/账户填充。  
其他协议事件见 `core/events.rs` 中各 `*Event` 结构体。

## Create + Buy 检测 / Create+Buy detection

当同一笔交易中既有 Create 又有 Buy 时，解析器会设置 Trade 的 `is_created_buy = true`，用于识别「新币首买」。仅当订阅了相关事件时才会做该检测以节省开销。Parser sets is_created_buy=true when Create and Buy in same tx; only runs when those events are subscribed.

## 参考 / References

- 事件定义：`sol-parser-sdk/src/core/events.rs`
- 事件类型与过滤：`sol-parser-sdk/src/grpc/types.rs`（`EventType`、`EventTypeFilter`）
- 示例：`examples/pumpfun_trade_filter.rs`、`pumpswap_ordered.rs`、`meteora_damm_grpc.rs`
