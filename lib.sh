#!/bin/bash
# Functions for use by other shell scripts

# Global vars useful for debugging and testing
declare -A WARNINGS=( )

_warn() {
    # Preserve information about previous call
    local -i status=$?
    local caller="${BASH_SOURCE[0]}: ${FUNCNAME[1]} @${BASH_LINENO[0]}"
    WARNINGS["$caller"]="$*"
    echo "WARNING: ${caller}: $*" >&2
    return $status
}

_print_array() {
    local -i quoted=1
    if [ "$1" = "-Q" ]; then
        let quoted=0
        shift
    fi
    # Choose a weird name to avoid circular references
    local -n _arr="$1" && shift || return -1
    local title="$*"
    local template='%s'
    if [ $quoted -ne 0 ]; then
        template="\"${template}\""
    fi
    template="${template}\n"
    if [ -n "$title" ]; then
        echo "${title}:"
        template="  - ${template}"
    fi
    printf "$template" "${_arr[@]}"
}

_kill_jobs() {
    # Kills all child processes of the current shell
    kill $(ps -o pid= --ppid $$)
} 2>/dev/null

_die() {
    # Exits after printing any messages passed by the user
    # Each argument is printed on a separate line to stderr
    # Exit code can be specified by passing the flag -i with an argument
    local -i code=1
    if [ "$1" = "-e" ]; then
        code="$2" && shift 2 || exit 255
    fi
    printf '%s\n' "$@"
    _kill_jobs
    exit $code
} >&2

_debug() {
    # Prints passed messages, indented and prefixed by a debug header with
    # callstack information
    # If an argument is the name of a variable, that variable will be printed
    # via `typeset -p`
    local status=$?
    if [ -n "$DEBUG" ]; then
        echo "DEBUG: ${BASH_SOURCE[0]}: ${FUNCNAME[1]} @${BASH_LINENO[0]}"
        local -n ref
        for arg in "$@"; do
            typeset -p "$arg" || echo "$arg"
        done | sed 's/^/	/'
        for ref in "$@"; do
            typeset -p "${!ref}"
        done | sed 's/^/	/'
    fi
    return $status
} >&2 2>/dev/null

