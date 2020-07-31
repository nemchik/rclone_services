#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    if [[ ${EUID} -eq 0 ]]; then
        echo "Running as root or with sudo is not supported. Please run as a standard user. The script will call sudo as needed."
        exit 1
    fi

    if [[ ! -f "${HOME}/.config/rclone/rclone.conf" ]]; then
        echo "Run the following command to configure your rclone remotes:"
        echo "rclone config"
        exit 1
    fi

    while IFS= read -r line; do
        if [[ ! -f "${HOME}/.config/rclone/${line%%:}.env" ]]; then
            echo "RCLONE_LOCAL_PATH must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "RCLONE_RC_ADDR must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different path and port."
            echo "${line} will not be mounted."
            echo
            continue
        fi

        source "${HOME}/.config/rclone/${line%%:}.env"

        if [[ ! "${RCLONE_LOCAL_PATH}" =~ ^/.* ]]; then
            echo "RCLONE_LOCAL_PATH must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different path."
            echo "${line} will not be mounted."
            echo
            continue
        fi
        if [[ ! "${RCLONE_RC_ADDR}" =~ ^[a-zA-Z0-9_\.\-]+:[0-9]{1,5}$ ]]; then
            echo "RCLONE_RC_ADDR must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different port."
            echo "${line} will not be mounted."
            echo
            continue
        fi

        sudo mkdir -p "${RCLONE_LOCAL_PATH}"
        systemctl --user start rclone@"${line%%:}".service
        systemctl --user enable rclone@"${line%%:}".service
        echo "Successfully mounted ${RCLONE_LOCAL_PATH}"
    done < <(rclone listremotes)
}
main
