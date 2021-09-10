#!/bin/bash

declare -a PAGERS=(
    "less"
    "more"
    "cat"
)

declare -a CATS=(
    "bat"
    "cat"
)

set_by_preference() {
    # exports a value to the env variable named in $1 after checking that it
    # corresponds to a valid command
    # Params: 
    #   Name of env variable to set
    #   A list of possible values, ordered by priority.  The first one which
    #   passes validation will be exported
    local -n varname="$1"
    while [ $# -gt 0 ]; do
        command -v "$1" >/dev/null 2>&1 && {
            export varname="$1"; return 0
        } || shift
    done
    echo "${!varname} not set: Failed to find any executables." >&2
    return -1
}

{
    set_by_preference PAGER "${PAGERS[@]}"
    set_by_preference CAT "${CATS[@]}"
} >/dev/null
