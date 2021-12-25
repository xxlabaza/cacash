function __log () {
  local datestring=`date +'%Y-%m-%d %H:%M:%S'`
  local message="[${datestring}] ${1}: ${2}"
  # printf "${message}\n" | fold -w80 -s >&2
  printf "${message}\n"
}
function info () {
  __log " INFO" "${1}"
}
function warn () {
  __log " WARN" "${1}"
}
function error () {
  __log "ERROR" "${1}" >&2
}
