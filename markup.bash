#!/bin/bash
# Functions to print Bash variables to arbitrary markup formats

_map_array() {
    local -n _arr_="$1" && shift || return -1
    local -a fn=( "$@" )
    local -i _i=0
    while [ $_i -lt ${#_arr_[@]} ]; do
        _arr_[$_i]="$(${fn[@]} "${_arr_[$_i]}")"
        let _i+=1
    done
}

_map_keys() {
    local -n _dict_="$1" && shift || return -1
    local -a fn=( "$@" ) keys=( "${!_dict_[@]}" )
    local _mapped_=
    for key in "${keys[@]}"; do
        _mapped_="$(${fn[@]} "$key")"
        if ! [ "$_mapped_" == "$key" ]; then
            _dict_["$_mapped_"]="${_dict_[$key]}"
            unset _dict_[$key]
        fi
    done
}

_map_values() {
    local -n _dict_="$1" && shift || return -1
    local -a fn=( "$@" )
    for key in "${!_dict_[@]}"; do
        _dict_[$key]="$(${fn[@]} "${_dict_[$key]}")"
    done
}

_transform() (
    # Generic function for printing strings, variables, arrays, and associative
    # arrays
    # Formatters can be specified as arguments to the same options the `declare`
    # builtin takes (i.e., -i -A -a -n -r...)
    # Each such argument is interpreted as a function to be applied to the
    # passed variable(s) of the corresponding type

    # Can't use associative array because order matters
    local -A handlers=( )
    local -a handler=( )

    # Generic handler (i.e., for anything other than arrays, ints, etc.)
    local -a generic=( )

    _recurse() (
        # Helper to recursively print array / assoc. array elements
        local type="$1" 
        local -n val="$2" && shift 2
        local -a handler=( "$@" )
        case "$1" in
            *a*) 
                _map_array val _transform ${handlers[@]@K} --
                ${handler[@]} "${!val}"
                ;;
            *A*) 
                _map_values val _transform ${handlers[@]@K} --
                ${handler[@]} "${!val}"
                ;;
            *) 
                ${handler[@]} "${!val}" 
                ;;
        esac
    )

    while [ $# -gt 0 ]; do
        case "$1" in
            --)
                shift
                break
                ;;
            -*) 
                local kind="$1"; shift
                while ! [[ "$1" == -* ]]; do
                    handlers[$kind]+="$1"
                    shift
                done
                ;;
            *)
                generic+=( $1 ); shift
                ;;
        esac
    done

    # echo "generic --> ${#generic[@]} elements"
    echo "${handlers[@]@K}" >&2

    if [ ${#generic[@]} -eq 0 ]; then
        generic=( "declare" "-p" )
    fi

    for arg in "$@"; do
        handler=( )
        # Try treating arg as reference variable
        local -n ref="$arg" 2>/dev/null && [ -n "${ref+x}" ] && {
            local kind="$(declare -p "${!ref}" 2>/dev/null | cut -f2)"
            for k in "${!handlers[@]}"; do
                if [[ "$kind" == -*"${handlers[$k]#-}"* ]]; then
                    handler=( ${handlers[$k]} )
                fi
            done
            if [ ${#handler[@]} -eq 0 ]; then
                handler=( ${generic[@]} )
            fi
            _recurse "$kind" ref "${handler[@]}"
        } || {
            # If reference logic fails, just print the value of the arg
            # $generic "$arg" 2>/dev/null || echo "$arg"
            echo "$arg"
        }
    done
    return $?
)

_yaml_arr () 
{ 
    local -n _yaml_arr="$1";
    printf -- '- %s\n' "${_yaml_arr[@]}";
    return $?
}
