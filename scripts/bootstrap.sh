#!/bin/sh

set -eu

if [ "$#" -ne 0 ]; then
    echo "usage: $0" >&2
    exit 2
fi

cache_root=${XDG_CACHE_HOME:-"$HOME/.cache"}
checkout="$cache_root/ricochet-rs/agent-instructions"

if [ ! -d "$checkout/.git" ]; then
    mkdir -p "$cache_root/ricochet-rs"
    git clone --filter=blob:none https://github.com/ricochet-rs/agent-instructions.git "$checkout"
fi

actual_origin=$(git -C "$checkout" remote get-url origin)
if [ "$actual_origin" != "https://github.com/ricochet-rs/agent-instructions.git" ]; then
    echo "unexpected agent instructions origin: $actual_origin" >&2
    exit 1
fi

if [ -n "$(git -C "$checkout" status --porcelain)" ]; then
    echo "agent instructions checkout has local changes: $checkout" >&2
    exit 1
fi

git -C "$checkout" fetch --quiet origin main
git -C "$checkout" checkout --quiet --detach origin/main

for required_path in instructions/global.md .codex-plugin/plugin.json; do
    if [ ! -f "$checkout/$required_path" ]; then
        echo "required agent instructions file is missing: $required_path" >&2
        exit 1
    fi
done

resolved_revision=$(git -C "$checkout" rev-parse HEAD)
origin_revision=$(git -C "$checkout" rev-parse origin/main)
if [ "$resolved_revision" != "$origin_revision" ]; then
    echo "cached HEAD does not match origin/main" >&2
    exit 1
fi

echo "$checkout"
