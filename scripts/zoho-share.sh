#!/bin/sh

# Upload a file to Zoho WorkDrive and print a public share link.
#
# Credentials come from OpenBao at saas/zoho/workdrive, or from ZOHO_WORKDRIVE_*
# environment variables when they are already exported. Nothing is written to disk.
#
# Usage: zoho-share.sh [--folder-id ID] [--name NAME] [--no-download] [--json] FILE...

set -eu

BAO_SECRET_PATH=${ZOHO_WORKDRIVE_SECRET_PATH:-saas/zoho/workdrive}
BAO_ADDR=${BAO_ADDR:-https://openbao.ricochet.rs}
ACCOUNTS_DOMAIN=${ZOHO_ACCOUNTS_DOMAIN:-https://accounts.zoho.com}
API_BASE=${ZOHO_WORKDRIVE_API_BASE:-https://workdrive.zoho.com/api/v1}

allow_download=true
emit_json=false
folder_id=${ZOHO_WORKDRIVE_FOLDER_ID:-}
link_name=

usage() {
    sed -n '3,8p' "$0" | cut -c 3-
    exit "${1:-0}"
}

die() {
    echo "zoho-share: $1" >&2
    exit 1
}

require() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is required but not installed"
}

# Read one field of the OpenBao secret, authenticating by AppRole when no token is set.
bao_field() {
    field=$1
    if [ -z "${BAO_TOKEN:-}" ]; then
        host=${BAO_ADDR#*://}
        host=${host%%/*}
        host=${host%%:*}
        cred_dir=${BAO_CRED_DIR:-$HOME/.config/openbao}/$host
        [ -r "$cred_dir/role_id" ] && [ -r "$cred_dir/secret_id" ] ||
            die "no OpenBao token and no AppRole credentials in $cred_dir"
        BAO_TOKEN=$(BAO_ADDR="$BAO_ADDR" bao write -field=token auth/approle/login \
            "role_id=$(cat "$cred_dir/role_id")" \
            "secret_id=$(cat "$cred_dir/secret_id")") ||
            die "OpenBao AppRole login failed against $BAO_ADDR"
        export BAO_TOKEN
    fi
    BAO_ADDR="$BAO_ADDR" bao kv get -field="$field" "$BAO_SECRET_PATH" 2>/dev/null ||
        die "field '$field' is missing from $BAO_SECRET_PATH on $BAO_ADDR (see skills/asset-sharing/setup.md)"
}

# Prefer an exported value so a local run can bypass OpenBao entirely.
credential() {
    env_name=$1
    field=$2
    eval "value=\${$env_name:-}"
    if [ -n "$value" ]; then
        printf '%s' "$value"
    else
        bao_field "$field"
    fi
}

# Exchange the long-lived refresh token for a one-hour access token.
mint_access_token() {
    response=$(curl -sS -X POST "$ACCOUNTS_DOMAIN/oauth/v2/token" \
        --data-urlencode "refresh_token=$refresh_token" \
        --data-urlencode "client_id=$client_id" \
        --data-urlencode "client_secret=$client_secret" \
        --data-urlencode "grant_type=refresh_token") ||
        die "token request to $ACCOUNTS_DOMAIN failed"

    token=$(printf '%s' "$response" | jq -r '.access_token // empty')
    [ -n "$token" ] ||
        die "no access token returned: $(printf '%s' "$response" | jq -c '.' 2>/dev/null || printf '%s' "$response")"
    printf '%s' "$token"
}

# WorkDrive nests the new file's id differently across response versions, so try each shape.
extract_resource_id() {
    printf '%s' "$1" | jq -r '
        [ .data[]?.attributes?
          | (."File INFO"? | if type == "string" then fromjson else . end)?.RESOURCE_ID?
          , .resource_id?
          , .Permalink?
        ] | map(select(. != null and . != "")) | first // empty'
}

while [ $# -gt 0 ]; do
    case $1 in
        --folder-id)
            [ $# -ge 2 ] || usage 1
            folder_id=$2
            shift 2
            ;;
        --name)
            [ $# -ge 2 ] || usage 1
            link_name=$2
            shift 2
            ;;
        --no-download)
            allow_download=false
            shift
            ;;
        --json)
            emit_json=true
            shift
            ;;
        -h | --help)
            usage 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            break
            ;;
    esac
done

[ $# -gt 0 ] || usage 1
require curl
require jq

for file in "$@"; do
    [ -f "$file" ] || die "no such file: $file"
done

client_id=$(credential ZOHO_WORKDRIVE_CLIENT_ID client_id)
client_secret=$(credential ZOHO_WORKDRIVE_CLIENT_SECRET client_secret)
refresh_token=$(credential ZOHO_WORKDRIVE_REFRESH_TOKEN refresh_token)
[ -n "$folder_id" ] || folder_id=$(credential ZOHO_WORKDRIVE_FOLDER_ID folder_id)

access_token=$(mint_access_token)

for file in "$@"; do
    base_name=$(basename "$file")

    upload=$(curl -sS -X POST "$API_BASE/upload" \
        -H "Authorization: Zoho-oauthtoken $access_token" \
        -H "Accept: application/vnd.api+json" \
        -F "parent_id=$folder_id" \
        -F "filename=$base_name" \
        -F "override-name-exist=true" \
        -F "content=@$file") ||
        die "upload of $base_name failed"

    resource_id=$(extract_resource_id "$upload")
    [ -n "$resource_id" ] ||
        die "upload of $base_name returned no resource id: $(printf '%s' "$upload" | head -c 400)"

    link_payload=$(jq -n \
        --arg resource_id "$resource_id" \
        --arg link_name "${link_name:-$base_name}" \
        --argjson allow_download "$allow_download" \
        '{data: {type: "links", attributes: {
            resource_id: $resource_id,
            link_name: $link_name,
            request_user_data: false,
            allow_download: $allow_download,
            role_id: "5"
        }}}')

    link=$(curl -sS -X POST "$API_BASE/links" \
        -H "Authorization: Zoho-oauthtoken $access_token" \
        -H "Accept: application/vnd.api+json" \
        -H "Content-Type: application/json" \
        -d "$link_payload") ||
        die "link creation for $base_name failed"

    url=$(printf '%s' "$link" | jq -r '.data.attributes.link // .data.attributes.Link // empty')
    [ -n "$url" ] ||
        die "no share link returned for $base_name: $(printf '%s' "$link" | head -c 400)"

    if [ "$emit_json" = true ]; then
        jq -n --arg file "$base_name" --arg resource_id "$resource_id" --arg url "$url" \
            '{file: $file, resource_id: $resource_id, url: $url}'
    else
        printf '%s\t%s\n' "$base_name" "$url"
    fi
done
