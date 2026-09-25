# `roam-find` Manual & Usage Guide

`roam-find` is a lightweight, terminal-native launcher for Org-roam nodes that bypasses Elisp minibuffer overhead by querying the Org-roam SQLite database directly.

---

## 1. Core Features

- **Direct Hit Routing:** If a query yields a single unique match, it visits the node in Emacs instantly without launching the interactive picker.
- **Fast Interactive Filtering:** If multiple matches (or no arguments) are passed, it streams items sorted by modification date (`mtime DESC`) into `fzf`.
- **Live Node Preview:** Standard 30-line `head` preview pane inside `fzf` rendered on the fly.
- **Terminal Session Log:** Leaves a record in your shell history printing the exact node title visited.

---

## 2. Command Reference

| Command / Option | Action |
| :--- | :--- |
| `roam-find` | Opens interactive `fzf` buffer listing all nodes sorted by most recent edit. |
| `roam-find <term>` | Searches for `<term>`. Visits directly if 1 match; opens `fzf` if multiple. |
| `roam-find -h`, `--help` | Prints concise command-line usage to stdout. |
| `roam-find -v`, `--verbose-help` | Opens this Markdown documentation buffer in `emacsclient`. |

---

## 3. Workflow Examples

### Instant Direct Node Lookup
When you know a unique string in a title:
```bash
roam-find bashrc
```
> **Behavior:** Bypasses `fzf` entirely and opens `20260107114920-bashrc_file.org` in Emacs immediately.

### Pre-Filtered Ambiguous Search
When searching broad topics:
```bash
roam-find emacs
```
> **Behavior:** Opens `fzf` pre-seeded with all nodes containing "emacs", ordered by most recently modified.

### Terminal History Integration (`Ctrl-r`)
Combine `roam-find` with shell history for fast navigation to frequently accessed nodes:
```bash
# Press Ctrl-r in bash, type e.g. "bashrc", and hit Enter
```

---

## 4. Dependencies & Paths

- **Database Path:** `~/.config/emacs/org-roam.db` (or `~/.emacs.d/org-roam.db`)
- **Required Utilities:** `sqlite3`, `fzf`, `emacsclient`, `tr`, `cut`
