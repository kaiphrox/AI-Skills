---
name: sol-parser-sdk-dev
description: "Guides development and contribution to sol-parser-sdk (Rust Solana DEX event parser). 开发、贡献 sol-parser-sdk 指南。Use when: adding new protocols, new event types, running tests, building, modifying SDK structure; 添加新协议、新事件类型、运行测试、构建、修改 SDK 结构时使用。"
---

# Sol Parser SDK 开发指南 / Development Guide

## 项目结构 / Project structure（sol-parser-sdk，仓库根目录 / repo root）

```
src/
├── lib.rs              # 入口、重导出 API
├── core/               # 核心解析与事件
│   ├── events.rs       # 所有 DexEvent 及具体事件结构
│   ├── unified_parser.rs
│   ├── account_dispatcher.rs
│   ├── account_fillers/
│   └── ...
├── grpc/               # Yellowstone gRPC 客户端与类型
│   ├── client.rs
│   ├── types.rs        # OrderMode, ClientConfig, EventType, EventTypeFilter, Protocol
│   ├── event_parser.rs
│   └── ...
├── instr/              # 指令解析（按程序 ID 路由）
│   ├── mod.rs          # parse_instruction_unified 入口
│   ├── program_ids.rs
│   ├── pump.rs, pump_amm.rs, meteora_damm.rs, ...
│   └── inner_common.rs / *_inner.rs
├── logs/               # 日志解析（SIMD 协议检测 + 各协议 parser）
│   ├── mod.rs          # parse_log_unified 入口
│   ├── optimized_matcher.rs / discriminator_lut
│   ├── pump.rs, raydium_*.rs, orca_*.rs, meteora_*.rs, ...
│   └── zero_copy_parser.rs (parse-zero-copy feature)
├── accounts/           # 账户解析（token, nonce, pumpswap, ...）
├── rpc_parser.rs       # 从 RPC 交易解析
├── warmup.rs           # 解析器预热
└── perf/               # 性能相关（可选）
idls/                   # 各协议 IDL JSON（Borsh 结构参考）
examples/               # 可运行示例
```

## 构建与测试 / Build and test

```bash
# 开发构建 / dev build
cargo build

# Release（性能测试必须 / required for perf）
cargo build --release

# 运行测试 / run tests
cargo test

# 生成文档 / generate docs
cargo doc --open
```

## Features（Cargo.toml）

- **default**: `parse-borsh`（类型安全、易维护 / type-safe, maintainable）
- **parse-zero-copy**: 零拷贝解析，最高性能（与 parse-borsh 二选一 / max perf, mutually exclusive）
- **perf-stats**: 性能统计 / performance stats
- **ultra-perf**: 极限性能（unsafe 优化 / unsafe opts）

添加新 feature 时保持与现有互斥关系（如解析器只能选一个）。When adding features, keep mutual exclusion (e.g. only one parser variant).

## 添加新协议 / 新事件类型 / Adding new protocol or event type

1. **事件定义**  
   在 `core/events.rs` 中增加 `DexEvent` 的 enum 变体及对应结构体；如需 Borsh 解析，加 `#[cfg_attr(feature = "parse-borsh", derive(BorshDeserialize))]` 与 `borsh(skip)` 等。

2. **EventType**  
   在 `grpc/types.rs` 的 `EventType` 中增加新变体；如需在过滤逻辑中特殊处理，在 `EventTypeFilter::should_include` 或 `includes_*` 中补充。

3. **Protocol**  
   若按协议过滤，在 `grpc/types.rs` 的 `Protocol` 中增加，并在 `TransactionFilter::for_protocols` / `AccountFilter::for_protocols` 中映射程序 ID。

4. **程序 ID**  
   在 `instr/program_ids.rs` 和 `logs` 侧（若用）增加对应 `PROGRAM_ID` 常量。

5. **指令解析**  
   在 `instr/` 下新增或修改模块，在 `parse_instruction_unified` 中按 `program_id` 路由到新解析函数；导出 `parse_xxx_instruction` 如需对外使用。

6. **日志解析**  
   在 `logs/` 下增加协议识别（如 SIMD finder / discriminator）和对应 `parse_*`；在 `logs/mod.rs` 的 `parse_log_unified` 中根据 log 内容调用。

7. **账户填充（可选）**  
   若事件需要从账户数据填充字段，在 `core/account_fillers/` 增加 filler，并在 `account_dispatcher` 中注册。

8. **IDL**  
   若有官方 IDL，将 JSON 放到 `idls/` 并用于 Borsh 结构对齐。

9. **示例与文档 / Examples and docs**  
   在 `examples/` 增加至少一个示例；README 中补充协议与事件类型说明。Add at least one example; document protocol and event types in README.

## 代码风格与约定 / Code style and conventions

- 热路径用 `#[inline]` 或 `#[inline(always)]`，避免在热路径堆分配。Use `#[inline]` on hot path; avoid heap allocation there.
- 新协议解析先实现 Borsh 路径（parse-borsh），再考虑 zero-copy 优化。Implement Borsh path first, then zero-copy if needed.
- 公共 API 变更需同步更新 `lib.rs` 的 `pub use` 和 README。Keep `lib.rs` pub use and README in sync with API changes.
- 中文注释可保留；对外文档以 README/README_CN 为准。Chinese comments OK; public docs: README / README_CN.

## 参考 / References

- 主文档：`sol-parser-sdk/README.md`、`sol-parser-sdk/README_CN.md`
- 示例：`examples/pumpfun_trade_filter.rs`、`pumpswap_with_metrics.rs`、`meteora_damm_grpc.rs`
