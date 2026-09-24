#!/usr/bin/env bash

DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

SEARCH_TERM="$1"

# Base SQL query
BASE_SQL="SELECT nodes.title, nodes.file FROM nodes JOIN files ON nodes.file = files.file WHERE nodes.title IS NOT NULL AND nodes.title != ''"

if [[ -z "$SEARCH_TERM" ]]; then
    # --- CASE 1: No arguments passed, load all nodes into fzf ---
    QUERY="$BASE_SQL ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
else
    # --- CASE 2: Argument passed, filter in SQLite first ---
    # Escape single quotes in user input for SQL safety
    SAFE_TERM="${SEARCH_TERM//\'/\'\'}"
    QUERY="$BASE_SQL AND nodes.title LIKE '%$SAFE_TERM%' ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
fi

# Count how many matching lines were returned
MATCH_COUNT=$(echo "$RESULTS" | sed '/^$/d' | wc -l)

if [[ $MATCH_COUNT -eq 0 ]]; then
    echo "No Org-roam nodes matching: \"$SEARCH_TERM\"" >&2
    exit 1

elif [[ $MATCH_COUNT -eq 1 ]]; then
    # --- Direct Hit: Open immediately without opening fzf ---
    SELECTION="$RESULTS"

else
    # --- Multiple Matches (or full list): Interactive selection via fzf ---
    SELECTION=$(echo "$RESULTS" \
        | fzf --exact \
              --delimiter=$'\t' \
              --with-nth=1 \
              --tiebreak=index \
              ${SEARCH_TERM:+--query="$SEARCH_TERM"} \
              --preview 'head -n 30 {2}' \
              --preview-window=right:50%:wrap)
fi

# Open selected node if a choice was made
if [[ -n "$SELECTION" ]]; then
    TITLE=$(echo "$SELECTION" | cut -f1)
    FILE=$(echo "$SELECTION" | cut -f2)

    emacsclient -n "$FILE"
    echo "Visited node: \"$TITLE\""
fi
