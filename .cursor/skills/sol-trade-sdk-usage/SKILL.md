---
name: sol-trade-sdk-usage
description: "How to use sol-trade-sdk to build and send DEX trades. 如何使用 sol-trade-sdk 构建并发送 DEX 交易。Use when: building buy/sell from parser events, TradeConfig, PumpFunParams::from_dev_trade, SWQoS/MEV, slippage; 从解析事件构造买卖、TradeConfig、from_dev_trade、SWQoS/MEV、滑点时使用。"
---

# Sol Trade SDK 使用指南 / Sol Trade SDK usage

sol-trade-sdk 用于**构造并发送** Solana DEX 交易（买/卖），与 sol-parser-sdk（发现与解析事件）配合完成狙击、跟单等场景。This skill covers building and sending buy/sell transactions; use with sol-parser-sdk for sniping and copy trading.

---

## 依赖关系 / Dependencies

- **sol-parser-sdk**：订阅与解析链上事件，得到 `mint`、`bonding_curve`、`sol_amount`、`token_amount` 等。
- **sol-trade-sdk**：根据上述字段构造指令并发送交易（含 SWQoS/MEV 等）。  
狙击与跟单需**同时**使用两个 SDK。Sniping and copy trading require **both** SDKs.

---

## 核心流程 / Core flow

1. 创建 **SolanaTrade** 客户端：`SolanaTrade::new(payer, trade_config).await`，其中 `TradeConfig` 包含 RPC URL、SWQoS 配置、commitment。
2. 准备 **买卖参数**：`TradeBuyParams` / `TradeSellParams`，包含 `dex_type`、`mint`、金额、滑点、`extension_params`（如 `DexParamEnum::PumpFun(PumpFunParams::from_dev_trade(...))`）。
3. 调用 **client.buy(buy_params)** 或 **client.sell(sell_params)** 发送交易。

---

## 从解析事件到下单 / From parser event to order

**PumpFun 狙击**：解析到 `PumpFunTradeEvent`（如 `is_created_buy`）后，用 **PumpFunParams::from_dev_trade** 从事件字段构造参数，再传给 `TradeBuyParams.extension_params`：

```rust
use sol_trade_sdk::trading::core::params::{PumpFunParams, DexParamEnum};
use sol_trade_sdk::TradeBuyParams;

// e: PumpFunTradeEvent from sol_parser_sdk
let extension_params = DexParamEnum::PumpFun(PumpFunParams::from_dev_trade(
    e.mint,
    e.token_amount,
    max_sol_cost,
    e.creator,
    e.bonding_curve,
    e.associated_bonding_curve,
    e.creator_vault,
    None,
    e.fee_recipient,
    e.token_program,
    e.is_cashback_coin,
));

let buy_params = TradeBuyParams {
    dex_type: DexType::PumpFun,
    input_token_type: TradeTokenType::SOL,
    mint: e.mint,
    input_token_amount: buy_sol_amount,
    slippage_basis_points: Some(300),
    extension_params,
    // ... recent_blockhash, gas_fee_strategy, simulate, etc.
};
client.buy(buy_params).await?;
```

**卖出**：可用 **PumpFunParams::from_trade** 传入曲线与储备等，构造 `TradeSellParams.extension_params`。其他协议（PumpSwap、Bonk、Raydium、Meteora）有对应的 Params 与 from_* 方法，见 `sol-trade-sdk/src/trading/core/params` 与各 instruction 模块。

---

## TradeConfig 与 SWQoS / MEV

- **TradeConfig::new(rpc_url, swqos_configs, commitment)**：`swqos_configs` 为发单通道列表（如 `SwqosConfig::Default(rpc_url)` 或 Jito、Nextblock 等），可配置多路并发，先成交者生效。
- **GasFeeStrategy**：可通过 `GasFeeStrategy::new()` 与 `set_global_fee_strategy` 等控制优先费与计算单元，影响上链速度与成本。

---

## 关键类型与模块

- **DexType**：PumpFun、PumpSwap、Bonk、RaydiumCpmm、RaydiumAmmV4、MeteoraDammV2。
- **TradeBuyParams / TradeSellParams**：统一买卖参数；`extension_params` 为协议具体参数（PumpFunParams、PumpSwapParams 等）。
- **PumpFunParams::from_dev_trade**：从 parser 的 PumpFun 事件（含 bonding_curve、creator、is_cashback_coin 等）构造，用于狙击/跟单首买。
- **PumpFunParams::from_trade**：从事件中的储备与曲线信息构造卖出参数。
- **Middleware**：可选，在指令发出前修改/增删指令，见 `MiddlewareManager`。

---

## 示例位置 / Example locations

- 狙击：`sol-trade-sdk/examples/pumpfun_sniper_trading`
- 跟单：`sol-trade-sdk/examples/pumpfun_copy_trading`
- 其他协议：`pumpswap_trading`、`raydium_amm_v4_trading`、`meteora_damm_v2_direct_trading` 等。

---

## 参考 / References

- 事件字段来源：sol-parser-sdk（狙击/跟单 skills）
- 参数与 API：`sol-trade-sdk/src/trading/`、`sol-trade-sdk/src/instruction/`
- 官方文档：`sol-trade-sdk/README.md`、`README_CN.md`
