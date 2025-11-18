# GitHub Actions Workflows

This repository uses GitHub Actions to automate quality checks and publishing.

## Workflows

### 1. Validate Script (`validate-script.yml`)

**Triggers:**
- On pull requests to `main` or `dev`
- On pushes to `main` or `dev`

**What it does:**
- ✅ Tests PowerShell syntax
- ✅ Validates PSScriptInfo metadata
- ✅ Checks script can be parsed
- ✅ Ensures version format is correct

**Purpose:** Catch issues early before merging

---

### 2. Publish to PowerShell Gallery (`publish-to-psgallery.yml`)

**Triggers:**
- When a GitHub Release is published
- Can be manually triggered from Actions tab

**What it does:**
- ✅ Validates version matches the release tag
- ✅ Publishes script to PowerShell Gallery
- ✅ Verifies publication succeeded

**Purpose:** Automate PSGallery publishing on release

---

## Setup Instructions

### 1. Add PSGallery API Key to GitHub Secrets

1. Get your API key from: https://www.powershellgallery.com/account/apikeys
2. Go to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `PSGALLERY_API_KEY`
5. Value: [Your API Key]
6. Click **Add secret**

### 2. Release Workflow

```powershell
# 1. Update version in Get-IntuneAssignments.ps1
# Edit: .VERSION 1.0.14 → .VERSION 1.0.15

# 2. Commit and push to dev
git add Get-IntuneAssignments.ps1
git commit -m "Bump version to 1.0.15"
git push origin dev

# 3. Create PR: dev → main
# GitHub will run validation workflow

# 4. Merge PR to main

# 5. Create GitHub Release
# Go to: https://github.com/amirjs/Get-IntuneAssignments/releases/new
# - Tag: v1.0.15
# - Target: main
# - Title: v1.0.15 - [Description]
# - Release notes: Copy from .RELEASENOTES
# - Click "Publish release"

# 6. GitHub Action automatically publishes to PSGallery! 🚀
```

### 3. Manual Publishing (if needed)

If the automated workflow fails, you can manually trigger it:

1. Go to: **Actions** → **Publish to PowerShell Gallery**
2. Click **Run workflow**
3. Select branch: `main`
4. Click **Run workflow**

Or publish locally:
```powershell
git checkout main
git pull origin main
Publish-Script -Path ".\Get-IntuneAssignments.ps1" -NuGetApiKey "YOUR-KEY" -Verbose
```

---

## Status Badges

Add these to your README.md to show workflow status:

```markdown
[![Validate Script](https://github.com/amirjs/Get-IntuneAssignments/actions/workflows/validate-script.yml/badge.svg)](https://github.com/amirjs/Get-IntuneAssignments/actions/workflows/validate-script.yml)
[![Publish to PSGallery](https://github.com/amirjs/Get-IntuneAssignments/actions/workflows/publish-to-psgallery.yml/badge.svg)](https://github.com/amirjs/Get-IntuneAssignments/actions/workflows/publish-to-psgallery.yml)
```

---

## Troubleshooting

### Workflow fails with "Version mismatch"
- Ensure the version in `.VERSION` matches the Git tag (without the 'v' prefix)
- Example: Tag `v1.0.15` should match `.VERSION 1.0.15`

### Workflow fails with "unauthorized" or API key error
- Check that `PSGALLERY_API_KEY` secret is set correctly
- Verify the API key hasn't expired
- Generate a new API key if needed

### Script published but not showing on PSGallery
- PSGallery indexing can take 5-15 minutes
- Check: https://www.powershellgallery.com/packages/Get-IntuneAssignments
- Refresh after a few minutes

---

## Benefits

✅ **Automated publishing** - No manual steps after creating release  
✅ **Version validation** - Prevents mismatched versions  
✅ **Quality checks** - Catches syntax errors before merge  
✅ **Consistent process** - Same steps every release  
✅ **Audit trail** - All publishes logged in Actions tab  
