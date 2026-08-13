#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <revision>" >&2
    exit 2
fi

revision=$1
cache_root=${XDG_CACHE_HOME:-"$HOME/.cache"}
checkout="$cache_root/ricochet-rs/agent-instructions"

case "$revision" in
    *[!0-9a-f]* | "")
        echo "agent instructions revision must be a hexadecimal commit SHA" >&2
        exit 2
        ;;
esac

if [ ! -d "$checkout/.git" ]; then
    mkdir -p "$cache_root/ricochet-rs"
    git clone --filter=blob:none git@github.com:ricochet-rs/agent-instructions.git "$checkout"
fi

actual_origin=$(git -C "$checkout" remote get-url origin)
if [ "$actual_origin" != "git@github.com:ricochet-rs/agent-instructions.git" ]; then
    echo "unexpected agent instructions origin: $actual_origin" >&2
    exit 1
fi

if [ -n "$(git -C "$checkout" status --porcelain)" ]; then
    echo "agent instructions checkout has local changes: $checkout" >&2
    exit 1
fi

git -C "$checkout" fetch --quiet origin "$revision"
git -C "$checkout" checkout --quiet --detach "$revision"

for required_path in instructions/global.md .codex-plugin/plugin.json skills/development-flow/SKILL.md; do
    if [ ! -f "$checkout/$required_path" ]; then
        echo "required agent instructions file is missing: $required_path" >&2
        exit 1
    fi
done

resolved_revision=$(git -C "$checkout" rev-parse HEAD)
case "$resolved_revision" in
    "$revision"*) ;;
    *)
        echo "resolved revision does not match requested revision" >&2
        exit 1
        ;;
esac

echo "$checkout"
