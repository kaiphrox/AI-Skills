# AI-Skills

本仓库包含与 Solana 生态相关的 **Cursor Agent Skills**，用于在 Cursor 中开发或使用 [sol-parser-sdk](sol-parser-sdk) 与 [sol-trade-sdk](sol-trade-sdk)（如狙击、跟单等场景）时获得更精准的 AI 协助。

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">中文</a>
</p>

---

## 目录

- [什么是 Cursor Skills？](#什么是-cursor-skills)
- [本仓库提供的 Skills 列表](#本仓库提供的-skills-列表)
- [如何「安装」Skills？](#如何安装skills)
  - [一键安装（推荐）](#一键安装推荐)
  - [项目级 Skills（打开本仓库即用）](#项目级-skills打开本仓库即用)
  - [需要下载 SDK 源码吗？](#需要下载-sdk-源码吗)
- [如何使用这些 Skills？](#如何使用这些-skills)
  - [使用方式：正常提问即可](#使用方式正常提问即可)
  - [触发场景速查](#触发场景速查)
- [目录结构](#目录结构)
- [小结](#小结)

---

<a id="什么是-cursor-skills"></a>
## 什么是 Cursor Skills？

Skills 是 Cursor 的「技能」文件，用来教 AI 在特定场景下如何回答和操作：

- **项目级 Skills**：放在仓库的 `.cursor/skills/` 下，任何人拉取本仓库并在 Cursor 中打开即可使用。
- **个人级 Skills**：放在 `~/.cursor/skills/` 下，只在你本机生效，可跨项目使用。

本仓库提供的是 **项目级 Skills**，只要用 Cursor 打开本仓库（或包含本仓库的目录），无需额外安装即可使用。

---

<a id="本仓库提供的-skills-列表"></a>
## 本仓库提供的 Skills 列表

| Skill 名称 | 类型 | 用途简述 |
|------------|------|----------|
| **sol-parser-sdk-dev** | 开发 | 开发/贡献 sol-parser-sdk：项目结构、构建测试、添加新协议或新事件类型 |
| **sol-parser-sdk-rust-patterns** | 开发 | SDK 内的 Rust 与性能模式：SIMD、零拷贝、Borsh、无锁队列、热路径优化 |
| **sol-parser-sdk-dex-events** | 业务 | DEX 事件类型、协议支持、业务场景与事件过滤（交易机器人、池监控等） |
| **sol-parser-sdk-grpc-usage** | 业务 | gRPC 订阅、OrderMode、过滤器、队列消费、RPC 解析、账户订阅 |
| **sol-parser-sdk-sniping** | 业务 | 狙击新币（需**同时**使用 sol-parser-sdk + sol-trade-sdk）：Create/首买、is_created_buy、最低延迟；parser 发现，trade-sdk 发单 |
| **sol-parser-sdk-copy-trading** | 业务 | 跟单（需**同时**使用 sol-parser-sdk + sol-trade-sdk）：按钱包过滤、解析买卖；parser 发现，trade-sdk 发跟单 |
| **sol-trade-sdk-usage** | 业务 | 使用 sol-trade-sdk 构建并发送 DEX 交易：TradeBuyParams、from_dev_trade、SWQoS/MEV、滑点；与 parser 配合狙击/跟单 |
| **sol-parser-sdk-account-subscription** | 业务 | 账户订阅：代币余额、nonce、池账户、按 mint 的 ATA、memcmp 过滤；与交易订阅的区别与示例 |

**语言说明**：所有 Skills 支持中英文。描述与章节标题为双语；用中文或英文提问均可触发并获取对应指导。

---

<a id="如何安装skills"></a>
## 如何「安装」Skills？

<a id="一键安装推荐"></a>
### 一键安装（推荐）

在终端执行下面一条命令即可：**自动克隆本仓库，并把 Skills 安装到 Cursor，同时在项目根目录自动克隆 sol-parser-sdk、sol-trade-sdk**，无需你再手动克隆或复制。

```bash
git clone https://github.com/0xfnzero/AI-Skills.git && cd AI-Skills && chmod +x scripts/install.sh && ./scripts/install.sh
```

（若你已克隆过本仓库，只需在仓库根目录执行：`./scripts/install.sh`。）

安装脚本会：

1. 把 `.cursor/skills/` 下所有 skill 复制到 `~/.cursor/skills/`，之后在任意项目用 Cursor 打开都会生效；
2. 在**项目根目录**自动克隆 [sol-parser-sdk](https://github.com/0xfnzero/sol-parser-sdk) 和 [sol-trade-sdk](https://github.com/0xfnzero/sol-trade-sdk)（优先 SSH，失败则用 HTTPS）。

若**只安装 Skills、不下载 SDK 源码**（例如你只用 crates.io 依赖、不需要本地源码），可加参数：

```bash
./scripts/install.sh --skills-only
```

<a id="项目级-skills打开本仓库即用"></a>
### 项目级 Skills（打开本仓库即用）

用 Cursor 打开本仓库根目录时，无需安装即可使用项目自带的 Skills（`.cursor/skills/`）。若要在其他项目里也能用，请执行上面的一键安装或 `./scripts/install.sh`，把 Skills 安装到个人目录。

<a id="需要下载-sdk-源码吗"></a>
### 在自己的项目里用这些 Skills，需要下载 SDK 源码吗？

- **只在自己的项目里写业务、用 sol-parser-sdk 做依赖**：不需要。安装时用 `./scripts/install.sh --skills-only`，项目里用 crates.io（如 `sol-parser-sdk = "0.2.2"`）即可。
- **要改 SDK 源码或对照源码看**：需要。直接执行 `./scripts/install.sh`（不加 `--skills-only`），脚本会自动把 sol-parser-sdk、sol-trade-sdk 克隆到**本仓库根目录**（与 `.cursor`、`scripts` 同级）。

---

<a id="如何使用这些-skills"></a>
## 如何使用这些 Skills？

不需要手动「启用」某个 Skill。Cursor 会根据你**对话中的意图和关键词**，自动选择是否调用某个 Skill。

<a id="使用方式正常提问即可"></a>
### 使用方式：正常提问即可

在 Cursor 的 AI 对话里，用自然语言描述你的需求即可。例如：

- **开发类**  
  - 「在 sol-parser-sdk 里怎么加一个新的 DEX 协议？」  
  - 「解析热路径上能不能用零拷贝？有什么约定？」  
  - 「这个项目结构里 instr 和 logs 分别负责什么？」  

- **业务类**  
  - 「只要 PumpFun 的买和卖，怎么设 EventTypeFilter？」  
  - 「gRPC 订阅用 Unordered 和 MicroBatch 区别是什么？」  
  - 「我想做新币首买监控，该订阅哪些事件？」  
- **狙击**  
  - 「怎么用 sol-parser-sdk 做狙击机器人？」「is_created_buy 是什么？」  
  - 「新币首买最低延迟怎么配？」  
- **跟单**  
  - 「怎么用 sol-parser-sdk 跟单某钱包的交易？」「按钱包地址过滤交易」  
- **发单（sol-trade-sdk）**  
  - 「怎么从 PumpFun 事件构造买入参数？」「from_dev_trade」「SWQoS 怎么配？」  
- **账户订阅**  
  - 「怎么订阅某个代币账户余额变化？」「memcmp 过滤 ATA」  

当你的问题涉及上述场景时，Cursor 会优先参考对应的 Skill 来回答，从而更贴合 sol-parser-sdk 的代码和用法。

<a id="触发场景速查"></a>
### 触发场景速查（方便你提问）

| 你想做的事 | 建议提问/关键词 | 会参考的 Skill |
|------------|------------------|----------------|
| 给 SDK 加新协议/新事件 | 「添加新协议」「新事件类型」「项目结构」 | sol-parser-sdk-dev |
| 跑测试、构建、改结构 | 「测试」「构建」「cargo」 | sol-parser-sdk-dev |
| 写/优化解析、性能相关代码 | 「零拷贝」「SIMD」「Borsh」「无锁」「热路径」 | sol-parser-sdk-rust-patterns |
| 按业务过滤事件、理解事件含义 | 「事件类型」「PumpFun/PumpSwap」「交易机器人」「池监控」 | sol-parser-sdk-dex-events |
| 接 gRPC、选顺序、写过滤器、RPC 解析 | 「gRPC 订阅」「OrderMode」「TransactionFilter」「RPC 解析」 | sol-parser-sdk-grpc-usage |
| 狙击新币、首买抢跑 | 「狙击」「sniper」「is_created_buy」「新币首买」 | sol-parser-sdk-sniping |
| 跟单、跟踪某钱包交易 | 「跟单」「copy trading」「按钱包过滤」「account_include」 | sol-parser-sdk-copy-trading |
| 用 sol-trade-sdk 构建/发单 | 「TradeBuyParams」「from_dev_trade」「SWQoS」「滑点」 | sol-trade-sdk-usage |
| 账户订阅、余额监听 | 「账户订阅」「token balance」「memcmp」「ATA」 | sol-parser-sdk-account-subscription |

---

<a id="目录结构"></a>
## 目录结构（与本教程相关部分）

```
AI-Skills/
├── README.md                 # 英文说明
├── README_CN.md              # 本教程（中文）
├── scripts/
│   └── install.sh            # 一键安装：复制 Skills + 在根目录克隆 SDK
├── .cursor/
│   └── skills/
│       ├── sol-parser-sdk-dev/
│       ├── sol-parser-sdk-rust-patterns/
│       ├── sol-parser-sdk-dex-events/
│       ├── sol-parser-sdk-grpc-usage/
│       ├── sol-parser-sdk-sniping/
│       ├── sol-parser-sdk-copy-trading/
│       ├── sol-trade-sdk-usage/
│       └── sol-parser-sdk-account-subscription/
├── sol-parser-sdk/           # 执行 install.sh 后自动克隆到根目录
└── sol-trade-sdk/            # 执行 install.sh 后自动克隆到根目录
```

---

<a id="小结"></a>
## 小结

- **安装**：推荐在仓库根目录执行 `./scripts/install.sh`（或一键命令克隆后执行）。脚本会自动把 Skills 安装到 `~/.cursor/skills/`，并在**项目根目录**克隆 sol-parser-sdk、sol-trade-sdk，无需用户手动下载。仅要 Skills 时使用 `./scripts/install.sh --skills-only`。
- **使用**：在 Cursor 里像平时一样提问即可，涉及开发、性能、事件类型、gRPC、狙击、跟单等时，AI 会自动参考对应 Skill 作答。
- **依赖**：在自己的项目里通过 crates.io（如 `sol-parser-sdk = "0.2.2"`）引用 SDK 即可；需要看或改 SDK 源码时，用脚本在根目录拉取的 `sol-parser-sdk/`、`sol-trade-sdk/` 即可。**狙击与跟单**需同时使用 sol-parser-sdk 和 sol-trade-sdk。

更多关于 sol-parser-sdk 的用法与示例，请查看 [sol-parser-sdk/README.md](sol-parser-sdk/README.md) 与 [sol-parser-sdk/README_CN.md](sol-parser-sdk/README_CN.md)。**更多技能拓展方向**（RPC vs gRPC、多 DEX、测试、MEV 等）见 [SKILLS_EXTENSION.md](SKILLS_EXTENSION.md)。
