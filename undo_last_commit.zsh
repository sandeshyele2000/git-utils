undo_last_commit() {
  git reset --soft HEAD~1
  local commitid=$(git rev-parse HEAD)
  echo "✅ Last commit undone ($commitid)"
}