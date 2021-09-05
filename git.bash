#!/bin/bash
# Functions to automate git repo management

_commit_files() (
    # Commits changes to passed files
    # Params:
    #   - root dir of git repo (i.e., .git/..)
    #   - array ref populated with files to commit
    #   - commit message (remainder of pos. params)
    cd "$1" && shift || return 1
    local -n ref="$1" && shift || return 2
    local msg="$*"

    git add "${ref[@]}" || return 3
    git commit -m "$msg"
    return $?
)
