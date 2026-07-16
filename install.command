#!/usr/bin/env bash
# Dawei 安装器：从 GitHub 拉取最新配置，安装到 Cursor 项目或 Codex/GPT。
# 用法：
#   ./install.command                      # 交互式
#   ./install.command --mode cursor --target "/你的项目"
#   ./install.command --mode gpt           # 全局装到 ~/.codex
#   ./install.command --mode both --target "/你的项目"
#   curl -fsSL https://raw.githubusercontent.com/dawei-ux/Cursor-Gpt-Armor-Penetration/main/install.command | bash
set -euo pipefail

REPO_SLUG="dawei-ux/Cursor-Gpt-Armor-Penetration"
REPO_GIT="https://github.com/${REPO_SLUG}.git"
BRANCH="main"

MODE=""
TARGET=""
REF="$BRANCH"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)   MODE="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --ref)    REF="${2:-}"; shift 2 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "[X] 未知参数：$1"; exit 2 ;;
  esac
done

info()  { printf '\033[36m[*]\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m[+]\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m[!]\033[0m %s\n' "$*"; }
die()   { printf '\033[31m[X]\033[0m %s\n' "$*" >&2; exit 1; }

# 交互模式（无 --mode 时）。管道执行(无 tty)默认 both。
if [[ -z "$MODE" ]]; then
  if [[ -t 0 ]]; then
    printf "安装到哪里？ [1] Cursor 项目  [2] Codex/GPT(全局)  [3] 两者\n> "
    read -r choice
    case "$choice" in
      1) MODE="cursor" ;;
      2) MODE="gpt" ;;
      *) MODE="both" ;;
    esac
  else
    MODE="both"
  fi
fi

if [[ "$MODE" == "cursor" || "$MODE" == "both" ]]; then
  if [[ -z "$TARGET" ]]; then
    if [[ -t 0 ]]; then
      printf "请输入 Cursor 项目目录（默认：%s）：\n> " "$PWD"
      read -r TARGET
      TARGET="${TARGET:-$PWD}"
    else
      TARGET="$PWD"
    fi
  fi
  [[ -d "$TARGET" ]] || die "项目目录不存在：$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

# 1) 拉取仓库到临时目录
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dawei-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
SRC="$TMP/src"

fetch_repo() {
  if command -v git >/dev/null 2>&1; then
    info "git 克隆 ${REPO_SLUG} (${REF}) ..."
    if git clone --depth 1 --branch "$REF" "$REPO_GIT" "$SRC" >/dev/null 2>&1; then
      return 0
    fi
    warn "指定分支克隆失败，尝试默认分支 ..."
    git clone --depth 1 "$REPO_GIT" "$SRC" >/dev/null 2>&1 && return 0
  fi
  warn "git 不可用或失败，改用 tarball ..."
  local tb="$TMP/repo.tgz"
  curl -fsSL "https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REF}" -o "$tb" \
    || die "下载失败：检查网络或分支名 ${REF}"
  mkdir -p "$SRC"
  tar -xzf "$tb" -C "$SRC" --strip-components=1
}

fetch_repo
[[ -d "$SRC/.cursor/rules" ]] || die "仓库结构异常：缺少 .cursor/rules"
ok "已获取最新配置。"

# 2) 安装到 Cursor 项目
install_cursor() {
  local root="$1"
  local rules="$root/.cursor/rules"
  local skills="$root/.cursor/skills"
  local backup="$root/.cursor/backups/dawei-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$rules" "$skills" "$backup/rules" "$backup/skills"

  local n_rules=0 n_skills=0
  for s in "$SRC"/.cursor/rules/dawei-*.mdc; do
    [[ -e "$s" ]] || continue
    local name; name="$(basename "$s")"
    [[ -e "$rules/$name" ]] && cp "$rules/$name" "$backup/rules/$name"
    cp "$s" "$rules/$name"; n_rules=$((n_rules+1))
  done
  for s in "$SRC"/.cursor/skills/dawei-*; do
    [[ -e "$s" ]] || continue
    local name; name="$(basename "$s")"
    [[ -e "$skills/$name" ]] && cp -R "$skills/$name" "$backup/skills/$name"
    rm -rf "$skills/$name"
    cp -R "$s" "$skills/$name"; n_skills=$((n_skills+1))
  done
  ok "Cursor: 安装 $n_rules 条 Rules、$n_skills 个 Skills 到 $root/.cursor"
  info "备份目录：$backup"
}

# 3) 安装到 Codex/GPT（全局 ~/.codex）
install_gpt() {
  local base="${CODEX_HOME:-$HOME/.codex}"
  local skills="$base/skills"
  local backup="$base/backups/dawei-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$skills" "$backup"

  [[ -e "$base/AGENTS.md" ]] && cp "$base/AGENTS.md" "$backup/AGENTS.md"
  cp "$SRC/codex/AGENTS.md" "$base/AGENTS.md"

  local n_skills=0
  for s in "$SRC"/.cursor/skills/dawei-*; do
    [[ -e "$s" ]] || continue
    local name; name="$(basename "$s")"
    [[ -e "$skills/$name" ]] && cp -R "$skills/$name" "$backup/$name"
    rm -rf "$skills/$name"
    cp -R "$s" "$skills/$name"; n_skills=$((n_skills+1))
  done
  ok "Codex/GPT: 写入 AGENTS.md 与 $n_skills 个 Skills 到 $base"
  info "备份目录：$backup"
}

case "$MODE" in
  cursor) install_cursor "$TARGET" ;;
  gpt)    install_gpt ;;
  both)   install_cursor "$TARGET"; install_gpt ;;
  *) die "未知模式：$MODE" ;;
esac

ok "完成。完全重启 Cursor / 新开 Codex 会话后生效。输入 \`在吗\` 可验证。"
