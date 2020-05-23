#!/bin/bash
set -euo pipefail

rootdisk=/dev/disk/by-label/root
saved_sysroot=/run/ignition-ostree-rootfs

case "${1:-}" in
    detect)
        # This is obviously crude; perhaps in the future we could change ignition's `fetch`
        # stage to write out a file if the rootfs is being replaced or so.  But eh, it
        # works for now.
        wipes_root=$(jq '.storage?.filesystems? // [] | map(select(.label == "root" and .wipeFilesystem == true)) | length' < /run/ignition.json)
        if [ "${wipes_root}" = "0" ]; then
            exit 0
        fi
        echo "Detected rootfs replacement in fetched Ignition config: /run/ignition.json"
        mkdir "${saved_sysroot}"
        ;;
    save)
        mount "${rootdisk}" /sysroot
        echo "Moving rootfs to RAM..."
        cp -aT /sysroot "${saved_sysroot}"
        ;;
    restore)
        # This one is in a private mount namespace since we're not "offically" mounting
        mount "${rootdisk}" /sysroot
        echo "Restoring rootfs from RAM..."
        cd "${saved_sysroot}"
        find . -mindepth 1 -maxdepth 1 -exec mv {} /sysroot \;
        ;;
    *)
        echo "Unsupported operation: ${1:-}" 1>&2; exit 1
        ;;
esac
