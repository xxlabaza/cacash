{
  if ($0 ~ /^source /) {
    sub(/\$\{SCRIPT_DIR\}\//, "")
    system("awk -f .cacash/src/comments_remover.awk " substr($0, 8))
  } else if ($0 !~ /^\s*#:doc:/) {
    print $0
  }
}
