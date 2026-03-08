#!/usr/bin/env bash
#
# Checks all PDF files under sources/ and renames any that
# don't follow kebab-case convention: [a-z0-9](-[a-z0-9]+)*\.pdf
#
# Usage:
#   ./rename-to-kebab-case.sh          # dry-run (preview only)
#   ./rename-to-kebab-case.sh --apply  # actually rename files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY=false

if [[ "${1:-}" == "--apply" ]]; then
    APPLY=true
fi

to_kebab_case() {
    local name="$1"

    # Remove .pdf extension, will re-add later
    name="${name%.pdf}"

    # Replace common separators with hyphens
    name="${name// - /-}"
    name="${name// /-}"
    name="${name//_/-}"

    # Remove parentheses and their surrounding hyphens
    # e.g. "-(2008)" → "-2008"
    name=$(echo "$name" | sed -E 's/\(([^)]*)\)/\1/g')

    # Remove characters that aren't alphanumeric or hyphens
    name=$(echo "$name" | sed -E "s/[^a-zA-Z0-9-]//g")

    # Collapse multiple consecutive hyphens into one
    name=$(echo "$name" | sed -E 's/-+/-/g')

    # Remove leading/trailing hyphens
    name=$(echo "$name" | sed -E 's/^-+//; s/-+$//')

    # Lowercase everything
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    echo "${name}.pdf"
}

is_kebab_case() {
    local filename="$1"
    [[ "$filename" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.pdf$ ]]
}

echo "=== PDF Kebab-Case Rename Check ==="
echo "    Directory: $SCRIPT_DIR"
echo "    Mode: $(if $APPLY; then echo 'APPLY (will rename)'; else echo 'DRY-RUN (preview only)'; fi)"
echo ""

found=0
renamed=0

while IFS= read -r filepath; do
    filename=$(basename "$filepath")
    dirpath=$(dirname "$filepath")

    if is_kebab_case "$filename"; then
        echo "  ✓ $filename"
        continue
    fi

    found=$((found + 1))
    new_name=$(to_kebab_case "$filename")

    echo "  ✗ $filename"
    echo "    → $new_name"

    if $APPLY; then
        if [[ "$filename" == "$new_name" ]]; then
            echo "    ⚠ SKIPPED: already correct"
        elif [[ -e "$dirpath/$new_name" ]] && [[ "$(basename "$(readlink -f "$dirpath/$new_name")")" != "$filename" ]]; then
            echo "    ⚠ SKIPPED: target file already exists!"
        else
            # Two-step rename to handle case-insensitive filesystems (macOS)
            mv "$filepath" "$filepath.tmp"
            mv "$filepath.tmp" "$dirpath/$new_name"
            echo "    ✔ Renamed successfully"
            renamed=$((renamed + 1))
        fi
    fi

    echo ""
done < <(find "$SCRIPT_DIR" -name "*.pdf" -type f | sort)

echo "---"
echo "Total PDFs scanned: $((found + $(find "$SCRIPT_DIR" -name "*.pdf" -type f | wc -l) - found))"
echo "Non-compliant: $found"
if $APPLY; then
    echo "Renamed: $renamed"
else
    if [[ $found -gt 0 ]]; then
        echo ""
        echo "Run with --apply to rename:"
        echo "  ./sources/rename-to-kebab-case.sh --apply"
    fi
fi
