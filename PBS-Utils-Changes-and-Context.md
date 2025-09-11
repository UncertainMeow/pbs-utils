Got it. I understand the frustration — you’ve been following step after step and then ran into version mismatches in PBS itself (your `proxmox-backup-manager` doesn’t support the `--output-format` flag).

Here’s a clean, **hand-off document** you can give your friend. It summarizes every change I suggested, why, and where it differs from stock PBS.

---

# PBS-Utils Changes & Context

## Problem

Original scripts in the repo used outdated commands:

* `proxmox-backup-manager token create … --privs …`
* `proxmox-backup-manager acl update … $USER … --privs …`

On newer PBS, these fail:

* `--privs` is not valid on `user generate-token`.
* ACLs expect a **role name** (`DatastoreBackup`, `DatastoreAudit`, etc.) and the subject set via `--auth-id`.

## Changes Made

### 1. `10-pbs-user-token.sh`

* **Before:**
  Used `user generate-token … --privs …` which caused `schema does not allow additional properties`.
* **After:**

  ```bash
  proxmox-backup-manager user generate-token "$PBS_USER" "$PBS_TOKEN_NAME"
  ```

  (We initially added `--output-format json-pretty` to parse with `jq`, but user’s PBS version does **not** support that option.)

**Why:**
To align with current PBS behavior — tokens don’t carry privileges. Output parsing was for convenience, but needs adjusting for this PBS version.

---

### 2. `30-pbs-acl.sh`

* **Before:**

  ```bash
  proxmox-backup-manager acl update "/datastore/$DS" "$PBS_USER" --privs "Datastore.Backup,Datastore.Audit"
  ```

  → passed a user where PBS expects a role.
* **After:**

  ```bash
  proxmox-backup-manager acl update "/datastore/$DS" DatastoreAudit  --auth-id "$AUTH_ID"
  proxmox-backup-manager acl update "/datastore/$DS" DatastoreBackup --auth-id "$AUTH_ID"
  ```

  with `AUTH_ID` set to `pve-backup@pbs!pve-token`.

**Why:**
PBS ACL model requires:

* positional arg = role name
* subject set with `--auth-id`.

---

### 3. `00-bootstrap.sh`

**Added new script** to install dependencies (`git`, `jq`, `openssl`) that aren’t present on a minimal PBS install.

---

### 4. `70-test.sh`

* Original called `proxmox-backup-client datastore …` which is not a valid client command.
* Suggested replacement:

  ```bash
  proxmox-backup-manager status
  proxmox-backup-manager datastore list
  ```

**Why:**
These are the correct server-side commands to test PBS health and datastore visibility.

---

### 5. General repo hygiene

* Added grep sanity checks to verify `--privs` was removed.
* Suggested writing `.pbs_token_create.out` even if the token already exists, so later scripts don’t break when PBS refuses to return a secret twice.
* Encouraged checking `00-env.sh` matches reality (`PBS_HOST`, `PBS_USER`, `PBS_TOKEN_NAME`, `DATASTORES`).

---

## Current Sticking Point

Your `proxmox-backup-manager` binary does **not** support `--output-format`. That flag was added in newer PBS builds. On your version:

* Run plain `proxmox-backup-manager user generate-token …`
* Parse output manually (or redirect to a file and copy/paste secret).

---

## Next Steps for Your Friend

1. **Check PBS version**:

   ```bash
   proxmox-backup-manager version
   ```

   Compare against docs to confirm supported flags.
2. **Adjust token script**: drop `--output-format json-pretty`. Capture secret from stdout.
3. **Verify ACLs**: confirm that roles (`DatastoreBackup`, `DatastoreAudit`) are assigned with `--auth-id`.
4. **Update repo**: decide if you want to keep JSON parsing (requires newer PBS) or stick with plain text parsing.
5. **Run flow again** in order:
   `05-preflight.sh → 10-pbs-user-token.sh → 30-pbs-acl.sh → 50/60/70`.

---

✅ **Summary**

* Removed invalid `--privs` usage.
* Corrected ACL syntax to use roles + `--auth-id`.
* Added bootstrap script for dependencies.
* Fixed test script to use valid commands.
* Remaining blocker is PBS version mismatch (`--output-format` not supported).

---

Would you like me to also include a *fallback version* of `10-pbs-user-token.sh` that works on **older PBS** (no `--output-format`, just tee the raw output), so your friend has both options?

