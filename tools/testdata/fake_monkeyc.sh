#!/usr/bin/env bash
set -euo pipefail

[[ -f "$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ]]
[[ -d "$HOME/.Garmin/ConnectIQ/Devices" ]]

if [[ "${1:-}" == "--version" ]]; then
    echo "Fake Connect IQ compiler"
fi
