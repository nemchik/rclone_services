#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    while IFS= read -r line; do
        /bin/mkdir -p "/mnt/remote/rclone.${line%%:}"
        sudo systemctl enable rclone@"${line%%:}".service
        sudo systemctl start rclone@"${line%%:}".service
    done < <(/usr/bin/rclone listremotes)
}
main
