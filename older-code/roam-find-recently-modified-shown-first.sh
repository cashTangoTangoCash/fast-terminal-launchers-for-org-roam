#!/usr/bin/env bash

DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

# 1. Fetch title and file path joined on mtime DESC
# 2. Clean literal quotes
# 3. Present titles in fzf with exact matching, tiebreak by index, and live preview
SELECTION=$(sqlite3 -separator $'\t' "$DB_PATH" \
    "SELECT nodes.title, nodes.file FROM nodes JOIN files ON nodes.file = files.file WHERE nodes.title IS NOT NULL AND nodes.title != '' ORDER BY files.mtime DESC;" \
    | tr -d '"' \
    | fzf --exact \
          --delimiter=$'\t' \
          --with-nth=1 \
          --tiebreak=index \
          --preview 'head -n 30 {2}' \
          --preview-window=right:50%:wrap)

if [[ -n "$SELECTION" ]]; then
    # Separate field 1 (Title) and field 2 (File path)
    TITLE=$(echo "$SELECTION" | cut -f1)
    FILE=$(echo "$SELECTION" | cut -f2)

    # Open in Emacs
    emacsclient -n "$FILE"

    # Print record to terminal
    echo "Visited node: \"$TITLE\""
fi
