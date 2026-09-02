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

# PROMPT 2
the preview behavior is not yet working as expected.  we see in the preview output like:

head: cannot open '"/home/dad84/Documents/RoamNotes/20260107114920-bashrc_file.org"' for reading: No such file or directory

I had to type that manually since I could not seem to copy and paste from that preview pane

how can we build up that SELECTION= line piece by piece so we comprehend what is going on in it?

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260901_234021_capture.md")

---

# RESPONSE 2
The extra escaped quotes (`"`) around the file path in the SQLite output are tripping up `head`. When `sqlite3` exports strings containing certain characters or formatting, it often wraps the column value in literal quotation marks, so `fzf` receives `'"/home/dad84/..."'` instead of `/home/dad84/...`.

Deconstructing that line step-by-step makes it easy to isolate and verify each stage directly in your shell.

---

### Step 1: Check the Raw Database Output

First, test what `sqlite3` actually prints for titles and file paths.

```bash
sqlite3 -separator $'\t' ~/.emacs.d/org-roam.db "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' LIMIT 5;"

```

* **What to look for:** Look closely at the second column (the file path). If you see literal double quotes wrapping the path (e.g., `"/home/dad84/..."`), that's the culprit.

---

### Step 2: Strip Quotes and Clean the Output

To clean those extra quotes before `fzf` gets them, pipe the output through `tr` or `sed` to remove double quotes (`"`):

```bash
sqlite3 -separator $'\t' ~/.emacs.d/org-roam.db "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' LIMIT 5;" | tr -d '"'

```

* **What to look for:** The paths should now be clean, unquoted strings like `/home/dad84/Documents/RoamNotes/20260107114920-bashrc_file.org`.

---

### Step 3: Test `fzf` Field Splitting and Preview Separately

`fzf` uses `{2}` to reference the second field (the path) based on `--delimiter=$'\t'`. Now test `fzf` with a small batch of clean data:

```bash
sqlite3 -separator $'\t' ~/.emacs.d/org-roam.db "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' LIMIT 10;" \
  | tr -d '"' \
  | fzf --delimiter=$'\t' --with-nth=1 --preview 'head -n 30 {2}'

```

* **What to look for:** As you move up and down in `fzf`, the right pane should now successfully read field `{2}` and render the first 30 lines of the org file.

---

### The Fixed Script

Applying `tr -d '"'` directly to the SQLite output before handing it to `fzf` resolves the preview error and simplifies extracting the file path at the end:

```bash
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
    | fzf --delimiter=$'\t' --with-nth=1 --preview 'head -n 30 {2}' --preview-window=right:50%:wrap)

if [[ -n "$SELECTION" ]]; then
    # Extract field 2 (the cleaned file path)
    FILE=$(echo "$SELECTION" | cut -f2)
    emacsclient -n "$FILE"
fi

```

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260901_234027_capture.md")

---

# PROMPT 3
seems to be working and is very cool.  now what if we wanted to see the most recently edited/modified nodes in fzf at the top, rather than sorted by node title?

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260902_134248_capture.md")

---

# RESPONSE 3
To rank your most recently modified notes at the top, you can adjust the query to sort by the file's modification time stored in Org-roam's database (`mtime`), or explicitly instruct `fzf` not to re-sort the incoming stream.

Org-roam tracks the last modified timestamp in the `mtime` column of the `files` table (or derived on the `nodes` table). Sorting directly by `mtime DESC` in SQLite ensures the most recently updated notes hit the top of your list immediately.

---

### Step 1: Updating the SQL Query

Modify the SQLite `ORDER BY` clause to target `mtime` in descending order (`DESC`):

```sql
SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' ORDER BY mtime DESC;

```

---

### Step 2: Preserving Order in `fzf` (`--no-sort`)

By default, as soon as you start typing a search query in `fzf`, it re-ranks items by fuzzy-match score. To ensure that your **initial view** (before typing) presents your most recently edited files at the top, add the `--no-sort` flag, or keep standard fuzzy matching for active queries while preserving the default SQL ordering on launch.

---

### Updated `roam-find` Script

Here is the complete updated script sorting by recent modification time:

```bash
#!/usr/bin/env bash

DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/emacs/org-roam.db"
[[ ! -f "$DB_PATH" ]] && DB_PATH="$HOME/.emacs.d/org-roam.db"

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Org-roam database not found at $DB_PATH" >&2
    exit 1
fi

# 1. Fetch title and file path, ORDER BY mtime DESC (newest first)
# 2. Strip surrounding quotes
# 3. Pass clean stream to fzf
SELECTION=$(sqlite3 -separator $'\t' "$DB_PATH" \
    "SELECT title, file FROM nodes WHERE title IS NOT NULL AND title != '' ORDER BY mtime DESC;" \
    | tr -d '"' \
    | fzf --delimiter=$'\t' \
          --with-nth=1 \
          --tiebreak=index \
          --preview 'head -n 30 {2}' \
          --preview-window=right:50%:wrap)

if [[ -n "$SELECTION" ]]; then
    FILE=$(echo "$SELECTION" | cut -f2)
    emacsclient -n "$FILE"
fi

```

### Key Change to Note

* **`--tiebreak=index`**: When `fzf` finds multiple equal fuzzy matches for a search term, `--tiebreak=index` tells it to prioritize items higher up in the original input stream (which means your more recently modified notes break ties!).

Edit: (find-file "/home/dad84/Documents/2026/20260901-standalone-org-roam/chat/captures/20260902_134256_capture.md")

---
