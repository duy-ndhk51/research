#!/usr/bin/env bash
#
# Regenerate the Topic Index and Playground tables in README.md
# by scanning domain folders (01-* to 11-*) and playground/.
#
# Usage:  bash scripts/update-topic-index.sh
# Run from the repository root.

set -euo pipefail

README="README.md"

if [[ ! -f "$README" ]]; then
  echo "Error: $README not found. Run this script from the repo root." >&2
  exit 1
fi

domain_label() {
  case "$1" in
    01-*) echo "Fundamentals" ;;
    02-*) echo "System Design" ;;
    03-*) echo "Languages" ;;
    04-*) echo "Frontend" ;;
    05-*) echo "Backend" ;;
    06-*) echo "DevOps & Infra" ;;
    07-*) echo "Databases" ;;
    08-*) echo "Security" ;;
    09-*) echo "Testing" ;;
    10-*) echo "Soft Skills" ;;
    11-*) echo "AI/ML" ;;
    *)    echo "Other" ;;
  esac
}

# --- Build topic index ---------------------------------------------------

topic_table="| # | Topic | Domain | Tags |\n|---|-------|--------|------|\n"
count=0

while IFS= read -r file; do
  title=$(head -1 "$file" | sed 's/^#[[:space:]]*//')
  folder=$(echo "$file" | cut -d'/' -f1)
  domain=$(domain_label "$folder")
  count=$((count + 1))
  topic_table+="| ${count} | [${title}](./${file}) | ${domain} |  |\n"
done < <(find [0-9][0-9]-* -name "*.md" ! -name "README.md" -type f | sort)

# --- Build playground index -----------------------------------------------

playground_table="| # | Topic | Description |\n|---|-------|-------------|\n"
pg_count=0

for summary in playground/*/SUMMARY.md; do
  [[ -f "$summary" ]] || continue
  title=$(head -1 "$summary" | sed 's/^#[[:space:]]*//')
  pg_count=$((pg_count + 1))
  playground_table+="| ${pg_count} | [${title}](./${summary}) |  |\n"
done

# --- Replace sections in README ------------------------------------------

tmpfile=$(mktemp)

awk -v topic="$topic_table" -v playground="$playground_table" '
  /<!-- TOPIC-INDEX-START -->/ {
    print
    printf "%s", topic
    skip = 1
    next
  }
  /<!-- TOPIC-INDEX-END -->/ {
    skip = 0
    print
    next
  }
  /<!-- PLAYGROUND-INDEX-START -->/ {
    print
    printf "%s", playground
    skip = 1
    next
  }
  /<!-- PLAYGROUND-INDEX-END -->/ {
    skip = 0
    print
    next
  }
  !skip { print }
' "$README" > "$tmpfile"

mv "$tmpfile" "$README"

echo "✓ Topic Index updated: ${count} topics, ${pg_count} playground experiments"
