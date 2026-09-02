# Full Transcript: 20260901-standalone-org-roam


# PROMPT 1
AFAIK org-roam-node-find was never truly snappy.  it makes me think about somehow creating a tool to access roam nodes that runs in the terminal and then uses emacsclient to visit a node in emacs.  but it can't be that easy - seems like cheating.

node-find is still slow, whether it's sqlite-builtin or sqlite-module.

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260901_002414_capture.md")

---

# RESPONSE 1
It is **not** cheating at all—in fact, external CLI tools querying the database directly are often orders of magnitude faster than Emacs formatting nodes in Elisp!

Because Org-roam uses a standard SQLite database stored locally (usually at `~/.config/emacs/org-roam.db` or `~/.emacs.d/org-roam.db`), you can query your entire network of notes instantly using command-line tools like `sqlite3`, `duckdb`, `ripgrep`, or `fzf`, and then pass the target file directly to `emacsclient`.

The reason `org-roam-node-find` is notoriously sluggish inside Emacs—even with a fully synced SQLite database—is not usually the database query itself. It's the **Elisp completion overhead**: Emacs has to read thousands of rows, instantiate an Elisp node structure for *every single node*, apply display properties/formatting (`org-roam-node-display-template`), and hand that massive list over to minibuffer completion (Vertico, Helm, Ivy, etc.).

---

### Terminal Org-Roam Finder (`roam-find`)

Here is a lightweight shell script using `sqlite3`, `fzf`, and `emacsclient`. It bypasses Elisp object generation entirely by running a single SQL query directly against the SQLite database, feeding titles to `fzf`, and opening the selected file in your running Emacs session.

#### 1. The Script (`roam-find`)

Save this script as `roam-find` somewhere in your `PATH` (e.g., `~/bin/roam-find` or `~/.local/bin/roam-find`) and make it executable (`chmod +x roam-find`):

```bash
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

```

---

### Why This Approach Is Blazing Fast

1. **Native SQLite Performance:** `sqlite3` reads indexed tables in standard C speed (~2-5 milliseconds across tens of thousands of nodes).
2. **Zero Elisp Garbage Collection:** Emacs never has to allocate heap memory or execute dynamic string formatting loops for nodes you aren't actively visiting.
3. **`fzf` Filtering:** Instantaneous fuzzy matching and live previews without minibuffer rendering latency.

---

### Quick Check: Database Location

If running `sqlite3 ~/.config/emacs/org-roam.db "SELECT count(*) FROM nodes;"` returns `0` or an error, verify your exact database file location inside Emacs:

```elisp
M-: (message org-roam-db-location)

```

Update `DB_PATH` in the script to point to that file.

If you like this workflow, you can even map a hotkey in your terminal or window manager to trigger `roam-find` instantly from anywhere on your desktop!

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260901_002420_capture.md")

---
