# Git Remote Branch Cleaner Script

This utility script fetches the latest remote updates and generates a scannable table of all remote branches. It analyzes whether branches have been merged into a target branch (defaults to `main`), identifies if they contain unmerged commits, and tracks who last updated them. It also includes filters and an interactive mode to delete remote and local branches step-by-step.

---

## Features

* **Detailed Overview:** Displays `Last commit author` (latest commit author), `Branch Name`, `Merged status`, `Has Unmerged Commits` (with commit counts), and `Last Updated` date.
* **Smart Filtering:** Filter branches by **Creator** (`-c`), **Merged status** (`-m yes/no`), or **Unmerged commits** (`-u yes/no`).
* **Target Branch Selection:** Compare merge statuses against any branch using `-b <branch_name>` (e.g., `-b develop`).
* **Interactive Deletion Mode (`-i`):** Safe, branch-by-branch evaluation with the following options:
  * `y`: Deletes the branch **remotely** only.
  * `Y`: Deletes the branch **both remotely and locally**.
  * `n`: Skips the branch and moves to the next one.

---

## Git Alias Setup

To execute this script from **any repository** on your computer without typing the full directory path, you can map it to a global Git alias. Open your terminal and run the command corresponding to your operating system:

### 🪟 Windows (Using PowerShell)
If your script is saved at `path/to/your/git-branch-clean.sh`, run this command to safely bridge PowerShell with Git Bash without breaking syntax arguments:
```powershell
$FixedCommand = '!f() { "C:/Program Files/Git/bin/sh.exe" path/to/your/git-branch-clean.sh "$@"; }; f'
git config --global alias.clean-branches $FixedCommand
```

_(Note: If Git is installed in a custom directory, update C:/Program Files/Git/bin/sh.exe to your actual path)._

### 🐧 Linux & 🍏 macOS (Using Bash / Zsh)

First, make sure the script file has execution permissions:

```bash
chmod +x /path/to/your/git-clean-branches.sh
```

Then, map the script globally:

```bash
git config --global alias.clean-branches '!f() { /path/to/your/git-clean-branches.sh "$@"; }; f'
```
