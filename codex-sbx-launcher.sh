#!/bin/sh
set -eu

# Docker Sandboxes installation.
SBX="$HOME/.local/opt/docker-sandboxes-0.37.0/docker-sbx/sbx"

# Disable Docker Sandboxes CLI telemetry.
export SBX_NO_TELEMETRY=1

# Required on Debian because mkfs.ext4 lives in /usr/sbin.
# sandboxd inherits this PATH when started automatically.
export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Do not expose the host SSH agent to the sandbox.
unset SSH_AUTH_SOCK

FRESH=0

if [ "${1:-}" = "--fresh" ]; then
    FRESH=1
    shift
fi

if [ "$#" -gt 1 ]; then
    echo "Usage: codex-sbx [--fresh] [WORKSPACE]" >&2
    exit 2
fi

# Default to the current directory.
WORKSPACE="${1:-$PWD}"

# Resolve to a real absolute directory.
WORKSPACE="$(realpath -e -- "$WORKSPACE")"

if [ ! -d "$WORKSPACE" ]; then
    echo "Error: workspace is not a directory: $WORKSPACE" >&2
    exit 1
fi

# Generate a stable sandbox name from the folder name plus a short
# hash of its absolute path. This avoids collisions when two folders
# happen to have the same basename.
BASENAME="$(basename "$WORKSPACE" | sed 's/[^A-Za-z0-9._+-]/-/g')"
HASH="$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-8)"
NAME="codex-${BASENAME}-${HASH}"

echo "Workspace : $WORKSPACE"
echo "Sandbox   : $NAME"
echo "Mode      : direct read/write"

if [ "$FRESH" -eq 1 ]; then
    echo "Removing previous sandbox, if present..."
    "$SBX" rm --force "$NAME" >/dev/null 2>&1 || true
fi

# Garmin compiler and device definitions.
CIQ_STATE="$HOME/.local/share/garmin-connectiq/state"
CIQ_SDKS="$CIQ_STATE/Sdks"
CIQ_DEVICES="$CIQ_STATE/Devices"

for DIRECTORY in "$CIQ_SDKS" "$CIQ_DEVICES"; do
    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: Garmin directory does not exist: $DIRECTORY" >&2
        exit 1
    fi
done

if "$SBX" inspect "$NAME" >/dev/null 2>&1; then
    # Sandbox already exists: just start it.
    exec "$SBX" run \
        --name "$NAME"
else
    # Sandbox doesn't exist: create it with the workspaces.
    exec "$SBX" run \
        --name "$NAME" \
        codex \
        "$WORKSPACE" \
        "$CIQ_SDKS:ro" \
        "$CIQ_DEVICES:ro"
fi
