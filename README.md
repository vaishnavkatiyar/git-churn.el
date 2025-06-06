# git-churn.el

Highlight lines in Emacs buffers based on how frequently they were changed in Git history, and annotate how many commits have touched each line.

## ✨ Features

* 🌟 **Visualize Git churn per line**: high-churn lines are highlighted in red, stable lines in green.
* ➕ **Inline commit counts**: shows how many times a line was changed (e.g., `⟶ 5x`).
* ⚖️ **Range support**: restrict analysis to a specific line span (e.g., lines 10–20).
* ❌ **Non-intrusive overlays**: easy to toggle on/off.

Great for:
* Spotting unstable or heavily modified code
* Focusing reviews on volatile sections
* Understanding code evolution over time

## 📦 Installation

### Using `use-package` (recommended)

```elisp
(use-package git-churn
  ;; :load-path "/path/to/git-churn.el"
  :straight (git-churn :type git :host github :repo "vaishnavkatiyar/git-churn.el")
  :commands (git-churn-visualize-buffer git-churn-clear-overlays))
```

### Manual

Download `git-churn.el` into your load path and add:

```elisp
(load "/path/to/git-churn.el")
```

## 🧠 Usage

From any Git-tracked buffer:

### 🔍 Visualize Git churn

```elisp
M-x git-churn-visualize-buffer
```

* Prompts for an optional line range (e.g., `10-20` or `15`) or leave it blank to analyze the entire file.
* Applies a green-to-red gradient by commit frequency.
* Adds suffix like `⟶ 5x` indicating 5 commits touched that line.

### ❌ Clear overlays

```elisp
M-x git-churn-clear-overlays
```

* Removes all overlays created by `git-churn`.

## 📁 How It Works

Internally:

* Runs `git log -L <line>,<line>:<file>` per line.
* Counts how many commits changed each line.
* Scores churn from 0.0 (lowest) to 1.0 (highest).
* Displays:
  * Heatmap background color
  * Inline count annotation: `⟶ <n>x`

## ✅ Requirements

* Emacs 25.1 or later
* Git must be installed and available in PATH
* File must belong to a Git repository
