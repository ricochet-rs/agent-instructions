# Zoho WorkDrive uploader setup

One time setup for [scripts/zoho-share.sh](../../scripts/zoho-share.sh).
Every step here needs a person, because the agent AppRole can read OpenBao but never write it.

The secret lives at `saas/zoho/workdrive` on `openbao.ricochet.rs`, which is the uploader's default instance.
The account is on the US data center, so the hosts are `accounts.zoho.com` and `workdrive.zoho.com`.
Override `ZOHO_ACCOUNTS_DOMAIN` and `ZOHO_WORKDRIVE_API_BASE` if that ever changes.

## Create the OAuth client

1. Open the Zoho API console at `https://api-console.zoho.com`, choose **ADD CLIENT**, then **Self Client**, and confirm.
2. Copy the client ID and client secret from the **Client Secret** tab.
3. On the **Generate Code** tab, enter these scopes, set the duration to 10 minutes, add any description, and select the WorkDrive app and portal when prompted:

   ```text
   WorkDrive.files.CREATE,WorkDrive.links.CREATE,WorkDrive.links.READ
   ```

4. Exchange the grant token for a refresh token before the duration expires, because the code is single use:

   ```sh
   curl -X POST https://accounts.zoho.com/oauth/v2/token \
     -d grant_type=authorization_code \
     -d client_id=<CLIENT_ID> \
     -d client_secret=<CLIENT_SECRET> \
     -d code=<GRANT_TOKEN>
   ```

A self client needs no `redirect_uri`.
The response contains `refresh_token`, which does not expire.
The `access_token` in the same response lasts one hour and is not stored anywhere.
An `invalid_code` error means the grant token expired, so generate a new one and repeat this step.

## Find the destination folder

Create a dedicated Team Folder such as `agent-uploads` rather than using a personal My Folders location.
Every teammate can then browse, rename, and delete the accumulated assets, which nobody but the owner can do inside My Folders.
Everything the uploader writes gets a public link, so the folder should hold nothing else.

Open that folder in WorkDrive and copy the last path segment of the address bar, which is the value the uploader passes as `parent_id`.
A folder URL looks like `https://workdrive.zoho.com/home/<team>/teams/<team>/ws/<team folder id>/folders/<folder id>`, so the identifier to copy depends on whether the open folder is the Team Folder root or a subfolder.
A wrong identifier surfaces as a 404 on the first upload rather than failing silently.

Uploads always act as the account that generated the OAuth client, whoever runs the script.
Generate the client from an account that will outlive individual team members, because deleting that user kills the refresh token and stops every upload until someone repeats this setup.

## Store the secret

Write all four fields in one secret, so a rotation touches a single path:

```sh
bao kv put saas/zoho/workdrive \
  client_id=<CLIENT_ID> \
  client_secret=<CLIENT_SECRET> \
  refresh_token=<REFRESH_TOKEN> \
  folder_id=<FOLDER_ID>
```

Writing requires a policy with write capability, which `dev-ro` does not have.

## Verify

Run the uploader against a throwaway file and open the printed link in a private browser window.
Share links are served from `workdrive.zohoexternal.com`, not `workdrive.zoho.com`:

```sh
scripts/zoho-share.sh /tmp/hello.png
```

A `401` from the token endpoint means the refresh token was revoked or belongs to another data center.
A `404` on upload usually means the folder ID is wrong or the client's scopes are missing `WorkDrive.files.CREATE`.

## Rotation

Revoking the self client in the API console invalidates the refresh token immediately.
Rotate by repeating the steps above and overwriting the same OpenBao path.
