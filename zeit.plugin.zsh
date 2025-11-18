zeit() {
    zmodload zsh/datetime 2>/dev/null

    if (( $# == 0 )); then
        print "Usage: zeit <command>"
        return 1
    fi

    local zeit_tmp exit_code
    local -F realtime user_t sys_t
    local -i max_bar_width=40

    zeit_tmp="/tmp/.zeit_$$"

    local TIMEFMT='%*E %*U %*S'

    { time "$@" 2>&3; } 3>&2 2> "$zeit_tmp"
    exit_code=$?

    read -r realtime user_t sys_t < "$zeit_tmp"
    rm -f "$zeit_tmp"

    if [[ -z "$realtime" ]]; then
        realtime=0; user_t=0; sys_t=0
    fi


    format_time() {
        local -F t="$1"
        if (( t < 0.000001 )); then
             printf "0.00 s"
        elif (( t < 0.001 )); then
            printf "%.2f µs" $(( t * 1000000 ))
        elif (( t < 1 )); then
            printf "%.2f ms" $(( t * 1000 ))
        else
            printf "%.2f s" "$t"
        fi
    }

    local real_fmt=$(format_time $realtime)
    local user_fmt=$(format_time $user_t)
    local sys_fmt=$(format_time $sys_t)

    make_bar() {
        local -F value="$1"
        local -F total="$2"
        local -i width

        (( width = (value / total) * max_bar_width ))

        (( width < 1 && value > 0 )) && width=1
        (( width > max_bar_width )) && width=max_bar_width

        printf "%${width}s" | tr " " "█"
    }

    local real_bar=$(make_bar $realtime $realtime)
    local user_bar=$(make_bar $user_t $realtime)
    local sys_bar=$(make_bar $sys_t $realtime)

    local BLUE="%F{4}" CYAN="%F{6}" GREEN="%F{2}"
    local YELLOW="%F{3}" MAGENTA="%F{5}" RESET="%f"
    local BOLD="%B" NO_BOLD="%b"

    print_row() {
        local color="$1"
        local label="$2"
        local time="$3"
        local bar="$4"
        print -P " ${color}${(r:5:)label}${RESET}  ${BOLD}${(l:10:)time}${NO_BOLD}  ${color}${bar}${RESET}"
    }

    print -P "${BLUE}──────────────────────────────────────────────${RESET}"
    print -P " ${CYAN}Executed in${RESET}  ${GREEN}${BOLD}$real_fmt${NO_BOLD}${RESET}   (exit: $exit_code)"
    echo ""
    print_row "$CYAN"    "real" "$real_fmt" "$real_bar"
    print_row "$YELLOW"  "user" "$user_fmt" "$user_bar"
    print_row "$MAGENTA" "sys"  "$sys_fmt"  "$sys_bar"
    print -P "${BLUE}──────────────────────────────────────────────${RESET}"
}
