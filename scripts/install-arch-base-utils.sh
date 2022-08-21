#!/bin/bash

shell_join() {
    local arg
    printf "%s" "$1"
    shift
    for arg in "$@"; do
        printf " "
        printf "%s" "${arg// /\ }"
    done
}

chomp() {
    printf "%s" "${1/"$'\n'"/}"
}

ohai() {
    printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
    printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

# Search for the given executable in PATH (avoids a dependency on the `which` command)
which() {
    # Alias to Bash built-in command `type -P`
    type -P "$@"
}

# Search PATH for the specified program
# function which is set above
find_tool() {
    if [[ $# -ne 1 ]]; then
        return 1
    fi

    local executable
    while read -r executable; do
        if "test_$1" "${executable}"; then
            echo "${executable}"
            break
        fi
    done < <(which -a "$1")
}

execute() {
    if ! "$@"; then
        abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
    fi
}

function save_var() {
    local key="${1}"
    local value="${2}"

    echo "${key}=${value}" >>.env
    export ${key}="${value}"
}

function update_var() {
    local key="${1}"
    local value="${2}"

    sed -i "s/^${key}=.*/${key}=${value}/" .env
    export ${key}="${value}"
}

function print_header() {
    local messages=("${@}")

    echo
    echo "-------------------------------------------------"
    for message in "${messages[@]}"; do
        echo "${message}"
    done
    echo "-------------------------------------------------"
    echo
}

function reboot_after_delay() {
    local delay="${1}"

    ohai "Rebooting in ${delay} seconds..." "Press CTRL+C to cancel the reboot"
    for i in {1..${delay}}; do
        ohai "Rebooting in ${delay} seconds ..."
        sleep 1
        delay=$((delay - 1))
    done

    reboot now
}

function cleanup() {
    unset SCRIPT_DIR
    unset ISO
    unset DISK
    unset EFI_PARTITION
    unset ROOT_PARTITION
    unset CRYPTROOT_NAME
    unset CRYPTROOT_PATH
    unset TOTAL_MEM
    unset SWAPFILE_SIZE
    unset USERNAME
    unset CPU_CORES
    unset CPU_TYPE
    unset CPU_UCODE
    unset PKGS
    unset PKG
    unset ROOT_PARTITION_UUID
}

function mounts_success() {
    if ! [[ $(mount | grep "/mnt ") ]]; then
        return 1
    elif ! [[ $(mount | grep "/mnt/home ") ]]; then
        return 1
    elif ! [[ $(mount | grep "/mnt/var/log ") ]]; then
        return 1
    elif ! [[ $(mount | grep "/mnt/var/cache ") ]]; then
        return 1
    elif ! [[ $(mount | grep "/mnt/swap ") ]]; then
        return 1
    elif ! [[ $(mount | grep "/mnt/.snapshots ") ]]; then
        return 1
    else
        return 0
    fi
}
