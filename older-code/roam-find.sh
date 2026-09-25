#!/usr/bin/env bash

DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

# 1. Fetch title and file path
# 2. Strip surrounding literal quotes
# 3. Pass clean fields to fzf
SELECTION=$(sqlite3 -separator $'\t' "$DB_PATH" \
    "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' ORDER BY title;" \
    | tr -d '"' \
    | fzf --exact --delimiter=$'\t' --with-nth=1 --preview 'head -n 30 {2}' --preview-window=right:50%:wrap)

if [[ -n "$SELECTION" ]]; then
    # Extract field 2 (the cleaned file path)
    FILE=$(echo "$SELECTION" | cut -f2)
    emacsclient -n "$FILE"
fi
