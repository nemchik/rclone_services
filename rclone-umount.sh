#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    if [[ ${EUID} -eq 0 ]]; then
        echo "Running as root or with sudo is not supported. Please run as a standard user. The script will call sudo as needed."
        exit 1
    fi

    if [[ $(rclone listremotes | wc -l) -lt 1 ]]; then
        echo "Run the following command to configure your rclone remotes:"
        echo "rclone config"
        exit 1
    fi

    while IFS= read -r line; do
        if [[ ! -f "${HOME}/.config/rclone/${line%%:}.env" ]]; then
            echo "RCLONE_LOCAL_PATH must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "RCLONE_RC_ADDR must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different path and port."
            echo "${line} will not be umounted."
            echo
            continue
        fi

        # shellcheck source=/dev/null
        source "${HOME}/.config/rclone/${line%%:}.env"

        if [[ ! "${RCLONE_LOCAL_PATH}" =~ ^/.* ]]; then
            echo "RCLONE_LOCAL_PATH must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different path."
            echo "${line} will not be umounted."
            echo
            continue
        fi
        if [[ ! "${RCLONE_RC_ADDR}" =~ ^[a-zA-Z0-9_\.\-]+:[0-9]{1,5}$ ]]; then
            echo "RCLONE_RC_ADDR must be set in ${HOME}/.config/rclone/${line%%:}.env"
            echo "Each remote requires a different port."
            echo "${line} will not be umounted."
            echo
            continue
        fi

        sudo umount "${RCLONE_LOCAL_PATH}" || true

        systemctl --user stop rclone@"${line%%:}".service || true
        systemctl --user disable rclone@"${line%%:}".service || true

        systemctl --user stop rclone_vfs_refresh@"${line%%:}".service || true
        systemctl --user disable rclone_vfs_refresh@"${line%%:}".service || true

        systemctl --user stop rclone_vfs_refresh@"${line%%:}".timer || true
        systemctl --user disable rclone_vfs_refresh@"${line%%:}".timer || true

        echo "Successfully umounted ${RCLONE_LOCAL_PATH}"
    done < <(rclone listremotes)
}
main
