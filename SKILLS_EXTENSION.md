# 技能拓展建议 / Skills extension ideas

在现有 6 个技能基础上，可考虑以下拓展方向，便于按需新增或迭代技能。  
Below are suggested directions for extending skills beyond the current six.

---

## 已实现 / Implemented

| 技能 | 说明 |
|------|------|
| sol-trade-sdk-usage | 使用 sol-trade-sdk 构建买卖参数、发单、SWQoS/MEV、与 parser 事件对接 |
| sol-parser-sdk-account-subscription | 账户订阅：余额、池、ATA、memcmp 过滤，与交易订阅的区别 |

---

## 可选拓展 / Optional extensions

1. **RPC 解析 vs gRPC 流**  
   - 何时用 `parse_transaction_from_rpc` / `parse_rpc_transaction`（回放、单笔调试、按签名解析）vs gRPC 实时流。  
   - 技能名建议：`sol-parser-sdk-rpc-vs-grpc` 或合并进 grpc-usage。

2. **多协议聚合 / Multi-DEX**  
   - 同时监听多 DEX（PumpFun + PumpSwap + Raydium + Meteora）时如何设计过滤器、归一化事件、去重。  
   - 技能名建议：`sol-parser-sdk-multi-dex`。

3. **测试与调试**  
   - 用 RPC 按签名解析单笔交易做回归；`debug_pump_tx`、`debug_pumpswap_tx`、`test_account_filling` 等示例；为新事件写单元测试。  
   - 技能名建议：`sol-parser-sdk-testing-debug`。

4. **SWQoS / MEV 发单**  
   - sol-trade-sdk 侧：Jito、Nextblock、ZeroSlot 等配置、多路并发发单、速度与成功率权衡。可并入 sol-trade-sdk-usage 或单独 `sol-trade-sdk-swqos-mev`。

5. **交易安全与风控**  
   - 仿真（simulate）、滑点、私钥不落库、限频、简单 MEV 防护。偏规范与最佳实践。  
   - 技能名建议：`trading-safety-risk`。

6. **sol-trade-sdk 开发/贡献**  
   - 类似 sol-parser-sdk-dev：项目结构、添加新协议指令、TradeFactory、params 扩展。  
   - 技能名建议：`sol-trade-sdk-dev`。

7. **代币元数据 / Token metadata**  
   - 从 mint 获取 name、symbol、decimals（Metaplex 等），用于狙击/跟单展示或风控。  
   - 技能名建议：`token-metadata-mint` 或合并进业务类技能。

---

## 使用方式

- 需要某方向时，在 `.cursor/skills/` 下新增对应目录与 `SKILL.md`，并在 README 技能列表中登记。  
- 安装脚本 `scripts/install.sh` 会复制 `.cursor/skills/` 下所有目录，无需改脚本。
