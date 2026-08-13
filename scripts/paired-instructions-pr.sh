#!/bin/sh

set -eu

instructions_repository=ricochet-rs/agent-instructions

effective_pr_details() {
    forge_url=$1
    effective_repository=$2
    effective_pr=$3

    case "$forge_url" in
        https://github.com)
            gh pr view "$effective_pr" --repo "$effective_repository" --json body,url
            ;;
        *)
            if [ -z "${FORGE_TOKEN:-}" ]; then
                echo "FORGE_TOKEN is required for $forge_url" >&2
                exit 1
            fi
            curl -fsS -H "Authorization: token $FORGE_TOKEN" \
                "$forge_url/api/v1/repos/$effective_repository/pulls/$effective_pr" |
                jq '{body: .body, url: .html_url}'
            ;;
    esac
}

instructions_pr_declaration() {
    forge_url=$1
    effective_repository=$2
    effective_pr=$3
    body=$(effective_pr_details "$forge_url" "$effective_repository" "$effective_pr" | jq -r .body)
    printf '%s\n' "$body" | awk '
        $0 == "Instructions-PR: none" { print "none" }
        $0 ~ /^Instructions-PR: https:\/\/github.com\/ricochet-rs\/agent-instructions\/pull\/[0-9]+$/ {
            sub(/^Instructions-PR: /, "")
            print
        }
    '
}

verify_instructions_pr() {
    instructions_pr=$1
    expected_origin=$2
    attempt=1

    while [ "$attempt" -le 5 ]; do
        details=$(gh pr view "$instructions_pr" --json baseRefName,body,isDraft,mergeable,state)
        mergeable=$(printf '%s' "$details" | jq -r .mergeable)
        if [ "$mergeable" != UNKNOWN ]; then
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    base=$(printf '%s' "$details" | jq -r .baseRefName)
    draft=$(printf '%s' "$details" | jq -r .isDraft)
    state=$(printf '%s' "$details" | jq -r .state)
    origins=$(printf '%s' "$details" | jq -r .body | awk '
        /^Origin-PR: https:\/\/(github.com\/ricochet-rs|codefloe.com\/ricochet)\/[A-Za-z0-9._-]+\/(pull|pulls)\/[0-9]+$/ {
            sub(/^Origin-PR: /, "")
            print
        }
    ')
    origin_count=$(printf '%s\n' "$origins" | grep -c . || true)

    if [ "$base" != main ] || [ "$draft" != false ] || [ "$state" != OPEN ] || [ "$mergeable" != MERGEABLE ]; then
        echo "paired instructions PR must be open, ready, target main, and be conflict free: $instructions_pr" >&2
        echo "$details" >&2
        exit 1
    fi
    if [ "$origin_count" -ne 1 ] || [ "$origins" != "$expected_origin" ]; then
        echo "paired instructions PR must contain exactly one matching Origin-PR trailer: $expected_origin" >&2
        exit 1
    fi
}

check_pr() {
    forge_url=$1
    effective_repository=$2
    effective_pr=$3
    details=$(effective_pr_details "$forge_url" "$effective_repository" "$effective_pr")
    declarations=$(instructions_pr_declaration "$forge_url" "$effective_repository" "$effective_pr")
    declaration_count=$(printf '%s\n' "$declarations" | grep -c . || true)
    if [ "$declaration_count" -ne 1 ]; then
        echo "effective PR must contain exactly one valid Instructions-PR trailer" >&2
        echo "add one of these exact lines to the pull-request body:" >&2
        echo "Instructions-PR: none" >&2
        echo "Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/<number>" >&2
        exit 1
    fi
    instructions_pr=$declarations
    if [ "$instructions_pr" = none ]; then
        echo "effective PR declares no shared instruction change"
        exit 0
    fi
    effective_pr_url=$(printf '%s' "$details" | jq -r .url)
    verify_instructions_pr "$instructions_pr" "$effective_pr_url"
    echo "paired instructions PR is conflict free: $instructions_pr"
}

merge_for_commit() {
    forge_url=$1
    repository=$2
    commit=$3
    attempt=1
    effective_pr=
    while [ "$attempt" -le 5 ]; do
        case "$forge_url" in
            https://github.com)
                effective_pr=$(gh api "repos/$repository/commits/$commit/pulls" --jq 'map(select(.merged_at != null)) | first | .html_url')
                ;;
            *)
                effective_pr=$(curl -fsS -H "Authorization: token $FORGE_TOKEN" \
                    "$forge_url/api/v1/repos/$repository/commits/$commit/pull" |
                    jq -r 'select(.merged == true) | .html_url')
                ;;
        esac
        if [ -n "$effective_pr" ] && [ "$effective_pr" != null ]; then
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    if [ -z "$effective_pr" ] || [ "$effective_pr" = null ]; then
        echo "no merged effective PR found for $commit" >&2
        exit 1
    fi

    effective_pr_number=${effective_pr##*/}
    declarations=$(instructions_pr_declaration "$forge_url" "$repository" "$effective_pr_number")
    declaration_count=$(printf '%s\n' "$declarations" | grep -c . || true)
    if [ "$declaration_count" -ne 1 ]; then
        echo "merged effective PR has no valid Instructions-PR trailer; skipping paired merge"
        exit 0
    fi
    instructions_pr=$declarations
    if [ "$instructions_pr" = none ]; then
        echo "merged effective PR declares no shared instruction change"
        exit 0
    fi

    verify_instructions_pr "$instructions_pr" "$effective_pr"
    instructions_head=$(gh pr view "$instructions_pr" --repo "$instructions_repository" --json headRefOid --jq .headRefOid)
    gh pr merge "$instructions_pr" --repo "$instructions_repository" --squash --delete-branch --match-head-commit "$instructions_head"
}

case "${1:-}" in
    check)
        if [ "$#" -ne 4 ]; then
            echo "usage: $0 check <forge-url> <repository> <effective-pr>" >&2
            exit 2
        fi
        check_pr "$2" "$3" "$4"
        ;;
    merge-for-commit)
        if [ "$#" -ne 4 ]; then
            echo "usage: $0 merge-for-commit <forge-url> <repository> <commit>" >&2
            exit 2
        fi
        merge_for_commit "$2" "$3" "$4"
        ;;
    *)
        echo "usage: $0 {check <forge-url> <repository> <effective-pr>|merge-for-commit <forge-url> <repository> <commit>}" >&2
        exit 2
        ;;
esac
