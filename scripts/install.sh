#!/usr/bin/env bash
# 一键安装 Cursor Skills，并可选自动克隆依赖到项目根目录（sol-parser-sdk、sol-trade-sdk）
# 用法：
#   在 AI-Skills 仓库根目录执行: ./scripts/install.sh
#   仅安装 Skills（不下载 SDK 源码）: ./scripts/install.sh --skills-only

set -e

SKILLS_ONLY=false
if [[ "${1:-}" == "--skills-only" ]]; then
  SKILLS_ONLY=true
fi

# 若当前不在 AI-Skills 仓库内，尝试通过 git 找到仓库根
REPO_ROOT="${REPO_ROOT:-}"
if [[ -z "$REPO_ROOT" ]]; then
  if [[ -d ".cursor/skills" ]]; then
    REPO_ROOT="."
  elif [[ -d ".git" ]]; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  fi
fi

if [[ -z "$REPO_ROOT" || ! -d "$REPO_ROOT/.cursor/skills" ]]; then
  echo "错误: 请在 AI-Skills 仓库根目录下执行此脚本，或设置 REPO_ROOT 指向该目录。"
  echo "示例: git clone https://github.com/0xfnzero/AI-Skills.git && cd AI-Skills && ./scripts/install.sh"
  exit 1
fi

cd "$REPO_ROOT"
CURSOR_SKILLS_DIR="${HOME}/.cursor/skills"
mkdir -p "$CURSOR_SKILLS_DIR"

# 复制所有 skill 到个人目录
for skill in .cursor/skills/*/; do
  if [[ -d "$skill" ]]; then
    name=$(basename "$skill")
    cp -r "$skill" "$CURSOR_SKILLS_DIR/"
    echo "已安装 skill: $name"
  fi
done

echo "Skills 已复制到: $CURSOR_SKILLS_DIR"

if [[ "$SKILLS_ONLY" == true ]]; then
  echo "已跳过 SDK 源码克隆（--skills-only）。"
  exit 0
fi

# 自动克隆或更新依赖到项目根目录（已存在则 git pull 拉取最新）
clone_or_update_repo() {
  local url_ssh="$1"
  local name="$2"
  local target="$REPO_ROOT/$name"
  if [[ -d "$target/.git" ]]; then
    echo "已存在，拉取最新: $name"
    (cd "$target" && git pull) || echo "警告: $name 拉取失败，请手动进入该目录执行 git pull"
    return 0
  fi
  if [[ -d "$target" ]]; then
    echo "警告: $target 已存在但非 git 仓库，跳过。若需重新克隆请先移除该目录。"
    return 0
  fi
  echo "正在克隆 $name ..."
  if git clone --depth 1 "$url_ssh" "$target" 2>/dev/null; then
    echo "已克隆: $name (SSH)"
    return 0
  fi
  local url_https="https://github.com/0xfnzero/${name}.git"
  if git clone --depth 1 "$url_https" "$target"; then
    echo "已克隆: $name (HTTPS)"
  else
    echo "警告: 克隆失败 $name，请检查网络或手动执行: git clone $url_https $target"
    return 1
  fi
}

clone_or_update_repo "git@github.com:0xfnzero/sol-parser-sdk.git" "sol-parser-sdk"
clone_or_update_repo "git@github.com:0xfnzero/sol-trade-sdk.git" "sol-trade-sdk"

echo ""
echo "安装完成。"
echo "  - Skills 已安装到: $CURSOR_SKILLS_DIR"
echo "  - 项目根目录已就绪: $REPO_ROOT/sol-parser-sdk, $REPO_ROOT/sol-trade-sdk"
