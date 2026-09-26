#!/usr/bin/env bash

DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"
HELP_FILE="$HOME/Documents/2026/20260901-standalone-org-roam/roam-insert-verbose-help.md"

show_brief_help() {
    cat << 'EOF'
Usage: roam-insert-recently-modified-shown-first-with-input.sh [OPTION] [SEARCH_TERM]

Instantly select a pre-existing Org-roam node and insert an Org-mode ID link into your 
active Emacs buffer, appending a newline.  Supports org-roam aliases.

Options:
  -h, --help           Show this brief command-line help message and exit.
  -v, --verbose-help   Open the full Markdown manual in Emacs.

Examples:
  roam-insert-recently-modified-shown-first-with-input.sh
      Interactive search through all nodes (sorted by mtime).

  roam-insert-recently-modified-shown-first-with-input.sh "bashrc"
      Direct hit or pre-filtered fzf search for "bashrc".
EOF
}

show_verbose_help() {
    if [[ -f "$HELP_FILE" ]]; then
        emacsclient -n "$HELP_FILE"
    else
        echo "Error: Help file not found at $HELP_FILE" >&2
        exit 1
    fi
}

case "$1" in
    -h|--help) show_brief_help; exit 0 ;;
    -v|--verbose-help) show_verbose_help; exit 0 ;;
esac

[[ ! -f "$DB_PATH" ]] && { echo "Error: Database not found at $DB_PATH" >&2; exit 1; }

SEARCH_TERM="$1"

# Base SQL pulling Title, ID, File, and Aliases
BASE_SQL="SELECT nodes.title, nodes.id, nodes.file, COALESCE(GROUP_CONCAT(aliases.alias, ' | '), '') AS alias_list FROM nodes JOIN files ON nodes.file = files.file LEFT JOIN aliases ON nodes.id = aliases.node_id WHERE nodes.title IS NOT NULL AND nodes.title != '' GROUP BY nodes.id"

if [[ -z "$SEARCH_TERM" ]]; then
    QUERY="$BASE_SQL ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
else
    SAFE_TERM="${SEARCH_TERM//\'/\'\'}"
    QUERY="$BASE_SQL HAVING nodes.title LIKE '%$SAFE_TERM%' OR alias_list LIKE '%$SAFE_TERM%' ORDER BY files.mtime DESC;"
    RESULTS=$(sqlite3 -separator $'\t' "$DB_PATH" "$QUERY" | tr -d '"')
fi

MATCH_COUNT=$(echo "$RESULTS" | sed '/^$/d' | wc -l)

if [[ $MATCH_COUNT -eq 0 ]]; then
    echo "No Org-roam nodes or aliases matching: \"$SEARCH_TERM\"" >&2
    exit 1
elif [[ $MATCH_COUNT -eq 1 ]]; then
    SELECTION="$RESULTS"
else
    # Display Title and Alias list in fzf (cols 1 and 4), preview column 3 (File)
    SELECTION=$(echo "$RESULTS" \
        | fzf --exact \
              --delimiter=$'\t' \
              --with-nth=1,4 \
              --tiebreak=index \
              ${SEARCH_TERM:+--query="$SEARCH_TERM"} \
              --preview 'head -n 30 {3}' \
              --preview-window=right:50%:wrap)
fi

if [[ -n "$SELECTION" ]]; then
    TITLE=$(echo "$SELECTION" | cut -f1)
    ID=$(echo "$SELECTION" | cut -f2)
    FILE=$(echo "$SELECTION" | cut -f3)

    if [[ ! -f "$FILE" ]]; then
        echo "Error: Node file does not exist: $FILE" >&2
        exit 1
    fi

    ORG_LINK="[[id:${ID}][${TITLE}]]"
    SAFE_LINK="${ORG_LINK//\"/\\\"}"

    emacsclient -e "(with-current-buffer (window-buffer (selected-window)) (insert \"$SAFE_LINK\\n\"))" > /dev/null

    echo "Inserted Org-roam link: $ORG_LINK"
fi
