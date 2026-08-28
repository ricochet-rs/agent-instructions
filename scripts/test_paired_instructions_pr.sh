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
    *"api repos/"*"/commits/"*"/pulls"*)
        if [ -n "${MOCK_API_FAILURES:-}" ]; then
            failure_count=$(cat "${MOCK_API_FAILURE_COUNT_FILE:?}" 2>/dev/null || printf 0)
            if [ "$failure_count" -lt "$MOCK_API_FAILURES" ]; then
                printf '%s\n' "$((failure_count + 1))" >"$MOCK_API_FAILURE_COUNT_FILE"
                echo "unexpected end of JSON input" >&2
                exit 1
            fi
        fi
        printf '%s\n' "${MOCK_COMMIT_PR:-null}"
        ;;
    *"--json state --jq .state"*)
        printf '%s\n' "${MOCK_STATE:-OPEN}"
        ;;
    *)
        echo "unexpected gh invocation: $*" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$temporary_directory/gh"

cat >"$temporary_directory/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$temporary_directory/sleep"

cat >"$temporary_directory/curl" <<'EOF'
#!/bin/sh
jq -n \
    --arg body "${MOCK_BODY:-}" \
    --arg html_url "${MOCK_EFFECTIVE_URL:-https://codefloe.com/ricochet/example/pulls/1}" \
    --argjson merged "${MOCK_MERGED:-false}" \
    '{body: $body, html_url: $html_url, merged: $merged}'
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
run_case 0 "declares no shared instruction change" env MOCK_BODY="Instructions-PR: none" "$script" check ricochet-rs/example 1
run_case 0 "declares no shared instruction change" env MOCK_BODY="Instructions-PR: none" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "declares no shared instruction change" env MOCK_BODY="" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "declares no shared instruction change" env MOCK_BODY="unrelated body" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "at most one valid" env MOCK_BODY="Instructions-PR: none
Instructions-PR: none" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "at most one valid" env MOCK_BODY="Instructions-PR: #10" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "declares no shared instruction change" env FORGE_TOKEN=test MOCK_BODY="Instructions-PR: none" "$script" check https://codefloe.com ricochet/example 1
run_case 0 "is conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_DRAFT=true "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_STATE=MERGED "$script" check https://github.com ricochet-rs/example 1
run_case 1 "must be open, ready, target main, and be conflict free" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_MERGEABLE=CONFLICTING "$script" check https://github.com ricochet-rs/example 1
run_case 1 "exactly one matching Origin-PR trailer" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_PAIRED_BODY="Origin-PR: https://github.com/ricochet-rs/other/pull/2" "$script" check https://github.com ricochet-rs/example 1

# A pull-request body written or edited in a forge web UI comes back with CRLF endings,
# which leaves a carriage return on the trailer the parsers anchor with $.
crlf_none=$(printf 'Instructions-PR: none\r\n')
crlf_declaration=$(printf 'Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10\r\n')
crlf_origin=$(printf 'Origin-PR: https://github.com/ricochet-rs/example/pull/1\r\n')
run_case 0 "declares no shared instruction change" env MOCK_BODY="$crlf_none" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "is conflict free" env MOCK_BODY="$crlf_declaration" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "is conflict free" env MOCK_BODY="$crlf_declaration" MOCK_PAIRED_BODY="$crlf_origin" "$script" check https://github.com ricochet-rs/example 1
run_case 0 "skipping paired merge" env FORGE_TOKEN=test "$script" merge-for-commit https://codefloe.com ricochet/example abc123
run_case 0 "skipping paired merge" "$script" merge-for-commit ricochet-rs/example abc123
run_case 0 "skipping paired merge" env MOCK_API_FAILURES=1 MOCK_API_FAILURE_COUNT_FILE="$temporary_directory/transient-api-failures" "$script" merge-for-commit ricochet-rs/example abc123
run_case 1 "failed to look up merged effective PR" env MOCK_API_FAILURES=5 MOCK_API_FAILURE_COUNT_FILE="$temporary_directory/persistent-api-failures" "$script" merge-for-commit ricochet-rs/example abc123
run_case 0 "declares no shared instruction change" env FORGE_TOKEN=test MOCK_MERGED=true MOCK_BODY="" "$script" merge-for-commit https://codefloe.com ricochet/example abc123
run_case 0 "skipping paired merge" env FORGE_TOKEN=test MOCK_MERGED=true MOCK_BODY="Instructions-PR: #10" "$script" merge-for-commit https://codefloe.com ricochet/example abc123
run_case 0 "paired instructions PR is already merged" env MOCK_BODY="Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/10" MOCK_COMMIT_PR="https://github.com/ricochet-rs/example/pull/1" MOCK_STATE=MERGED "$script" merge-for-commit ricochet-rs/example abc123
