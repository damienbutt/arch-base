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
