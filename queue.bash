#!/bin/bash
# Basic "queue" datastructure

export DNF_QUEUE="$HOME/.queue.dnf"
export DNF_QUEUE_HIST="${DNF_QUEUE}.hist"

_queue_usage() {
    case "$1" in
        queue)
            cat <<-USAGE
				USAGE:
				    queue [-f filename] [-q queuename] [-l] [-H] [-S] [-e] [-h] packagenames
				OPTS:
				    -f      Add contents of file to queue
				    -q      Specify file to use as queue
				    -l      Dump contents of queue to stdout after modifying
				    -H      Dump contents of queue history to stdout
				    -S      Search for packages using DNF before adding to queue
				    -e      Edit contents of queue using \$EDITOR
				    -h      Display this message and return 0
				USAGE
            ;;
        dequeue)
            cat <<-USAGE
				USAGE:
				    dequeue [-q queuename] [-s] [-h]
				OPTS:
				    -q      Specify file to use as queue
				    -s      Show results
				    -h      Display this message and return 0
				USAGE
            ;;
        *)
            return -1
            ;;
    esac
    return 0
}

queue() { 
    # Queues packages for installation
    OPTIND=1
    local queue="$DNF_QUEUE"
    local -a files=( )
    local -a notfound=( )
    local show=0 show_hist=0 edit=0 search=0
    while getopts ":f:q:lHSeh" opt; do
        case "$opt" in 
            f)
                files+=( "$OPTARG" )
                ;;
            q)
                queue="$OPTARG"
                ;;
            l)
                show=1
                ;;
            H)
                show_hist=1
                ;;
            S)
                search=1
                ;;
            e)
                edit=1
                ;;
            h)
                _queue_usage queue; return 0
                ;;
            *)
                _queue_usage queue >&2; return -1
                ;;
        esac
    done
    local hist="${queue}.hist"
    shift $(( OPTIND - 1 ))
    if ! [ -w "$queue" ]; then
        echo "Cannot write to queue file '${queue}'" >&2
        return 1
    fi
    while read -r package; do
        package="$(sed \
            -e 's/^[[:space:]]//' \
            -e 's/[[:space:]]$//' <<<"$package")"
        if [ $search -ne 0 ]; then
            dnf search "$package" >/dev/null 2>&1 &&
                echo "$package" >>"$queue" ||
                notfound+=( "$package" )
        elif [ -n "$package" ] && ! grep "$package" "$queue" >/dev/null 2>&1
        then
            echo "$package" >>"$queue"
        fi
    done < <(printf '%s\n' "$@" | cat "${files[@]}" -)
    if [ $show -ne 0 ]; then
        cat "$queue"
    fi
    if [ $show_hist -ne 0 ]; then
        cat "$hist"
    fi
    if [ $edit -ne 0 ]; then
        $EDITOR "$queue"
    fi
    return $?
}

dequeue() {
    # Installs packages from queue
    OPTIND=1
    local queue="$DNF_QUEUE"
    local -A results=( )
    local show=0
    while getopts ":q:sh" opt; do
        case "$opt" in 
            q)
                queue="$OPTARG"
                ;;
            s)
                show=1
                ;;
            h)
                _queue_usage dequeue; return 0
                ;;
            *)
                _queue_usage dequeue >&2; return -1
                ;;
        esac
    done
    local hist="${queue}.hist"
    shift $(( OPTIND - 1 ))
    if ! [ -r "$queue" ]; then
        echo "Cannot read queue file '${queue}'" >&2
        return 1
    fi
    touch "$hist" || {
        echo "Cannot touch queue history file '${hist}'" >&2;
        return 2
    }
    echo "[`date -u`]" >>"$hist"
    while read -r package; do
        dnf list --installed "$package" >/dev/null 2>&1 &&
            results["$package"]="Already installed" || {
                sudo dnf install -y "$package" &&
                    results["$package"]="Installed" ||
                    results["$package"]="Failed"
                }
        if [ $show -ne 0 ]; then
            printf '%s: %s\n' "$package" "${results[$package]}" | tee -a "$hist"
        else
            printf '%s: %s\n' "$package" "${results[$package]}" >>"$hist"
        fi
    done <"$queue"
    rm "$queue" && touch "$queue" || {
        echo "Cannot refresh queue file '${queue}'" >&2;
        return 3
    }
    return $?
}

unqueue() {
    # Removes items from queue without installing
    # TODO: Implement
    :
}
