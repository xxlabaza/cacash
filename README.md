# CaCaSH

CacoCalabash, or simply `CaCaSH` - is a shell scripting templater that aims to help avoid widespread mistakes and increase your shell scripts' robustness, maintainability, and readability.

## Contents

- [Quick Start](#quick-start)
- [Template Description](#template-description)
  - [Override Functions](#override-functions)
    - [usage](#usage)
    - [parse_option](#parse_option)
    - [main](#main)
    - [finalize](#finalize)
  - [Features](#features)
    - [Flags](#flags)
    - [Logging](#logging)
- [Best Practices](#best-practices)
  - [General](#general)
  - [Variables](#variables)
  - [Substitution](#substitution)
  - [Output and Redirection](#output-and-redirection)
  - [Functions](#functions)
  - [Cleanup Code](#cleanup-code)
  - [Writing Robust Scripts And Debugging](#writing-robust-scripts-and-debugging)

## Quick Start

Install the project:

```bash
$> git clone https://github.com/xxlabaza/cacash
$> cd cacash
```

Create a new blank shell script file from a template:

```bash
$> ./caca.sh new
[2021-08-23 01:25:56]  INFO: created a new script ./source.sh
```

Modify the `./source.sh` file:

**source.sh:**
```bash
...
function main () {
  info "Hello world!"
}
...
```

> **NOTE:** don't worry, all `#:doc:` comments will be removed automatically after building the script.

Build the final version:

```bash
$> ./caca.sh build
[2021-08-23 01:26:02]  INFO: built the script ./target.sh
```

Enjoy your creature:

```bash
$> ./target.sh
[2021-08-23 01:26:09]  INFO: Hello world!
```

## Template Description

There's all you want (and even you wouldn't) to know about the templates which the `CaCaSH` templater provides.

### Override Functions

In this section, we're going to look at which parts of the new templated script you should override and implement.

#### usage

The defined "usage" function at the top of the template follow the two purposes:

1. force you to write documentation for your shell script, so in case of an invalid parsed argument or a help call, a user can get a script description and don't disturb you and your troubleshooter in Slack;

2. anyone who reads your script can get at least a minimal view of what's going on here at the beginning of your file.

When you create a new script from a template, the function looks like this:

```bash
function usage () {
  cat << USAGEOUT

Usage: ${SCRIPT_NAME} [OPTIONS] [--] [POSITIONAL_ARGUMENTS]

OPTIONS:
  -h,--help            show this help message and exit
  -v,--verbose         increase the verbosity of the bash script

USAGEOUT
}
```

A content example for such function body is below:

```bash
function usage () {
  cat << USAGEOUT

Usage: ${SCRIPT_NAME} [OPTIONS] [--] [POSITIONAL_ARGUMENTS]

OPTIONS:
  -h,--help            show this help message and exit
  -v,--verbose         increase the verbosity of the bash script
  -b,--builder <arg>   the id of the build strategy to use
  -ff,--fail-fast      stop at first failure
  -l,--log-file <arg>  log file where all output will go

POSITIONAL_ARGUMENTS:
  The files need to process and build.

EXAMPLES:
  - Print this help:
    ${SCRIPT_NAME} --help

  - Process and build a file, save the logs in a separate file:
    ${SCRIPT_NAME} --log-file=out.log --builder=full <file[s]>

USAGEOUT
}
```

#### parse_option

In most non-trivial shell scripts, you would like to parse users' arguments, options, and flags. The predefined "parse_option" function may help you with that.

At the bottom of a shell script template, you have a line like this:

```bash
source "${SCRIPT_DIR}/.cacash/includes/parsing_arguments.sh"
```

It includes simple arguments parsing functionality to your script. During its work, it calls that method - "parse_option", like asking a programmer:  "How to understand that option?". And a programmer should answer or get an "unknown argument" error in the output instead.

After a script is created from a template, the function definition looks like this:

```bash
function parse_option () {
  local readonly option="${1}"
  case "${option}" in
    -h|--help)
      usage
      exit 0
      ;;
    -*|*)
      return 1 # unknown option
      ;;
  esac
  return 0
}
```

> **NOTE:** if an option was normally parsed, the function **must** return 0, otherwise (e.g., in a case when the option is unknown), it **must** return 1. So, the block below **must** always be present in your function implementation:
> ```bash
> -*|*)
>   return 1 # unknown option
>   ;;
> ```

The positional arguments (the arguments without any flag before them) parses to the the `POSITIONAL_ARGUMENTS` global variable, and **also** may be accessible from the **main** function as an arguments array:

```bash
function main () {
  info "POSITIONAL_ARGUMENTS=${POSITIONAL_ARGUMENTS[*]}"
  local args=( "${@}" )
  info "the positional arguments are: ${args[*]}"
}
```

Let's explain how to use the **parse_option** function in the example below:

```bash
DETACHED="false"
USERNAME=""
VERBOSITY_LEVEL=0
FILE_NAMES_ARRAY=()
function parse_option () {
  local readonly option="${1}"
  case "${option}" in
    -h|--help)
      usage
      exit 0
      ;;
    -d|--detach)
      DETACHED="true"
      ;;
    -u|--username)
      shift_argument
      USERNAME=$( get_current_argument )
      ;;
    -v|--verbose)
      VERBOSITY_LEVEL=$(( VERBOSITY_LEVEL + 1 ))
      ;;
    -f|--file-name)
      shift_argument
      FILE_NAMES_ARRAY+=( $( get_current_argument ) )
      ;;
    -*|*)
      return 1 # unknown option
      ;;
  esac
  return 0
}
```

We've defined several options in the function above:

- **DETACHED** - a simple flag, which (in the example above) has value `false` by default, but change it to `true` if you set an appropriate flag in your CLI;

- **USERNAME** - an ordinary key-value option. You can set it like this `--username artem` or like this `--username=artem`;

- **VERBOSITY_LEVEL** - an example of how to make an incremental (stackable) flag. The more times you specify it in the arguments for your script, the more **VERBOSITY_LEVEL** will be. There are two ways how to use it in your CLI: you can set it like this - `--verbose --verbose` or like this - `-vv`, both variants will get value **2** for the **VERBOSITY_LEVEL**;

- **FILE_NAMES_ARRAY** - an array of all passed values. You may set the values like this `-f file1 --file-name file2 --file-name=file3` and get the array `["file1", "file2", "file3"]`.

So, if we run our hypothetical script with the following arguments:

```bash
$> ./popa.sh \
    --detach \
    --username="Hello Kitty" \
    -vvv \
    -f file1 --file-name file2 --file-name=file3
```

We get the next global variables values:

|       variable       |            value              |
|---------------------:|:------------------------------|
|         **DETACHED** | `true`                        |
|         **USERNAME** | `Hello Kitty`                 |
|  **VERBOSITY_LEVEL** | `3`                           |
| **FILE_NAMES_ARRAY** | `["file1", "file2", "file3"]` |

If you pass an unknown option here, you get an error like the one below:

```
$> ./popa.sh -j
[2021-08-23 00:11:42] ERROR: Unknown argument - '-j'
...
```

#### main

The **main** function is an entry point of your script and it looks like this:

```bash
function main () {
  # TODO: make something awesome
}
```

The arguments are already parsed at this point: the options and flags are available via the global variables, which you defined, and the positional arguments you can reach in two ways:

- They are available via a global variable named **POSITIONAL_ARGUMENTS**;

- Or you can easily get them as passed arguments to the **main** function.

A typical usage example is below.

**popa.sh:**

```bash
USERNAME=""
function parse_option () {
  local readonly option="${1}"
  case "${option}" in
    -u|--username)
      shift_argument
      USERNAME=$( get_current_argument )
      ;;
    -*|*)
      return -1 # unknown option
      ;;
  esac
  return 0
}
function main () {
  info "USERNAME=${USERNAME}"
  info "POSITIONAL_ARGUMENTS=${POSITIONAL_ARGUMENTS[*]}"
  local args=( "${@}" )
  info "args=${args[*]}"
}
```

**Invoke the script**

```bash
$> ./popa.sh \
    -u artem \
    one \
    -- \
    two \
    three

[2021-08-22 21:02:23]  INFO: USERNAME=artem
[2021-08-22 21:02:23]  INFO: POSITIONAL_ARGUMENTS=one two three
[2021-08-22 21:02:23]  INFO: args=one two three
```

As you can see - the global variable **POSITIONAL_ARGUMENTS** and passed
array to the main function have the same values.

#### finalize

We have all been there, you write a shell script that creates some temporary files and/or directories for processing some information. You complete your script with some basic testing and all is well. You set your cron job to run the script every day at noon. Six days later you realize that the script has been exiting prematurely and leaving a bunch of trash files in the file system. Or worse, potentially sensitive data is left unprotected.

The above scenario is a bit dramatic, but not completely ridiculous. If you are automating tasks with shell scripts you will eventually run into a premature exit. Either as the result of an error, a change in the environment, or an unanticipated user action. Creating scripts that deal with this scenario is imperative to keeping a clean and secure system.

So, the safer from all your headaches and finalizer of all your dirty stuff is the **finalize** function from a template, which looks like this:

```bash
function finalize () {
  local previous_command_exit_status_code=$?
  # your cleanup code here
  exit ${previous_command_exit_status_code}
}
```

Thet function automatically calls on each **EXIT** or **ERR** signal, so be sure that it always be the last action before any exit result of your script. Just place all cleaning stuff here, and that's all. There's nothing to add more.

### Features

#### Flags

At the bottom of the templated script, you can find a line like this:

```bash
source "${SCRIPT_DIR}/.cacash/includes/flags.sh"
```

That command includes a file with a reasonable set of flags for your future script. In addition, you can add a debug flag under this line, like this:

```bash
source "${SCRIPT_DIR}/.cacash/includes/flags.sh"
set -o xtrace
```

It is helpful at the development stage to see all the commands which your script runs.

**And don't forget to remove the `set -o xtrace` before production!** Nobody likes too many logs on the prod.

#### Logging

The line:

```bash
source "${SCRIPT_DIR}/.cacash/includes/logging.sh"
```

at the bottom of your origin script includes a set of helpful logging functions, like **info**, **warn**, and **error** (prints to the `STDERR`). You can use them like this:

```bash
function main () {
  info "Hello from info"
  warn "Hello from warn"
  error "Hello from error"
}
```

And the out put will be:

```bash
[2021-08-23 01:18:15]  INFO: Hello from info
[2021-08-23 01:18:15]  WARN: Hello from warn
[2021-08-23 01:18:15] ERROR: Hello from error
```

## Best Practices

> **NOTE:** this's an articale adoptation from https://bertvv.github.io/cheat-sheets/Bash.html

### General

- The principles of [Clean Code](https://www.pearson.com/us/higher-education/program/Martin-Clean-Code-A-Handbook-of-Agile-Software-Craftsmanship/PGM63937.html) apply to Bash as well

- Always use long parameter notation when available. This makes the script more readable, especially for lesser known/used commands that you don’t remember all the options for.

```bash
# Avoid:
rm -rf -- "${dir}"

# Good:
rm --recursive --force -- "${dir}"
```

- Don’t use:

```bash
cd "${foo}"
[...]
cd ..
```

but:

```bash
(
  cd "${foo}"
  [...]
)
```

**pushd** and **popd** may also be useful:

```bash
pushd "${foo}"
[...]
popd
```

- Use `nohup foo | cat &` if `foo` must be started from a terminal and run in the background.

### Variables

- Prefer local variables within functions over global variables

- If you need global variables, make them readonly

- Variables should always be referred to in the **${var}** form (as opposed to **$var**).

- Variables should always be quoted, especially if their value may contain a whitespace or separator character: **"${var}"**

- Capitalization:
Environment (exported) variables: **${ALL_CAPS}**
Local variables: **${lower_case}**

- Positional parameters of the script should be checked, those of functions should not

- Some loops happen in subprocesses, so don’t be surprised when setting variabless does nothing after them. Use stdout and **grep**ing to communicate status.

### Substitution

- Always use **$( cmd )** for command substitution (as opposed to backquotes)

- Prepend a command with **\** to override alias/builtin lookup. E.g.:

```bash
$> \time bash -c "dnf list installed | wc -l"
  5466
  1.32user 0.12system 0:01.45elapsed 99%CPU (0avgtext+0avgdata 97596maxresident)k
  0inputs+136outputs (0major+37743minor)pagefaults 0swaps
```

### Output and redirection

- [For various reasons](https://www.in-ulm.de/~mascheck/various/echo+printf/), **printf** is preferable to **echo**. **printf** gives more control over the output, it’s more portable and its behaviour is defined better.

- Print error messages on stderr. E.g., I use the following function:

```bash
error() {
  printf "${red}!!! %s${reset}\\n" "${*}" 1>&2
}
```

- Name heredoc tags with what they’re part of, like:

```bash
cat <<HELPMSG
usage $0 [OPTION]... [ARGUMENT]...

HELPMSG
```

- Single-quote heredocs leading tag to prevent interpolation of text between them.

```bash
cat <<'MSG'
[...]
MSG
```

- When combining a **sudo** command with redirection, it’s important to realize that the root permissions only apply to the command, not to the part after the redirection operator. An example where a script needs to write to a file that’s only writeable as root:

```bash
# this won't work:
sudo printf "..." > /root/some_file

# this will:
printf "..." | sudo tee /root/some_file > /dev/null
```

### Functions

Bash can be hard to read and interpret. Using functions can greatly improve readability. Principles from Clean Code apply here.

- Apply the [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle): a function does one thing.

- [Don’t mix levels of abstraction](http://sivalabs.in/clean-code-dont-mix-different-levels-of-abstractions/)

- Describe the usage of each function: number of arguments, return value, output

- Declare variables with a meaningful name for positional parameters of functions:

```bash
foo() {
  local first_arg="${1}"
  local second_arg="${2}"
  [...]
}
```

- Create functions with a meaningful name for complex tests:

```bash
# Don't do this
if [ "$#" -ge "1" ] && [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = "-?" ]; then
  usage
  exit 0
fi

# Do this
help_wanted() {
  [ "$#" -ge "1" ] && [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = "-?" ]
}

if help_wanted "$@"; then
  usage
  exit 0
fi
```

### Cleanup code

An idiom for tasks that need to be done before the script ends (e.g. removing temporary files, etc.). The exit status of the script is the status of the last statement before the **finish** function.

```bash
finish() {
  result=$?
  # Your cleanup code here
  exit ${result}
}
trap finish EXIT ERR
```

Source: Aaron Maxwell, [How “Exit Traps” can make your Bash scripts way more robust and reliable](http://redsymbol.net/articles/bash-exit-traps/).

### Writing robust scripts and debugging

Bash is not very easy to debug. There’s no built-in debugger like you have with other programming languages. By default, undefined variables are interpreted as empty strings, which can cause problems further down the line. A few tips that may help:

- Always check for syntax errors by running the script with `bash -n myscript.sh`

- Use [ShellCheck](https://www.shellcheck.net/) and fix all warnings. This is a static code analyzer that can find a lot of common bugs in shell scripts. Integrate ShellCheck in your text editor (e.g. Syntastic plugin in Vim)

- Abort the script on errors and undbound variables. Put the following code at the beginning of each script.

```bash
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
```

A shorter version is shown below, but writing it out makes the script more readable.

```bash
set -euo pipefail
```

- Use Bash’s debug output feature. This will print each statement after applying all forms of substitution (parameter/command substitution, brace expansion, globbing, etc.)

Run the script with `bash -x myscript.sh`

Put `set -x` at the top of the script

If you only want debug output in a specific section of the script, put `set -x` before and `set +x` after the section.

- Write lots of log messages to stdout or stderr so it’s easier to drill down to what part of the script contains problematic code
