#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 -m json.tool "$repository_root/.codex-plugin/plugin.json" >/dev/null
sh -n "$repository_root/scripts/bootstrap.sh"

for skill_path in "$repository_root"/skills/*; do
    skill_name=$(sed -n '2s/^name: //p' "$skill_path/SKILL.md")
    if [ "$skill_name" != "$(basename "$skill_path")" ]; then
        echo "skill name does not match its directory: $skill_path" >&2
        exit 1
    fi
    if ! sed -n '3p' "$skill_path/SKILL.md" | grep -q '^description: .'; then
        echo "skill description is missing: $skill_path" >&2
        exit 1
    fi
done

placeholder='[''TODO:'
if rg -n --fixed-strings "$placeholder" "$repository_root"; then
    echo "unresolved placeholder found" >&2
    exit 1
fi
