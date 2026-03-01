# AI-Skills

This repository provides **Cursor Agent Skills** for the Solana ecosystem, so that Cursor can give more accurate help when you develop or use [sol-parser-sdk](sol-parser-sdk) and [sol-trade-sdk](sol-trade-sdk) (e.g. for sniping and copy trading).

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">中文</a>
</p>

---

## Contents

- [What are Cursor Skills?](#what-are-cursor-skills)
- [Skills in this repo](#skills-in-this-repo)
- [How to install the skills](#how-to-install-the-skills)
  - [One-command install (recommended)](#one-command-install-recommended)
  - [Using project-level skills](#using-project-level-skills)
  - [Do I need the SDK source?](#do-i-need-the-sdk-source-when-using-these-skills-in-my-own-project)
- [How to use the skills](#how-to-use-the-skills)
  - [Just ask in natural language](#just-ask-in-natural-language)
  - [Quick reference: what to ask → which skill](#quick-reference-what-to-ask--which-skill)
- [Directory layout](#directory-layout-relevant-to-this-guide)
- [Summary](#summary)

---

## What are Cursor Skills?

Skills are instruction files that teach the AI how to answer and act in specific situations:

- **Project-level skills**: Live in `.cursor/skills/` in the repo; anyone who clones and opens the repo in Cursor can use them.
- **User-level skills**: Live in `~/.cursor/skills/` on your machine and apply across all your projects.

This repo ships **project-level skills**. Open this repo (or a parent folder that contains it) in Cursor and they are available with no extra install step.

---

## Skills in this repo

| Skill | Type | Purpose |
|-------|------|---------|
| **sol-parser-sdk-dev** | Dev | Contributing to sol-parser-sdk: project layout, build/test, adding new protocols or event types |
| **sol-parser-sdk-rust-patterns** | Dev | Rust and perf patterns in the SDK: SIMD, zero-copy, Borsh, lock-free queues, hot-path optimizations |
| **sol-parser-sdk-dex-events** | Biz | DEX event types, supported protocols, and scenarios: trading bots, pool monitors, event filtering |
| **sol-parser-sdk-grpc-usage** | Biz | gRPC client, OrderMode, transaction/account/event filters, queue consumption, RPC parsing, account subscriptions |
| **sol-parser-sdk-sniping** | Biz | Sniping new tokens (needs **both** sol-parser-sdk + sol-trade-sdk): Create/first-buy, is_created_buy, lowest-latency; parser discovers, trade-sdk sends buy |
| **sol-parser-sdk-copy-trading** | Biz | Copy trading (needs **both** sol-parser-sdk + sol-trade-sdk): filter tx by wallet, parse buys/sells; parser discovers, trade-sdk sends copy orders |
| **sol-trade-sdk-usage** | Biz | Build and send DEX trades with sol-trade-sdk: TradeBuyParams, PumpFunParams::from_dev_trade, SWQoS/MEV, slippage; pairs with parser for sniping/copy |
| **sol-parser-sdk-account-subscription** | Biz | Account subscription: token balance, nonce, pool account, ATA by mint, memcmp filters; when to use account vs transaction subscription |

**Language**: All skills support both Chinese and English. Descriptions and section titles are bilingual; you can ask in either language to trigger and use them.

---

## How to install the skills

### One-command install (recommended)

Run this in your terminal to clone the repo, install the skills into Cursor, and clone [sol-parser-sdk](https://github.com/0xfnzero/sol-parser-sdk) and [sol-trade-sdk](https://github.com/0xfnzero/sol-trade-sdk) into the repo root:

```bash
git clone https://github.com/0xfnzero/AI-Skills.git && cd AI-Skills && chmod +x scripts/install.sh && ./scripts/install.sh
```

If you already have the repo, from the repo root run:

```bash
./scripts/install.sh
```

The script will:

1. Copy all skills from `.cursor/skills/` to `~/.cursor/skills/` so they apply in any project you open in Cursor.
2. Clone sol-parser-sdk and sol-trade-sdk into the **repo root** (tries SSH first, then HTTPS).

To **install only the skills** (no SDK source, e.g. you depend on crates.io only):

```bash
./scripts/install.sh --skills-only
```

### Using project-level skills

When you open this repo in Cursor, the skills under `.cursor/skills/` are used automatically. To use them in other projects too, run the one-command install or `./scripts/install.sh` so the skills are copied to your user directory.

### Do I need the SDK source when using these skills in my own project?

- **Only using sol-parser-sdk as a dependency (e.g. from crates.io)**  
  No. Run `./scripts/install.sh --skills-only` and add `sol-parser-sdk = "0.2.2"` (or similar) in your project.

- **Editing or reading the SDK source**  
  Yes. Run `./scripts/install.sh` without `--skills-only`; the script will clone sol-parser-sdk and sol-trade-sdk into this repo's root (next to `.cursor/`, `scripts/`).

---

## How to use the skills

You don't enable skills manually. Cursor picks which skill to use from the **intent and keywords** in your message.

### Just ask in natural language

In Cursor's AI chat, describe what you want. For example:

- **Development**
  - "How do I add a new DEX protocol in sol-parser-sdk?"
  - "What are the rules for zero-copy on the parse hot path?"
  - "What do instr and logs do in this project structure?"

- **Usage / business**
  - "How do I set EventTypeFilter for only PumpFun buy and sell?"
  - "What's the difference between Unordered and MicroBatch for gRPC?"
  - "I want to monitor new-token first buys; which events should I subscribe to?"
- **Sniping**
  - "How do I build a sniper bot with sol-parser-sdk?" "What is is_created_buy?"
  - "Lowest latency setup for new token first buy"
- **Copy trading**
  - "How do I follow a wallet's trades with sol-parser-sdk?" "Filter transactions by wallet address"
- **Building/sending trades (sol-trade-sdk)**
  - "How do I build a buy from a PumpFun event?" "PumpFunParams::from_dev_trade"
  - "How do I configure SWQoS or Jito for sending trades?"
- **Account subscription**
  - "How do I subscribe to token account balance changes?" "memcmp filter for ATA"

When your question matches one of these areas, Cursor will use the right skill to answer in line with sol-parser-sdk's code and usage.

### Quick reference: what to ask → which skill

| What you want | Example questions / keywords | Skill used |
|---------------|-------------------------------|------------|
| Add new protocol/event to SDK | "add new protocol", "new event type", "project structure" | sol-parser-sdk-dev |
| Run tests, build, change structure | "test", "build", "cargo" | sol-parser-sdk-dev |
| Parser/perf code (zero-copy, SIMD, etc.) | "zero-copy", "SIMD", "Borsh", "lock-free", "hot path" | sol-parser-sdk-rust-patterns |
| Filter events, understand event types | "event types", "PumpFun/PumpSwap", "trading bot", "pool monitor" | sol-parser-sdk-dex-events |
| gRPC, ordering, filters, RPC parsing | "gRPC subscribe", "OrderMode", "TransactionFilter", "RPC parse" | sol-parser-sdk-grpc-usage |
| Sniping new tokens, first buy | "sniper", "sniping", "is_created_buy", "new token first buy" | sol-parser-sdk-sniping |
| Copy trading, follow wallet | "copy trading", "follow wallet", "account_include", "track wallet trades" | sol-parser-sdk-copy-trading |
| Build/send trade with sol-trade-sdk | "TradeBuyParams", "from_dev_trade", "SWQoS", "slippage", "SolanaTrade" | sol-trade-sdk-usage |
| Account subscription, balance listen | "account subscription", "token balance", "memcmp", "ATA", "nonce listen" | sol-parser-sdk-account-subscription |

---

## Directory layout (relevant to this guide)

```
AI-Skills/
├── README.md                 # This guide (English)
├── README_CN.md              # 中文说明
├── scripts/
│   └── install.sh            # One-command install: copy skills + clone SDKs to root
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
├── sol-parser-sdk/           # Cloned by install.sh
└── sol-trade-sdk/            # Cloned by install.sh
```

---

## Summary

- **Install**: From the repo root run `./scripts/install.sh` (or use the one-command clone + install). The script installs skills to `~/.cursor/skills/` and clones sol-parser-sdk and sol-trade-sdk into the repo root. Use `./scripts/install.sh --skills-only` if you only want the skills.
- **Use**: Ask in Cursor as usual; when the topic is development, perf, event types, gRPC, sniping, or copy trading, the AI will use the matching skill to answer.
- **Dependencies**: In your own project you can depend on the SDK via crates.io (e.g. `sol-parser-sdk = "0.2.2"`). When you need to read or change SDK source, use the clones under `sol-parser-sdk/` and `sol-trade-sdk/`. **Sniping and copy trading** require both sol-parser-sdk and sol-trade-sdk.

For more on sol-parser-sdk usage and examples, see [sol-parser-sdk/README.md](sol-parser-sdk/README.md) and [sol-parser-sdk/README_CN.md](sol-parser-sdk/README_CN.md). For **further skill ideas** (RPC vs gRPC, multi-DEX, testing, MEV, etc.), see [SKILLS_EXTENSION.md](SKILLS_EXTENSION.md).
