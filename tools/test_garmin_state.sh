#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

test_home="$test_root/home"
test_state="$test_root/state"
test_sdk="$test_state/Sdks/connectiq-sdk-test"
real_config="$test_home/.Garmin/ConnectIQ/current-sdk.cfg"

mkdir -p \
    "$test_home/.Garmin/ConnectIQ" \
    "$test_sdk/bin" \
    "$test_state/Devices/edge840"

printf '%s\n' '/user/selected/connectiq-sdk' > "$real_config"

cp "$repo_dir/tools/testdata/fake_monkeyc.sh" "$test_sdk/bin/monkeyc"
chmod +x "$test_sdk/bin/monkeyc"

HOME="$test_home" GARMIN_STATE="$test_state" \
    "$repo_dir/tools/garmin" doctor >/dev/null

expected="/user/selected/connectiq-sdk"
actual="$(cat "$real_config")"
[[ "$actual" == "$expected" ]] || {
    echo "tools/garmin changed the caller's current-sdk.cfg" >&2
    exit 1
}

standard_home="$test_root/standard-home"
standard_state="$standard_home/.Garmin/ConnectIQ"
standard_sdk="$standard_state/Sdks/connectiq-sdk-test"
standard_config="$standard_state/current-sdk.cfg"

mkdir -p \
    "$standard_sdk/bin" \
    "$standard_state/Devices/edge840"

printf '%s\n' '/user/selected/standard-sdk' > "$standard_config"
cp "$repo_dir/tools/testdata/fake_monkeyc.sh" "$standard_sdk/bin/monkeyc"
chmod +x "$standard_sdk/bin/monkeyc"

HOME="$standard_home" XDG_DATA_HOME="$standard_home/xdg" \
    "$repo_dir/tools/garmin" doctor >/dev/null

expected="/user/selected/standard-sdk"
actual="$(cat "$standard_config")"
[[ "$actual" == "$expected" ]] || {
    echo "tools/garmin changed the standard Garmin current-sdk.cfg" >&2
    exit 1
}

echo "Garmin state isolation test passed."
