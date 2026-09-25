#!/usr/bin/env bash

# Paths
DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"

# Path for verbose help file
HELP_FILE="$HOME/Documents/2026/20260901-standalone-org-roam/roam-find-verbose-help.md"

# --- HELP HANDLERS ---

show_brief_help() {
    cat << 'EOF'
Usage: roam-find [OPTION] [SEARCH_TERM]

Instantly search and open pre-existing Org-roam nodes in Emacs using SQLite and fzf.

Options:
  -h, --help           Show this brief command-line help message and exit.
  -v, --verbose-help   Open the full Markdown manual in Emacs.

Examples:
  roam-find            Interactive search through all notes (sorted by mtime).
  roam-find bashrc     Direct hit or pre-filtered fzf search for "bashrc".
EOF
}

show_verbose_help() {
    if [[ -f "$HELP_FILE" ]]; then
        emacsclient -n "$HELP_FILE"
        echo "Opened verbose documentation in Emacs: $HELP_FILE"
    else
        echo "Error: Verbose help file not found at $HELP_FILE" >&2
        exit 1
    fi
}

# Parse options
case "$1" in
    -h|--help)
        show_brief_help
        exit 0
        ;;
    -v|--verbose-help)
        show_verbose_help
        exit 0
        ;;
esac

# Check database existence
if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

SEARCH_TERM="$1"
BASE_SQL="SELECT nodes.title, nodes.file FROM nodes JOIN files ON nodes.file = files.file WHERE nodes.title IS NOT NULL AND nodes.title != ''"

if [[ -z "$SEARCH_TERM" ]]; then
    # Case 1: No query passed -> load all nodes ordered by recent mtime
    QUERY="$BASE_SQL ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
else
    # Case 2: Query passed -> filter in SQLite
    SAFE_TERM="${SEARCH_TERM//\'/\'\'}"
    QUERY="$BASE_SQL AND nodes.title LIKE '%$SAFE_TERM%' ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
fi

MATCH_COUNT=$(echo "$RESULTS" | sed '/^$/d' | wc -l)

if [[ $MATCH_COUNT -eq 0 ]]; then
    echo "No Org-roam nodes matching: \"$SEARCH_TERM\"" >&2
    exit 1

elif [[ $MATCH_COUNT -eq 1 ]]; then
    # Single match -> open directly
    SELECTION="$RESULTS"

else
    # Multiple matches -> launch fzf interface
    SELECTION=$(echo "$RESULTS" \
        | fzf --exact \
              --delimiter=$'\t' \
              --with-nth=1 \
              --tiebreak=index \
              ${SEARCH_TERM:+--query="$SEARCH_TERM"} \
              --preview 'head -n 30 {2}' \
              --preview-window=right:50%:wrap)
fi

# Visit node in Emacs
if [[ -n "$SELECTION" ]]; then
    TITLE=$(echo "$SELECTION" | cut -f1)
    FILE=$(echo "$SELECTION" | cut -f2)

    emacsclient -n "$FILE"
    echo "Visited node: \"$TITLE\""
fi
