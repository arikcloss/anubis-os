# Signing Setup for Anubis OS

## Overview

This repository uses **cosign** (via BlueBuild's signing module) to sign container images. This enables:

- **Verified updates**: Users can verify image integrity with `cosign verify`
- **Supply chain security**: Signed images prevent tampering
- **Easy updates**: `rpm-ostree` trusts signed images from this registry

## Prerequisites

1. **cosign** installed locally: `brew install cosign` or download from releases
2. **GitHub repository** with Actions enabled
3. **Container registry** (GHCR) with write permissions

## One-Time Setup

### 1. Generate Keypair

```bash
cosign generate-key-pair
```

This creates:
- `cosign.key` — **PRIVATE KEY** (never commit this!)
- `cosign.pub` — **PUBLIC KEY** (commit to repo root)

### 2. Add Public Key to Repo

```bash
cp cosign.pub /path/to/anubis-os/
git add cosign.pub
git commit -m "Add cosign public key for image signing"
git push
```

### 3. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|-------------|-------|
| `COSIGN_PRIVATE_KEY` | Contents of `cosign.key` (including `-----BEGIN ENCRYPTED COSIGN PRIVATE KEY-----`) |
| `COSIGN_PASSWORD` | The password you set during `cosign generate-key-pair` |

### 4. Verify Workflow

The `.github/workflows/build.yml` already includes the signing step. Push to `main` and check the Actions log for "Signing image" step.

## Local Builds (Unsigned)

For local testing without signing:

```bash
bluebuild build recipes/recipe.yml --no-sign
```

## Verifying Signed Images

```bash
# Verify latest image
cosign verify ghcr.io/arikcloss/anubis-os:latest \
  --key cosign.pub

# Verify specific digest
cosign verify ghcr.io/arikcloss/anubis-os@sha256:... \
  --key cosign.pub
```

## Key Rotation

To rotate keys:

1. Generate new keypair
2. Update `cosign.pub` in repo
3. Update GitHub secrets
4. Rebuild images

Old signatures remain valid for images signed with the old key.