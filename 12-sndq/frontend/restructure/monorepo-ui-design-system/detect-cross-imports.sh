#!/usr/bin/env bash
#
# detect-cross-imports.sh — Component lifting candidate detector
#
# Scans the frontend source tree for:
#   1. Shared component usage (src/components/ imported by modules)
#   2. Cross-module component imports (module A importing module B's components)
#   3. Pending TODO(lift) markers
#
# Usage:
#   bash detect-cross-imports.sh [src-directory]
#
# Defaults to sndq-fe/src if run from monorepo root (sndq/).

set -uo pipefail

SRC_DIR="${1:-sndq-fe/src}"

if [ ! -d "$SRC_DIR/modules" ]; then
  echo "Error: $SRC_DIR/modules not found."
  echo "Usage: bash detect-cross-imports.sh [path/to/src]"
  echo "Example: bash detect-cross-imports.sh sndq-fe/src"
  exit 1
fi

MODULES_DIR="$SRC_DIR/modules"

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
RESET='\033[0m'

divider() {
  echo ""
  echo -e "${DIM}$(printf '%.0s─' {1..70})${RESET}"
  echo ""
}

# ─────────────────────────────────────────────────────────
# Section 1: Shared component usage
# ─────────────────────────────────────────────────────────

echo -e "${BOLD}${CYAN}COMPONENT LIFT CANDIDATE REPORT${RESET}"
echo -e "${DIM}Source: $SRC_DIR${RESET}"
echo -e "${DIM}Generated: $(date '+%Y-%m-%d %H:%M')${RESET}"

divider

echo -e "${BOLD}1. SHARED COMPONENT USAGE${RESET}"
echo -e "${DIM}Components in src/components/ imported by modules — sorted by import count.${RESET}"
echo -e "${DIM}High counts = already shared cross-module = lift candidates for blocks/primitives.${RESET}"
echo ""

grep -rh "from '@/components/" "$MODULES_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null \
  | sed "s/.*from '@\/components\///" \
  | sed "s/['/].*//" \
  | sort \
  | uniq -c \
  | sort -rn \
  | while read -r count component; do
    if [ "$count" -ge 20 ]; then
      echo -e "  ${RED}${count}${RESET}  $component"
    elif [ "$count" -ge 10 ]; then
      echo -e "  ${YELLOW}${count}${RESET}  $component"
    else
      echo -e "  ${DIM}${count}${RESET}  $component"
    fi
  done

total_shared=$(grep -rh "from '@/components/" "$MODULES_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo -e "  ${DIM}Total shared component imports: ${total_shared}${RESET}"

# ─────────────────────────────────────────────────────────
# Section 2: Cross-module component imports
# ─────────────────────────────────────────────────────────

divider

echo -e "${BOLD}2. CROSS-MODULE COMPONENT IMPORTS${RESET}"
echo -e "${DIM}Module A importing components from module B — boundary violations.${RESET}"
echo -e "${DIM}These should either be lifted to src/components/ or to @sndq/ui.${RESET}"
echo ""

grep -rn "from '@/modules/[^']*components" "$MODULES_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null \
  | while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    import_path=$(echo "$line" | grep -o "from '@/modules/[^']*'" | sed "s/from '//" | sed "s/'//")

    consuming_module=$(echo "$file" | sed "s|$MODULES_DIR/||" | cut -d/ -f1)
    source_module=$(echo "$import_path" | sed "s|@/modules/||" | cut -d/ -f1)

    if [ "$consuming_module" != "$source_module" ]; then
      echo -e "  ${YELLOW}${consuming_module}${RESET} ← ${source_module}"
      echo -e "    ${DIM}${file}${RESET}"
      echo -e "    ${DIM}${import_path}${RESET}"
      echo ""
    fi
  done

cross_count=$(grep -rn "from '@/modules/[^']*components" "$MODULES_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null \
  | while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    import_path=$(echo "$line" | grep -o "from '@/modules/[^']*'" | sed "s/from '//" | sed "s/'//")
    consuming=$(echo "$file" | sed "s|$MODULES_DIR/||" | cut -d/ -f1)
    source=$(echo "$import_path" | sed "s|@/modules/||" | cut -d/ -f1)
    if [ "$consuming" != "$source" ]; then
      echo "x"
    fi
  done | wc -l | tr -d ' ')

echo -e "  ${DIM}Total cross-module boundary violations: ${cross_count}${RESET}"

# ─────────────────────────────────────────────────────────
# Section 2b: Cross-module summary by source
# ─────────────────────────────────────────────────────────

divider

echo -e "${BOLD}2b. CROSS-MODULE SUMMARY (by source module)${RESET}"
echo -e "${DIM}Which modules' components are most imported by OTHER modules — top lift priorities.${RESET}"
echo ""

grep -rn "from '@/modules/[^']*components" "$MODULES_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null \
  | while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    import_path=$(echo "$line" | grep -o "from '@/modules/[^']*'" | sed "s/from '//" | sed "s/'//")
    consuming=$(echo "$file" | sed "s|$MODULES_DIR/||" | cut -d/ -f1)
    source=$(echo "$import_path" | sed "s|@/modules/||" | cut -d/ -f1)
    if [ "$consuming" != "$source" ]; then
      echo "$source"
    fi
  done \
  | sort \
  | uniq -c \
  | sort -rn \
  | while read -r count mod; do
    if [ "$count" -ge 10 ]; then
      echo -e "  ${RED}${count}${RESET}  ${mod}/components/"
    elif [ "$count" -ge 5 ]; then
      echo -e "  ${YELLOW}${count}${RESET}  ${mod}/components/"
    else
      echo -e "  ${DIM}${count}${RESET}  ${mod}/components/"
    fi
  done

# ─────────────────────────────────────────────────────────
# Section 3: Pending TODO(lift) markers
# ─────────────────────────────────────────────────────────

divider

echo -e "${BOLD}3. PENDING TODO(lift) MARKERS${RESET}"
echo -e "${DIM}Components flagged for lifting during PR review.${RESET}"
echo ""

todo_count=$(grep -rn "TODO(lift)" "$SRC_DIR" \
  --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l | tr -d ' ')

if [ "$todo_count" -eq 0 ]; then
  echo -e "  ${GREEN}No pending TODO(lift) markers found.${RESET}"
  echo -e "  ${DIM}Add markers during PR review:${RESET}"
  echo -e "  ${DIM}  // TODO(lift): cross-module import, candidate for blocks${RESET}"
else
  grep -rn "TODO(lift)" "$SRC_DIR" \
    --include="*.tsx" --include="*.ts" 2>/dev/null \
    | while IFS= read -r line; do
      file=$(echo "$line" | cut -d: -f1)
      lineno=$(echo "$line" | cut -d: -f2)
      content=$(echo "$line" | cut -d: -f3- | sed 's/^[[:space:]]*//')
      echo -e "  ${YELLOW}${file}:${lineno}${RESET}"
      echo -e "    ${content}"
      echo ""
    done
  echo -e "  ${DIM}Total: ${todo_count} pending lift markers${RESET}"
fi

divider

echo -e "${BOLD}${GREEN}Done.${RESET} Run monthly or before sprint planning."
echo -e "${DIM}See component-lifting-process.md for the full process guide.${RESET}"
echo ""
