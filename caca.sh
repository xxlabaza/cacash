#!/usr/bin/env sh

SOURCE_FILE_NAME="source.sh"
TARGET_FILE_NAME="target.sh"

#:doc: Place the script usage, options description, and examples
#:doc: in the function below. Use the provided sample as a
#:doc: template and a good starting point.
function usage () {
  cat << USAGEOUT

CaCaSH - is a shell scripting templater that aims to avoid widespread mistakes
and increase your shell scripts' robustness, maintainability, and readability.

Usage: ${SCRIPT_NAME} [OPTIONS] [--] [COMMANDS]

OPTIONS:
  -h,--help             show this help message and exit
  -v,--verbose          increase the verbosity of the bash script
  -f,--forced           forces the questions to "yes", during the commands run

COMMANDS
  new [shell_type]      creates a new '${SOURCE_FILE_NAME}' file from a template
                        defined by "shell_type". The supported values for the
                        "shell_type" are "sh" and "bash". Default is "sh".

  build                 build a '${TARGET_FILE_NAME}' file from the '${SOURCE_FILE_NAME}'

USAGEOUT
}

#:doc: The arguments parsers (if you didn't remove its inclusion below) uses
#:doc: that function to recognize the passed flags and options to your script.
#:doc: Feel free to add more options here (see the README.md for examples).
FORCE_FLAG="false"
function parse_option () {
  local readonly option="${1}"
  case "${option}" in
    -h|--help)
      usage
      exit 0
      ;;
    -f|--forced)
      FORCE_FLAG="true"
      ;;
    -*|*)
      return 1 # unknown option
      ;;
  esac
  return 0
}

#:doc: This's an entry point of your program. Place your business-logic
#:doc: (ha-ha! "business" and "logic" in a shell script!) here.
function main () {
  local readonly arguments=( ${@+"${@}"} ) # a hack to use empty arrays with `set -o nounset`
  local readonly arguments_count=${#arguments[*]}

  if [ "${arguments_count}" -eq 0 ]; then
    error "invalid numer of commands"
    usage >&2
    exit 1
  fi

  local readonly command="${arguments[0]}"
  case "${command}" in
    "new")
      process_new "${arguments[@]:1}"
      ;;
    "build")
      process_build
      ;;
    *)
      error "unknown command - ${command}"
      usage >&2
      exit 1
      ;;
  esac
}

function process_new () {
  local readonly arguments=( ${@+"${@}"} ) # a hack to use empty arrays with `set -o nounset`
  local readonly arguments_count=${#arguments[*]}

  if [ "${arguments_count}" -gt 1 ]; then
    error "invalid number of arguments for the 'new' command"
    usage >&2
    exit 1
  fi

  local readonly shell_type="${arguments[0]:-sh}"
  local readonly template="${SCRIPT_DIR}/.cacash/templates/${shell_type}.template"
  if [ ! -f "${template}" ]; then
    error "there is no template for shell - '${shell_type}'"
    exit 1
  fi

  local readonly destination_file="./${SOURCE_FILE_NAME}"
  if [ -f "${destination_file}" ] && [ "${FORCE_FLAG}" = "false" ]; then
    printf "Overwrite script ${destination_file} (y/n)?: "
    read overwrite
    if [ "${overwrite}" = "${overwrite#[Yy]}" ]; then
      exit 0 # answer is 'no'
    fi
  fi

  cp "${template}" "${destination_file}"
  chmod +x "${destination_file}"
  info "created a new script ${destination_file}"
}

function process_build () {
  local readonly arguments=( ${@+"${@}"} ) # a hack to use empty arrays with `set -o nounset`
  local readonly arguments_count=${#arguments[*]}

  if [ "${arguments_count}" -gt 0 ]; then
    error "invalid number of arguments for the 'build' command"
    usage >&2
    exit 1
  fi

  local readonly source_file="./${SOURCE_FILE_NAME}"
  if [ ! -f "${source_file}" ]; then
    error "there is no file ${source_file}"
    exit 1
  fi

  local readonly templater="${SCRIPT_DIR}/.cacash/src/templater.awk"
  local readonly destination_file="./${TARGET_FILE_NAME}"

  awk -f "${templater}" "${source_file}" > "${destination_file}"
  chmod +x "${destination_file}"
  info "built the script ${destination_file}"
}

#:doc: The finalization section of your script. The place for tasks that need
#:doc: to be done before the script ends (e.g. removing temporary files, etc.).
#:doc: The exit status of the script is the status of the last statement before
#:doc: the finalize function.
function finalize () {
  local previous_command_exit_status_code=$?
  # your cleanup code here
  exit ${previous_command_exit_status_code}
}



################################################
# BEWARE: THE CACASH INTERNALS UNDER THIS LINE #
################################################

#:doc: The rest code below - belongs to the CaCaSH internal stuff.
#:doc: You can enable/disable some includes or even try to hack something there,
#:doc: but typically you don't have to touch anything below.

#:doc: Define the "exit trap" for the script. When your script ends with error
#:doc: or success - the function "finalize" always calls at the end of it.
trap finalize EXIT ERR

# Global variables:
#:doc: The default global helper variables for the script.
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly SCRIPT_NAME=$( basename "${0}" )

# Essential flags:
#:doc: This is the set of flags that may help to increase the robustness and
#:doc: strictness of your script.
#:doc: You can also add "set -o xtrace" here to print a trace of the commands.
#:doc: It may help debug the script.
source "${SCRIPT_DIR}/.cacash/includes/flags.sh"
# set -o xtrace

# The logging:
#:doc: The include adds the logging functions like: "info", "warn" and "error".
#:doc: Usage:
#:doc: info "Hello world"
#:doc: Output:
#:doc: [2021-08-22 21:33:13]  INFO: Hello world
source "${SCRIPT_DIR}/.cacash/includes/logging.sh"

# Arguments parsing:
#:doc: Provides the necessary functions for the script's arguments parsing.
#:doc: For example, the options parsing a script creator define above
#:doc: (see the "parse_option" function template), which uses in the arguments
#:doc: parsing process.
source "${SCRIPT_DIR}/.cacash/includes/parsing_arguments.sh"

# Let's start the shell scripting magic!
main ${POSITIONAL_ARGUMENTS[@]+"${POSITIONAL_ARGUMENTS[@]}"}
