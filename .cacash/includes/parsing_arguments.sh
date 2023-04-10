__ALL_ARGUMENTS=()
__ALL_ARGUMENTS_INDEX=0

POSITIONAL_ARGUMENTS=()

function shift_argument () {
  local readonly how_many="${1:-1}"
  __ALL_ARGUMENTS_INDEX=$(( __ALL_ARGUMENTS_INDEX + how_many ))
}
function get_current_argument () {
  echo "${__ALL_ARGUMENTS[__ALL_ARGUMENTS_INDEX]}"
}

# pre-process options to:
# - expand -xyz into -x -y -z
# - expand --longopt=arg into --longopt arg
function __pre_process_options () {
  local readonly arguments=( ${@+"${@}"} )
  local readonly arguments_count=${#arguments[*]}
  local end_of_options_flag=""

  for (( index = 0; index < ${arguments_count}; index += 1 ));
  do
    local readonly argument="${arguments[$index]}"

    case "${end_of_options_flag}${argument}" in
      --)
        __ALL_ARGUMENTS+=( "${argument}" )
        end_of_options_flag="<EOO_FLAG>"
        ;;
      --*=*)
        __ALL_ARGUMENTS+=( "${argument%%=*}" )
        __ALL_ARGUMENTS+=( "${argument#*=}" )
        ;;
      --*)
        __ALL_ARGUMENTS+=( "${argument}" )
        ;;
      -*)
        for i in $( seq 2 ${#argument} );
        do
          __ALL_ARGUMENTS+=( "-${argument:i-1:1}" )
        done
        ;;
      *)
        __ALL_ARGUMENTS+=( "${argument}" )
        ;;
    esac
  done
}

function __parse_arguments () {
  # we need the check below
  local errexit_was_enabled="false"
  if shopt -qo errexit ; then
    errexit_was_enabled="true"
    set +o errexit
  fi

  local readonly arguments_count=${#__ALL_ARGUMENTS[*]}
  local end_of_options_flag=""

  for (( __ALL_ARGUMENTS_INDEX = 0; __ALL_ARGUMENTS_INDEX < ${arguments_count}; __ALL_ARGUMENTS_INDEX += 1 ));
  do
    local readonly argument="${__ALL_ARGUMENTS[$__ALL_ARGUMENTS_INDEX]}"

    if [ "${end_of_options_flag}" = "<EOO_FLAG>" ]; then
      POSITIONAL_ARGUMENTS+=( "${argument}" )
      continue
    fi

    parse_option "${end_of_options_flag}${argument}"
    local readonly return_status=$?
    if [ "${return_status}" == 0 ]; then
      continue
    fi

    case "${argument}" in
      --)
        end_of_options_flag="<EOO_FLAG>"
        ;;
      -*)
        if [ "${return_status}" == 2 ]; then
          POSITIONAL_ARGUMENTS+=( "${argument}" )
        else
          error "unknown argument - '${argument}'"
          usage >&2
          exit 1
        fi
        ;;
      *)
        POSITIONAL_ARGUMENTS+=( "${argument}" )
        ;;
    esac
  done

  if [ "${errexit_was_enabled}" = "true" ]; then
    set -o errexit
  fi
}

__pre_process_options ${@+"${@}"}
__parse_arguments

unset __ALL_ARGUMENTS
unset __ALL_ARGUMENTS_INDEX
