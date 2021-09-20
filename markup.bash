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
    local handler=

    # Generic handlers (i.e., fallbacks to use when variable type has no
    # associated handler)
    local generic=

    _recurse() (
        # Helper to recursively print array / assoc. array elements
        local -n val="$1" && shift
        local -a handler=( $@ )
        local -a opts=( ${handlers[@]@K} )
        case "${val@a}" in
            *a*) 
                # echo "Recursing into array ${!val}='${val[@]}'..." >&2
                # printf '%s\n' "${opts[*]@A}" "${handler[*]@A}" >&2
                _map_array val _transform ${opts[@]} -- &&
                    eval ${handler[@]} "${val[@]}" 2>/dev/null ||
                    eval ${handler[@]} "${!val}" 2>/dev/null ||
                    { echo "Could not recurse into array ${!val}" >&2; 
                        return 1; }
                ;;
            *A*) 
                # echo "Recursing into associative array ${!val}='${val[@]@K}'..." >&2
                # printf '%s\n' "${opts[*]@A}" "${handler[*]@A}" >&2
                _map_values val _transform ${opts[@]} -- &&
                    eval ${handler[@]} ${val[@]@K} 2>/dev/null ||
                    eval ${handler[@]} "${!val}" 2>/dev/null ||
                    { echo "Could not recurse into associative array ${!val}" >&2; 
                        return 1; }
                ;;
            *) 
                # echo "Handling plain value ${!val}='${val}'..." >&2
                # printf '%s\n' "${opts[*]@A}" "${handler[*]@A}" >&2
                eval ${handler[@]} "$val" 2>/dev/null ||
                    eval ${handler[@]} "${!val}" 2>/dev/null ||
                    { echo "Failed to apply handler '${handler[@]}' to value ${!val}='$val'" >&2;
                        return 1; }
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
                local kind="$1"; shift;
                # handlers[$kind]="${2@Q}"; shift 2
                while ! [[ "$1" == -* ]]; do
                    handlers[$kind]+=" ${1@Q} "
                    shift
                done
                ;;
            *)
                generic+=" ${1} "; shift;
                ;;
        esac
    done

    if [ -z "$generic" ]; then
        generic="declare -p"
    fi

    for arg in "$@"; do
        handler=
        # First try dereferencing arg
        # Param expansion ${var@a} --> prints attributes of $var
        if local -n ref="$arg" 2>/dev/null && [ -n "${ref@a}" ]; then 
            for k in "${!handlers[@]}"; do
                if [[ "${k#-}" == *"${ref@a}"* ]]; then
                    # eval handler=( ${handlers[$k]} )
                    # eval local x="${handlers[$k]}"
                    handler="${handlers[$k]}"
                fi
            done
            if [ -z "$handler" ]; then
                # eval handler=( ${generic[@]} )
                # eval x="${generic[*]}"
                handler="$generic"
            fi
            _recurse ref "$handler"
            # _recurse ref "$x"
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
