{
  if ($0 ~ /^source /) {
    sub(/\$\{SCRIPT_DIR\}/, SCRIPT_ROOT_DIR)
    command = sprintf("awk -f %s/.cacash/src/comments_remover.awk ", SCRIPT_ROOT_DIR)
    system(command substr($0, 8))
  } else if ($0 !~ /^\s*#:doc:/) {
    print $0
  }
}
