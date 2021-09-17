#!/bin/bash
# Functions to print Bash variables to arbitrary markup formats

_map_array() {
    local -n _arr_="$1" && shift || return -1
    local -a fn=( "${@@Q}" )
    if [ ${#fn[@]} -eq 0 ]; then fn+=( "echo" ); fi
    local -i _i=0
    while [ $_i -lt ${#_arr_[@]} ]; do
        _arr_[$_i]="$(eval ${fn[@]} "${_arr_[$_i]}")"
        let _i+=1
    done
}

_map_keys() {
    local -n _dict_="$1" && shift || return -1
    local -a fn=( "${@@Q}" ) keys=( "${!_dict_[@]}" )
    if [ ${#fn[@]} -eq 0 ]; then fn+=( "echo" ); fi
    local _mapped_=
    for key in "${keys[@]}"; do
        _mapped_="$(eval ${fn[@]} "$key")"
        if ! [ "$_mapped_" == "$key" ]; then
            _dict_["$_mapped_"]="${_dict_[$key]}"
            unset _dict_[$key]
        fi
    done
}

_map_values() {
    local -n _dict_="$1" && shift || return -1
    local -a fn=( "${@@Q}" )
    if [ ${#fn[@]} -eq 0 ]; then fn+=( "echo" ); fi
    for key in "${!_dict_[@]}"; do
        _dict_[$key]="$(eval ${fn[@]} "${_dict_[$key]}")"
    done
}

_map_items() {
    local -n _dict_="$1" && shift || return -1
    local -a fn=( "${@@Q}" )
    if [ ${#fn[@]} -eq 0 ]; then fn+=( "echo" ); fi
    for key in "${!_dict_[@]}"; do
        eval ${fn[@]} "$key" "${_dict_[$key]}"
    done
}

_transform() (
    # Generic function for printing strings, variables, arrays, and associative
    # arrays
    # Formatters can be specified as arguments to the same options the `declare`
    # builtin takes (i.e., -i -A -a -n -r...)
    # Each such argument is interpreted as a function to be applied to the
    # passed variable(s) of the corresponding type

    # Make sure infinite recursive loops fail
    export FUNCNEST=10

    local -A handlers=( )
    local -a handler=( )

    # Generic handler (i.e., for anything other than arrays, ints, etc.)
    local -a generic=( )

    _recurse() (
        # Helper to recursively print array / assoc. array elements
        local -n val="$1" && shift
        local -a handler=( "$@" )
        local -a opts=( ${handlers[@]@K} )
        case "${val@a}" in
            *a*) 
                _map_array val _transform ${opts[@]} --
                eval ${handler[@]} "${val[@]}"
                ;;
            *A*) 
                _map_values val _transform ${opts[@]} --
                # ${handler[@]} "${!val}"
                eval ${handler[@]} "${val[@]@K}"
                ;;
            *) 
                eval ${handler[@]} "${!val}"
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
                    handlers[$kind]+=" ${1@Q}"
                    shift
                done
                ;;
            *)
                generic+=( $1 ); shift
                ;;
        esac
    done

    if [ ${#generic[@]} -eq 0 ]; then
        generic=( "declare" "-p" )
    fi

    # echo "${handlers[@]@K}" >&2

    for arg in "$@"; do
        handler=( )
        # First try dereferencing arg
        if local -n ref="$arg" 2>/dev/null && [ -n "${ref@a}" ]; then 
            for k in "${!handlers[@]}"; do
                # Param expansion ${var@a} --> prints attributes of $var
                if [[ "${k#-}" == *"${ref@a}"* ]]; then
                    handler=( ${handlers[$k]} )
                fi
            done
            if [ ${#handler[@]} -eq 0 ]; then
                handler=( ${generic[@]} )
            fi
            _recurse ref ${handler[@]}
        else
            # If reference logic fails, just print the value of the arg
            echo "$arg"
        fi
    done
    return $?
)

_yaml_arr () 
{ 
    local -n _yaml_arr="$1";
    printf -- '- %s\n' "${_yaml_arr[@]}";
    return $?
}
