#!/bin/bash

export GET_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export GET_REPO_DIR="$(dirname ${GET_SCRIPT_DIR})"
export GET_REPO_NAME="$(awk -F/ '{print $NF}' <<<${GET_REPO_DIR})"

function save() {
    local key="${1}"
    local value="${2}"

    echo "${key}=${value}" >>.env
    export ${key}="${value}"
}

function update() {
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

    print_header "Rebooting in ${delay} seconds..." "Press CTRL+C to cancel the reboot"
    for i in {1..${delay}}; do
        echo "Rebooting in ${delay} seconds ..."
        sleep 1
        delay=$((delay - 1))
    done

    reboot now
}

function cleanup() {
    unset SCRIPT_DIR
    unset REPO_DIR
    unset REPO_NAME
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
    unset GET_SCRIPT_DIR
    unset GET_REPO_DIR
    unset GET_REPO_NAME
}
