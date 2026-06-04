git_patch() {
  local mode=""
  local arg1="$1"

  case "$arg1" in
    -h|--help)
      echo "Usage:"
      echo "  git_patch                 # create patch from staged changes"
      echo "  git_patch <name>.patch    # create patch with this name (if it doesn't exist)"
      echo "  git_patch <path>.patch    # apply patch (if file exists)"
      echo "  git_patch --create <name> # force create, even if file exists"
      echo "  git_patch --apply <path>  # force apply"
      echo
      echo "Creates a patch from *staged* changes and writes it to the current directory."
      echo "If the given file already exists, applies it with 'git apply --index'."
      return 0
      ;;
    --create|-c)
      mode="create"
      shift
      ;;
    --apply|-a)
      mode="apply"
      shift
      ;;
  esac

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not inside a git repository."
    return 1
  fi

  # If the user gave an existing file, treat it as a patch to apply (unless forced create).
  if [[ "$mode" == "apply" || ( -z "$mode" && -n "$1" && -f "$1" ) ]]; then
    local patch_path="$1"
    if [[ -z "$patch_path" ]]; then
      echo "❌ Missing patch file path."
      return 1
    fi
    if [[ ! -f "$patch_path" ]]; then
      echo "❌ Patch file not found: $patch_path"
      return 1
    fi
    if ! git apply --index --binary --whitespace=nowarn -- "$patch_path"; then
      echo "❌ Failed to apply patch: $patch_path"
      echo "   Tip: ensure your working tree matches the patch's base, or try from the repo root."
      return 1
    fi
    echo "✅ Patch applied (and staged): $patch_path"
    return 0
  fi

  if git diff --cached --quiet; then
    echo "ℹ️  No staged changes to create a patch."
    return 1
  fi

  local default_name="staged-$(date +%Y%m%d-%H%M%S).patch"
  local patch_name
  if [[ -n "$1" ]]; then
    patch_name="$1"
  else
    read "patch_name?📝 Patch file name [$default_name]: "
    patch_name=${patch_name:-$default_name}
  fi

  # Always store the patch in the current directory (where the command is run).
  patch_name=$(basename -- "$patch_name")

  if [[ -z "$patch_name" || "$patch_name" == "/" || "$patch_name" == "." ]]; then
    echo "❌ Invalid patch file name."
    return 1
  fi

  if [[ "$patch_name" != *.* ]]; then
    patch_name="${patch_name}.patch"
  fi

  local patch_path="${PWD}/${patch_name}"

  if [[ -e "$patch_path" ]]; then
    local confirm
    read "confirm?⚠️  '$patch_name' exists. Overwrite? (y/N): "
    [[ "$confirm" != "y" ]] && return 1
  fi

  if ! git diff --cached --binary > "$patch_path"; then
    echo "❌ Failed to create patch."
    return 1
  fi

  echo "✅ Patch saved to: $patch_path"
}
