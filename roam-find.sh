#!/usr/bin/env bash

# Path to your Org-roam SQLite database
DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"

# Fallback for standard ~/.emacs.d setup if not in ~/.config/emacs
if [[ ! -f "$DB_PATH" ]]; then
    DB_PATH="$HOME/.emacs.d/org-roam.db"
fi

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

# 1. Query SQLite for Title + File path (delimited by TAB)
# 2. Pipe to fzf, showing only the Title
# 3. Open selected file in emacsclient
SELECTION=$(sqlite3 -separator $'\t' "$DB_PATH" \
    "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' ORDER BY title;" \
    | fzf --delimiter=$'\t' --with-nth=1 --preview 'head -n 30 {2}' --preview-window=right:50%:wrap)

if [[ -n "$SELECTION" ]]; then
    FILE=$(echo "$SELECTION" | cut -f2 | tr -d '"')
    emacsclient -n "$FILE"
fi