_parse_opts() {
    # Conveniece wrapper around a standard getopts loop
    # Params:
    #   - Name of an associative array variable containing opts (format below)
    #   - Name of an associative array variable containing flags (format below)
    #   - Name of an array in which to store positional params
    #   - All other params are interpreted as arguments to be parsed
    # Format of opts associative array:
    #   ( [key]=val ), where "key" is the option name (e.g., "-m")
    # Format of flags associative array:
    #   ( [flag]= ), where "flagN" is the nth flag name (e.g., "-v").  After
    #   parsing, the value corresponding to "flag" will be the number of times
    #   the flag was passed.
    # TODO: Implement version without any passed arrays (i.e., don't restrict
    # options at all, just interpret all parameters prefixed with '-' as opts)
    local -n parsed="$1" && shift
    local optspec=":$(awk -v OFS='' '{$1=$1; print;}' <<<"${!parsed[@]}")"

    # Initialize counters (flags)
    for key in "${!parsed[@]}"; do
        if ! [ "${key: -1}" = ":" ]; then
            let parsed[$key]=0
        fi
    done
    _debug parsed optspec

    # Use getopts to assign opts and increment counters
    while getopts "$optspec" opt; do
        if [ -n "${parsed[${opt}:]+x}" ]; then
            parsed[${opt}:]="$OPTARG"
        elif [ -n "${parsed[${opt}]+x}" ]; then
            let parsed[${opt}]+=1
        else
            _debug "Unknown option encountered: '$opt'"
            return 1
        fi
    done
    _debug parsed optspec OPTIND
    shift $(( OPTIND - 1 )) && OPTIND=1

    # Assign positional parameters
    for (( indx=1; indx <= $#; ++indx )); do
        parsed[$indx]="${!indx}"
    done
    parsed["#"]=$#
    parsed["@"]="$@"
    _debug parsed optspec
    return $?
}

_commit_changes() {
    # Commmits changes to a list of files and/or directories
    # Assumptions: 
    #   - All args are files or directories located in the same repo
    #   - Args are **absolute** paths
    #   - Symlinks are not followed
    # The commit message can be specified as an argument to the -m flag. Default
    # is "Auto-generated commit message for script '${caller}'", followed by a
    # summary of changes made and errors encountered.
    # By default, the commit message will be opened in an editor for inspection
    # and modification; this behavior can be suppressed with the -f flag.
    local caller="$(basename ${BASH_SOURCE[1]})"
    local -A opts=( [m:]= [f]= )
    local -a changed=( )
    local -a unchanged=( )
    local -A errors=( )
    local file=

    _print_changed() {
        echo "The following files or directories were added or edited:"
		printf '%s\n' "${changed[@]}" | sed 's/^/	/'
        if [ ${#unchanged[@]} -gt 0 ]; then
            printf '%s\n' "" "The following files or directories were unchanged:"
            printf '%s\n' "${unchanged[@]}" | sed 's/^/	/'
        fi
    }

    _print_errors() {
        if [ ${#errors[@]} -gt 0 ]; then
            echo "The following errors occurred:"
            paste <(printf '%s\n' "${!errors[@]}" | fold -w 32) \
                <(printf '%s\n' "${errors[@]}" | fold -w 36) |
                sed 's/^/    /'
        fi
    }

    _parse_opts opts "$@"
    for (( i=1; i<=opts[#]; ++i )); do
        file="${opts[$i]}"
        _debug "Attempting to add file '$file' to git repo"
        cd "$(dirname "$file")" && git status >/dev/null 2>&1 ||
            errors["$file"]="Can't find parent git repository"
        local status="$(git status -s "$file" | awk '{print $1;}')"
        if [ -n "$status" ]; then
            git add "$file" 2>/dev/null && changed+=( "$file" ) ||
                errors["$file"]="Failed to add to repository index"
        else
            unchanged+=( "$file" )
        fi
    done
    _debug "Committing changes to `pwd`"
    local summary="$(fold -s -w 72 <<<\
        "Auto-generated commit message for script '${caller}'")"
    read -r -d '' default_msg <<-MSG
        ${summary}

		`_print_changed`

		`_print_errors`
		MSG
    local msg="${opts[m:]:-$default_msg}"
    _debug msg default_msg
    if [ ${#changed[@]} -gt 0 ]; then
        if [ "${opts[f]}" -gt 0 ]; then
            git commit -m "$msg"
        else
            git commit -t <(echo "$msg")
        fi || errors+=( "Unable to commit changes" )
    fi
    _print_changed
    _print_errors >&2
    return ${#errors[@]}
}


_commit_installed() (
    cd "$(dirname "$INSTALL_LOG")"
    git status 2>&1 >/dev/null ||
        _die -e 2 "`pwd` does not appear to be a git repository"
    git add . && git commit -m "$*"
    return $?
)

if [ -n "${TEST+x}" ]; then
    # Do something...do I even need this?
    eval "$@"
fi

_get_kv_pairs() {
    # Prints a list of key-value pairs suitable for use in (e.g.) PAM modules
    local -n ref="$1"
    for key in "${!ref[@]}"; do
        printf '%s=%s ' "$key" "${ref[$key]}"
    done | sed 's/[[:space:]]*$//'
}

_yesno() {
    read -s -n 1
    while :; do
        case "$REPLY" in
            y|Y)
                return 0
                ;;
            n|N)
                return 1
                ;;
            *)
                echo "Please press 'y/Y' for 'yes' or 'n/N' for 'no'."
                ;;
        esac
    done
}

_choose() {
    local -n ref="$1" && shift || return -1
    while :; do
        echo "$*" >&2
        select opt in "${ref[@]}"; do
            for x in "${ref[@]}"; do
                [ "$x" == "$opt" ] && echo "$opt" && return 0
            done
            echo "Invalid choice." >&2
        done
    done
    return $?
}
