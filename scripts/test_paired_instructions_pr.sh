#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

cat >"$temporary_directory/gh" <<'EOF'
#!/bin/sh

case "$*" in
    *"--json body,url"*)
        jq -n --arg body "${MOCK_BODY:-}" --arg url "${MOCK_EFFECTIVE_URL:-https://github.com/ricochet-rs/example/pull/1}" '{body: $body, url: $url}'
        ;;
    *"--json baseRefName,body,isDraft,mergeable,state"*)
        jq -n \
            --arg baseRefName "${MOCK_BASE:-main}" \
            --arg body "${MOCK_PAIRED_BODY:-Origin-PR: https://github.com/ricochet-rs/example/pull/1}" \
            --argjson isDraft "${MOCK_DRAFT:-false}" \
            --arg mergeable "${MOCK_MERGEABLE:-MERGEABLE}" \
            --arg state "${MOCK_STATE:-OPEN}" \
            '{baseRefName: $baseRefName, body: $body, isDraft: $isDraft, mergeable: $mergeable, state: $state}'
        ;;
    *)
        echo "unexpected gh invocation: $*" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$temporary_directory/gh"

cat >"$temporary_directory/curl" <<'EOF'
#!/bin/sh
jq -n --arg body "${MOCK_BODY:-}" --arg html_url "${MOCK_EFFECTIVE_URL:-https://codefloe.com/ricochet/example/pulls/1}" '{body: $body, html_url: $html_url}'
EOF
chmod +x "$temporary_directory/curl"

run_case() {
    expected_status=$1
    expected_output=$2
    shift 2
    output_file="$temporary_directory/output"
    if env PATH="$temporary_directory:$PATH" "$@" >"$output_file" 2>&1; then
        actual_status=0
    else
        actual_status=$?
    fi
    if [ "$actual_status" -ne "$expected_status" ]; then
        cat "$output_file" >&2
        echo "expected status $expected_status, got $actual_status" >&2
        exit 1
    fi
    if ! grep -Fq "$expected_output" "$output_file"; then
        cat "$output_file" >&2
        echo "expected output: $expected_output" >&2
        exit 1
    fi
}

script="$repository_root/scripts/paired-instructions-pr.sh"
run_case 0 "declares no shared instruction change" env MOCK_BODY="Instructions-PR: none" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "exactly one valid" env MOCK_BODY="" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "exactly one valid" env MOCK_BODY="Instructions-PR: none
Instructions-PR: none" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "exactly one valid" env MOCK_BODY="Instructions-PR: #10" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "declares no shared instruction change" env FORGE_TOKEN=test MOCK_BODY="Instructions-PR: none" "$script" check https://codefloe.com ricochet/example 1
run_case 0 "is conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_DRAFT=true "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_STATE=MERGED "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_MERGEABLE=CONFLICTING "$script" check https://github.com ricochet-rs/example 1
run_case 1 "exactly one matching Origin-PR trailer" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_PAIRED_BODY="Origin-PR: https://github.com/ricochet-rs/other/pull/2" "$script" check https://github.com ricochet-rs/example 1
