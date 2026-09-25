# `roam-insert` Manual & Usage Guide

`roam-insert-recently-modified-shown-first-with-input.sh` is a terminal-native tool that bypasses Elisp completion overhead to query your Org-roam SQLite database directly, select a node using `fzf`, and insert a standard Org-mode ID link into your active Emacs buffer—followed immediately by a newline.

---

## 1. Core Features

- **Direct Hit Routing:** If an argument yields a single unique match, the link is inserted directly into Emacs without popping up `fzf`.
- **Fast Interactive Filtering:** When multiple matches exist (or no argument is provided), nodes are streamed into `fzf` ordered by most recently modified (`mtime DESC`).
- **File Validation:** Verifies that the underlying `.org` file exists on disk before attempting to insert the link into Emacs.
- **Active Buffer Targeting:** Inserts the link into whichever buffer is currently selected in Emacs, placing the cursor on a fresh line below the link (`\n`).

---

## 2. Command Reference

| Command / Option | Action |
| :--- | :--- |
| `roam-insert-recently-modified-shown-first-with-input.sh` | Opens interactive `fzf` buffer listing all nodes sorted by most recent edit. |
| `roam-insert-recently-modified-shown-first-with-input.sh <term>` | Searches for single-word `<term>`. |
| `roam-insert-recently-modified-shown-first-with-input.sh "<multi word term>"` | Best practice for multi-word titles containing spaces. |
| `roam-insert-recently-modified-shown-first-with-input.sh -h`, `--help` | Prints concise command-line usage to stdout. |
| `roam-insert-recently-modified-shown-first-with-input.sh -v`, `--verbose-help` | Opens this Markdown documentation buffer in `emacsclient`. |

---

## 3. Workflow Examples

### Standard Multi-Word Link Insertion
Place your cursor in your active `.org` buffer in Emacs, then execute from your terminal:
```bash
roam-insert-recently-modified-shown-first-with-input.sh "my node title"
```
> **Result in Emacs:**
> ```org
> [[id:12345678-abcd-1234-abcd-1234567890ab][my node title]]
> [cursor lands here on a new line]
> ```

### Single Direct Hit Insertion
When you know a unique keyword in a node title:
```bash
roam-insert-recently-modified-shown-first-with-input.sh bashrc
```
> **Behavior:** Bypasses `fzf` entirely and instantly inserts `[[id:...][bashrc file]]` followed by a newline into Emacs.

### Interactive Selection with Filter
When looking through broader topics:
```bash
roam-insert-recently-modified-shown-first-with-input.sh emacs
```
> **Behavior:** Opens `fzf` pre-seeded with all matching nodes containing "emacs", showing a 30-line file preview in the right pane. Selecting a node inserts its link and closes the prompt.

---

## 4. Dependencies & Paths

- **Database Path:** `~/.config/emacs/org-roam.db` (or `~/.emacs.d/org-roam.db`)
- **Help File Path:** `~/.local/share/roam-insert/roam-insert-verbose-help.md`
- **Required Utilities:** `sqlite3`, `fzf`, `emacsclient`, `tr`, `cut`
