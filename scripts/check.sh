#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

for script_path in "$repository_root"/scripts/*.sh; do
    sh -n "$script_path"
done

shellcheck -s sh "$repository_root"/scripts/*.sh
python3 "$repository_root/scripts/validate_resources.py"
"$repository_root/scripts/test_paired_instructions_pr.sh"

if command -v crow >/dev/null 2>&1; then
    crow lint --strict "$repository_root/.crow/"
    crow lint --strict "$repository_root/templates/crow-instructions.yaml"
    crow lint --strict "$repository_root/templates/codefloe-crow-instructions.yaml"
fi

placeholder='[''TODO:'
if rg -n --fixed-strings "$placeholder" "$repository_root"; then
    echo "unresolved placeholder found" >&2
    exit 1
fi
