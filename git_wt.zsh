git_wt() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Not inside a git repository."
    return 1
  fi

  REPO_NAME=$(basename "$(pwd)")
  CURRENT_BRANCH=$(git branch --show-current)

  # Helper: get worktree path for branch
  get_worktree_path_for_branch() {
    git worktree list --porcelain | awk -v branch="$1" '
      $1=="worktree" { path=$2 }
      $1=="branch" && $2 ~ branch"$" { print path }
    '
  }

  # Helper: open VS Code if available
  open_editor() {
    if command -v code >/dev/null 2>&1; then
      code -r .
    fi
  }

  echo
  echo "📦 $REPO_NAME  |  🌿 $CURRENT_BRANCH"
  echo

  OPTION=$(printf "%s\n" \
    "Open or Jump to branch worktree" \
    "Create new branch from base branch" \
    "Jump to existing worktree" \
    "Delete worktree" \
    "Exit" | \
    fzf --height=50% --border --prompt="Select option > ")

  case "$OPTION" in

  # ---------------------------------------------------------
  # OPEN OR AUTO-JUMP
  # ---------------------------------------------------------
  "Open or Jump to branch worktree")

    TARGET_BRANCH=$(git branch --format="%(refname:short)" | \
      fzf --height=60% --border \
          --prompt="Select branch > " \
          --preview="git log --oneline --graph --decorate --color=always {} | head -20")

    [[ -z "$TARGET_BRANCH" ]] && return

    EXISTING_PATH=$(get_worktree_path_for_branch "$TARGET_BRANCH")

    if [[ -n "$EXISTING_PATH" ]]; then
      echo "🔁 Worktree already exists at $EXISTING_PATH"
      cd "$EXISTING_PATH" || return
      open_editor
      return
    fi

    DEFAULT_DIR="../${REPO_NAME}-${TARGET_BRANCH}"
    read "TARGET_DIR?📁 Directory [$DEFAULT_DIR]: "
    TARGET_DIR=${TARGET_DIR:-$DEFAULT_DIR}

    git worktree add "$TARGET_DIR" "$TARGET_BRANCH" || return

    echo "🚀 Switching to $TARGET_DIR"
    cd "$TARGET_DIR" || return
    open_editor
    ;;

  # ---------------------------------------------------------
  # CREATE NEW BRANCH
  # ---------------------------------------------------------
  "Create new branch from base branch")

    BASE_BRANCH=$(git branch --format="%(refname:short)" | \
      fzf --height=60% --border \
          --prompt="Select base branch > " \
          --preview="git log --oneline --graph --decorate --color=always {} | head -20")

    [[ -z "$BASE_BRANCH" ]] && return

    read "NEW_BRANCH?🆕 New branch name: "
    [[ -z "$NEW_BRANCH" ]] && return

    if git show-ref --verify --quiet refs/heads/$NEW_BRANCH; then
      EXISTING_PATH=$(get_worktree_path_for_branch "$NEW_BRANCH")
      if [[ -n "$EXISTING_PATH" ]]; then
        echo "🔁 Branch already has worktree at $EXISTING_PATH"
        cd "$EXISTING_PATH" || return
        open_editor
        return
      fi
    fi

    DEFAULT_DIR="../${REPO_NAME}-${NEW_BRANCH}"
    read "TARGET_DIR?📁 Directory [$DEFAULT_DIR]: "
    TARGET_DIR=${TARGET_DIR:-$DEFAULT_DIR}

    git worktree add -b "$NEW_BRANCH" "$TARGET_DIR" "$BASE_BRANCH" || return

    echo "🚀 Switching to $TARGET_DIR"
    cd "$TARGET_DIR" || return
    open_editor
    ;;

  # ---------------------------------------------------------
  # JUMP TO WORKTREE
  # ---------------------------------------------------------
  "Jump to existing worktree")

    TARGET_DIR=$(git worktree list --porcelain | \
      awk '/worktree/ {print $2}' | \
      fzf --height=50% --border \
          --prompt="Select worktree > " \
          --preview="git -C {} status")

    [[ -z "$TARGET_DIR" ]] && return

    cd "$TARGET_DIR" || return
    open_editor
    ;;

  # ---------------------------------------------------------
  # DELETE WORKTREE
  # ---------------------------------------------------------
  "Delete worktree")

    CURRENT_WT=$(git rev-parse --show-toplevel)

    TARGET_DIR=$(git worktree list --porcelain | \
      awk '/^worktree / {print $2}' | \
      grep -Fxv "$CURRENT_WT" | \
      fzf --height=50% --border \
          --prompt="Delete worktree > " \
          --preview="git -C {} status")

    [[ -z "$TARGET_DIR" ]] && return

    read "CONFIRM?⚠️  Delete $TARGET_DIR ? (y/N): "
    [[ "$CONFIRM" != "y" ]] && return

    git worktree remove "$TARGET_DIR" || return
    echo "🗑 Deleted $TARGET_DIR"
    ;;

  *)
    return
    ;;
  esac
}
