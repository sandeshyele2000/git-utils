git_config() {
  case "$1" in
    personal|-p)
      git config user.name "sandeshyele2000"
      git config user.email "sandeshyele2000@gmail.com"
      echo "✅ Git config set to PERSONAL"
      ;;
    ""|work|-w)
      git config user.name "Sandesh"
      git config user.email "sandesh.yele@getvymo.com"
      echo "✅ Git config set to WORK"
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage:"
      echo "  set_git_config          (defaults to work)"
      echo "  set_git_config work|-w"
      echo "  set_git_config personal|-p"
      ;;
  esac
}