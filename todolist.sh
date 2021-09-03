#!/bin/bash
# Simple function to echo text into a TODO file with a name determined by the
# first positional parameter (e.g., `to watch "Memento"` results in the string
# "- Memento" being appended to the file "towatch.txt" in the designated notes
# dir)

# Library of convenience functions (should be sourced in .bashrc.d)
# source ~/.installed/lib.sh

export NOTES_DIR="${NOTES_DIR:-$HOME/notes}"
export DEFAULT_EXT="txt"
export LIST_PREFIX="to"
export DEFAULT_LIST="${NOTES_DIR}/today.${DEFAULT_EXT}"
export CURRENT_LIST="$DEFAULT_LIST"

if ! [ -d "$NOTES_DIR" ]; then
	echo "WARNING: Directory \$NOTES_DIR='${NOTES_DIR}' does not appear to exist."
fi >&2

_set_current_list() {
    local list="$(awk -v ext="$DEFAULT_EXT" "$(cat <<-AWK
		{
		    ext=\$1 ~ "\\\." ? "" : "." ext
		    pre=\$1 ~ "^${LIST_PREFIX}" ? "" : "${LIST_PREFIX}"
		    printf("%s%s%s", pre, \$0, ext)
		} 
		AWK
    )" <<<"$1")"
    local file="${NOTES_DIR}/${list}"
    if ! [ -e "$file" ]; then
        echo "Create file '${file}'?"
        read -s -n 1
        case "$REPLY" in 
            y|Y)
                touch "$file"
                ;;
            *)
                echo "Aborting!" >&2 && return -1
                ;;
        esac
    fi
    if ! [ -r "$file" ]; then
        echo "Cannot read file for todo list '$list'" >&2
        return -1
    else
        export CURRENT_LIST="$file"
    fi
    return $?
}

agenda() {
    if [ "$1" = "list" ]; then
        shift; local search="$*"
        find "${NOTES_DIR}" \
            -maxdepth 1 \
            -name "${LIST_PREFIX}*${search}*.${DEFAULT_EXT}" \
            -printf "%f\n"
        return $?
    elif [ -z "$1" ]; then
        echo "AGENDA: ${DEFAULT_LIST}"
    else
        _set_current_list "$1"
    fi
    local -i status=$?
    cat "$CURRENT_LIST"
    return $status
}

finish() {
    # Completes item from specified TODO list
    OPTIND=1; while getopts ":l:" opt; do
        case "$opt" in
            l)
                _set_current_list "$OPTARG"
                ;;
            *)
                echo "Unknown option '$OPTARG'" >&2
                return -1
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    sed "/$*/s/^- \[ \]/- \[X\]/" "$CURRENT_LIST" | 
        tee "$CURRENT_LIST"
    cat "$CURRENT_LIST"
    return $?
}

to() { 
    # Adds item to specified TODO list
    _set_current_list "$1" && {
        shift 
        printf -- '- [ ] %s\n' "$@" | tee -a "$CURRENT_LIST"
    } || {
        echo "Could not set todo list to '${verb}'" >&2
        return -1
    }
    return $?
}

todo() {
    # Greps for parameters in TODO files
    local -a grep_flags=( "-i" )
    local -A grep_exprs=( )
    local -i all=0
    local -a files=( "$CURRENT_LIST" )
    OPTIND=1; while getopts ":l:a" opt; do
        case "$opt" in
            l)
                _set_current_list "$OPTARG"
                ;;
            a)
                files=( ${NOTES_DIR}/to*.${DEFAULT_EXT} )
                ;;
            *)
                echo "Unknown option '$OPTARG'" >&2
                return -1
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    grep "$*" "${files[@]}"
    return $?
}

# TODO system

# * Tags
# * Markdown
# * "Terraced" architecture:
#     * Support basic functionality with Bash; add more complex features in Python
# * Topological sorting:
#     * Use to construct agendas, schedules, and reminders
#     * cf. PERT (Program Evaluation and Review Technique)
#     * Critical Path Method (CPM)
# * Hierarchical items:
#     * Dependencies
#     * Categories: Use ':' as token while parsing args
# 
# --------
# 
# # Zettel system
# 
# * Tags
# * UIDs
# * References (?)
# * Pandoc / LaTeX
# * `idea` alias / script
# * Directory-agnostic: should be able to run in any project dir
# * GNU Stow:
#     * Maintain central Zettel repo but symlink to different project dirs
# 
# --------
# 
# # Build / deployment system
# 
# * Auto-generate Makefiles from YAML / Markdown dependency lists
# * Topological sorting: `tsort`
