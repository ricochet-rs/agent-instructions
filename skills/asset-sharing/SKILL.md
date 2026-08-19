---
name: asset-sharing
description: Publish a screenshot, screencast, GIF, or other demo asset to Zoho WorkDrive and return a public link. Use when a change needs to be shown rather than described, such as illustrating a UI change in an issue or pull request, or sending a customer a recording of a feature.
---

# Asset sharing

Binary demo assets do not belong in a Git repository.
Upload them to the shared Zoho WorkDrive folder and reference the returned link.

Use this skill when a reviewer, an issue, or a customer needs to see the result rather than read about it.
Do not use it for files that belong in version control, such as source, fixtures, or documentation images that must survive independently of the WorkDrive account.

## Before the first upload

The uploader needs an OAuth client and a refresh token stored in OpenBao.
Read [setup.md](setup.md) when `zoho-share.sh` reports a missing credential.
Creating the client and writing the secret is a human step, because the agent AppRole is read only.

## Upload and share

Run the uploader from this repository:

```sh
# one asset, public link printed on stdout
scripts/zoho-share.sh docs/demo/login-flow.gif
```

```sh
# several assets, machine readable output
scripts/zoho-share.sh --json shot-before.png shot-after.png
```

The script prints one `filename<TAB>url` line per asset, or one JSON object per asset with `--json`.
It uploads to the default folder from the secret unless `--folder-id` names another one.

Useful flags:

| Flag | Effect |
|------|--------|
| `--folder-id ID` | Upload into a specific WorkDrive folder instead of the configured default. |
| `--name NAME` | Set the share link's display name instead of using the file name. |
| `--no-download` | Create a view only link that external viewers cannot download. |
| `--json` | Emit `{file, resource_id, url}` per asset for scripting. |

## Treat the link as public

The default link is viewable and downloadable by anyone who has the URL, without signing in.
Upload only material that is safe to hand to an outside reader.

Check the asset before uploading it.
Screenshots of a running instance routinely contain customer names, tokens in a URL, log output, and internal hostnames.
Crop or re-record rather than uploading and deleting afterwards, because a link that has been shared may already have been fetched.

## Name assets so they stay findable

Name each file for the work it documents, such as `1300-signin-required.png` or `1300-flow.gif`.
A folder of `screenshot-1.png` files becomes unusable within weeks.

Paste the returned URL into the issue or pull request with one sentence describing what it shows.
Verify the link resolves in a fresh session before relying on it, because a link created against the wrong folder still returns a URL.
