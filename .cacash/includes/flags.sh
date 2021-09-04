set -o errexit   # exit if any command has a non-zero exit code
set -o nounset   # exit if we reference an undefined variable
set -o pipefail  # if any command in a pipeline fails, the whole pipeline fails
