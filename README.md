# git-utils

Small zsh helpers for common Git workflows:

- switch Git identity between work and personal
- create, apply, and share staged patches
- manage Git worktrees with `fzf`
- inspect rough contribution percentages
- undo the last commit while keeping changes staged

## Files

- `git_config.zsh` - sets local Git `user.name` and `user.email`
- `git_patch.zsh` - creates a patch from staged changes or applies an existing patch
- `git_wt.zsh` - interactive Git worktree helper
- `git_contrib.zsh` - shows contribution percentages by author from commit history
- `undo_last_commit.zsh` - soft-resets `HEAD~1`

## Setup

Source the files from your shell config (add this in .zshrc after adding the git-util folder under the $HOME path):
   
```sh
for file in $HOME/git-util/*.zsh(N); do
  source "$file"
done

```
## Requirements

- `zsh`
- `git`
- `fzf` for `git_wt`
- `code` CLI in `PATH` if you want `git_wt` to reopen VS Code automatically

## Usage

### `git_config`

Sets Git identity in the current repository.

```zsh
git_config           # defaults to work
git_config work
git_config -w
git_config personal
git_config -p
```

Current mappings:

- `work` -> `Sandesh <sandesh.yele@workemail.com>`
- `personal` -> `sandeshyele2000 <sandeshyele@personal.com>`

Note: this runs `git config`, not `git config --global`, so it updates repo-local config when run inside a repository.

### `git_patch`

Creates a patch from staged changes, or applies an existing patch.

```zsh
git_patch
git_patch feature.patch
git_patch --create feature.patch
git_patch --apply feature.patch
git_patch --help
```

Behavior:

- creates patches from `git diff --cached --binary`
- writes the patch into the current working directory
- if the provided file already exists, it is treated as a patch to apply unless `--create` is used
- applies patches with `git apply --index --binary --whitespace=nowarn`

Typical flow:

```zsh
git add path/to/files
git_patch fix-login.patch
```

Then elsewhere:

```zsh
git_patch fix-login.patch
```

### `git_wt`

Interactive helper for Git worktrees.

```zsh
git_wt
```

Available actions:

- open or jump to an existing branch worktree
- create a new branch from a selected base branch in a new worktree
- jump to any existing worktree
- delete an existing worktree

Notes:

- branch and worktree selection uses `fzf`
- when the `code` command is available, the selected worktree is opened in VS Code
- new worktrees default to directories like `../<repo>-<branch>`

### `git_contrib`

Shows a rough percentage breakdown of added lines per author across repo history.

```zsh
git_contrib
```

Details:

- excludes `node_modules`, `vendor`, `Pods`, `dist`, `build`, and `.git`
- ignores merge commits
- uses added lines only from `git log --numstat`
- groups authors under `1.5%` into `Others`

This is directional, not precise ownership data. Renames, deletions, large generated files, and historical churn can skew the numbers.

### `undo_last_commit`

Undoes the last commit but keeps the changes staged.

```zsh
undo_last_commit
```

Equivalent command:

```zsh
git reset --soft HEAD~1
```

Use this when the commit is wrong but the staged content is still what you want to recommit.

## Suggested aliases

If you want shorter names:

```zsh
alias gwt='git_wt'
alias gpach='git_patch'
alias gcontrib='git_contrib'
alias gundo='undo_last_commit'
```

## Caveats

- `git_patch` only creates patches from staged changes, not unstaged work
- `git_wt` depends on `fzf`; without it the function is not usable
- `undo_last_commit` assumes `HEAD~1` exists
- `git_config` currently hardcodes personal and work identities
