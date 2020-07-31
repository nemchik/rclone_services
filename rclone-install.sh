#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    # https://github.com/rclone/rclone/issues/811#issuecomment-255599253
    sudo sed -i -E 's/^#?user_allow_other$/user_allow_other/g' /etc/fuse.conf

    # https://rclone.org/install/#script-installation
    local GET_RCLONE
    GET_RCLONE=$(mktemp)
    curl -fsSL rclone.org/install.sh -o "${GET_RCLONE}"
    sudo bash "${GET_RCLONE}" || true
    rm -f "${GET_RCLONE}" || true
}
main
