---
name: sol-parser-sdk-rust-patterns
description: "Rust and performance patterns used in sol-parser-sdk. SDK 中的 Rust 与性能模式。Use when: writing or reviewing performance-critical parser code, SIMD, zero-copy, Borsh, lock-free queues, hot-path; 编写或审查解析器、SIMD、零拷贝、Borsh、无锁队列、热路径优化时使用。"
---

# Sol Parser SDK Rust 与性能模式 / Rust and performance patterns

## 解析器二选一 / Parser choice (pick one)

- **parse-borsh**（默认）：Borsh 反序列化，类型安全、易维护；事件结构带 `#[derive(BorshDeserialize)]`，用 `borsh(skip)` 标记非 Borsh 字段（如 `metadata`、派生字段）。
- **parse-zero-copy**：零拷贝、栈缓冲区，最高性能；热路径无堆分配，需与 Borsh 结构对齐。

添加新事件时优先实现 Borsh 路径，再考虑 zero-copy 特化。Prefer Borsh for new events, then zero-copy specialization.

## SIMD 协议检测 / SIMD protocol detection（logs）

- 用 `memchr`/`memmem::Finder` 替代 `log.contains(bytes)`，预编译为静态 finder：
  ```rust
  static PUMPFUN_FINDER: Lazy<memmem::Finder> =
      Lazy::new(|| memmem::Finder::new(b"6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P"));
  if PUMPFUN_FINDER.find(log_bytes).is_some() { ... }
  ```
- 协议/事件类型检测集中在 `logs/optimized_matcher.rs` 或 `discriminator_lut`，避免在热路径重复字符串搜索。Centralize protocol/discriminator detection there; avoid repeated string search on hot path.

## 零拷贝与栈分配 / Zero-copy and stack allocation

- 热路径使用栈缓冲区，例如 512 字节：`let mut decode_buf: [u8; 512] = [0u8; 512];`，用 `decode_slice` 等直接解码到栈。
- 小集合用 `SmallVec<[DexEvent; 4]>` 或 `smallvec![]` 避免堆分配；避免在热路径使用 `Vec::new()` 后频繁 push。
- 读取固定偏移用 `#[inline(always)]` 的 `read_u64_le` 等，避免多余分支与间接调用。

## 事件输出与无锁队列 / Event delivery and lock-free queue

- gRPC 端用 `ArrayQueue::<DexEvent>` 无锁队列向消费者递送事件；容量按吞吐配置（如 100_000）。Use ArrayQueue for event delivery; size by throughput (e.g. 100_000).
- 消费侧可用混合自旋策略：先 `spin_loop()` 若干次，再 `tokio::task::yield_now().await`。Hybrid spin then yield to avoid burning CPU.

## 内联与分支预测 / Inlining and branch hints

- 热路径解析函数加 `#[inline]` 或 `#[inline(always)]`。
- 冷路径用 `#[cold]` 或 `logs/perf_hints::unlikely()` 包装条件，帮助 CPU 分支预测。

## 事件类型过滤 / Event type filtering

- 在协议层尽早过滤；若 `EventTypeFilter::include_only` 仅包含单一类型，可走专用解析路径。Filter early; single-type filter can use dedicated parse path (e.g. PumpFunTrade zero-copy).
- 条件性逻辑（如 Create+Buy 检测）仅在订阅了相关事件时执行。Run conditional logic (e.g. Create+Buy) only when those events are subscribed.

## Borsh 与 IDL 对齐 / Borsh and IDL alignment

- 事件结构字段顺序与链上/IDL 布局一致；非 Borsh 字段（如 `metadata`、`trade_direction`、`is_created_buy`）必须 `#[borsh(skip)]`。
- 新增事件时对照 `idls/*.json` 和程序日志格式，保证 discriminator 与字段偏移正确。

## 错误与边界 / Errors and bounds

- 热路径上解析失败返回 `Option::None` 或 `Result`；避免在热路径打 log 或分配错误字符串。Return None/Result on parse failure; no log or error string allocation on hot path.
- 长度与边界检查用 `offset + 8 <= data.len()` 等形式，一次检查后再用 `copy_from_slice`/`from_le_bytes`。Check bounds once then use copy_from_slice/from_le_bytes.

## 参考文件 / Reference files

- 零拷贝解析：`src/logs/zero_copy_parser.rs`
- SIMD/匹配：`src/logs/optimized_matcher.rs`、`discriminator_lut.rs`
- 统一入口：`src/core/unified_parser.rs`、`src/instr/mod.rs`（`parse_instruction_unified`）、`src/logs/mod.rs`（`parse_log_unified`）
