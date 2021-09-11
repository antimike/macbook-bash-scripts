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
    # TODO: 
    #   - [X] check for null input
    #   - [X] check format of input (i.e., list basename, file basename, full path,
    #       - Added `basename` call
    #   etc.)
    #   - [X] expose option to suppress file creation if not found
    local -i create=1
    case "$1" in
        -q|--quiet) create=0; shift ;;
        "") return -1 ;;        # Empty argument
    esac
    local list="$(awk -v ext="$DEFAULT_EXT" "$(cat <<-AWK
		{
		    ext=\$1 ~ "\\\." ? "" : "." ext
		    pre=\$1 ~ "^${LIST_PREFIX}" ? "" : "${LIST_PREFIX}"
		    printf("%s%s%s", pre, \$0, ext)
		} 
		AWK
    )" <<<"$(basename "$1")")"
    local file="${NOTES_DIR}/${list}"
    if ! [ -e "$file" ]; then
        if [ $create -eq 1 ]; then
            echo "Create file '${file}'?"
            read -s -n 1
            case "$REPLY" in 
                y|Y)
                    touch "$file" ||
                        { echo "Could not touch '${file}'!"; return 1; } >&2
                    ;;
                *)
                    { echo "Aborting!"; return 2; } >&2
                    ;;
            esac
        else
            { echo "File '${file}' not found!"; return 3; } >&2
        fi
    fi
    if ! [ -r "$file" ]; then
        { echo "Cannot read file for todo list '$list'!"; return 4; } >&2
    else
        export CURRENT_LIST="$file"
    fi
    return $?
}

_commit_current_list() {
    git add "$CURRENT_LIST" &&
        git commit $(printf -- '-m "%s"' "$@") ||
        _warn "Failed to commit '${CURRENT_LIST}'"
}

agenda() {
    local list="$1" old_list=
    if [ "$list" = "list" ]; then
        shift; local search="$*"
        find "${NOTES_DIR}" \
            -maxdepth 1 \
            -name "${LIST_PREFIX}*${search}*.${DEFAULT_EXT}" \
            -printf "%f\n"
        return $?
    elif [ -z "$list" ]; then
        list="${DEFAULT_LIST}"
        old_list="$CURRENT_LIST"
    fi
    _set_current_list "$list"
    local -i status=$?
    echo "AGENDA: ${CURRENT_LIST}" |
        ${CAT} - "$CURRENT_LIST"
    _set_current_list "$old_list" 2>/dev/null
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
    sed -i "/$*/s/^- \[ \]/- \[X\]/" "$CURRENT_LIST"
    _commit_current_list \
        "Finished items matching '$*' from list '${CURRENT_LIST}'" \
        "$(echo "Items completed:" && grep "$*" "$CURRENT_LIST" |
                    sed '2,$s/^/	/')" ||
    ${CAT} "$CURRENT_LIST"
    return $?
}

to() { 
    # Adds item to specified TODO list
    _set_current_list "$1" && {
        shift 
        printf -- '- [ ] %s\n' "$@" | tee -a "$CURRENT_LIST"
        _commit_current_list
    } || _warn "Could not set todo list to '$1'"
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

