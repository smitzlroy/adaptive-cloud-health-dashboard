<#
.SYNOPSIS
    Syncs local repository with remote changes.

.DESCRIPTION
    Fetches changes from remote repository and merges them into the current branch.
    Handles merge conflicts and provides options for rebasing.

.PARAMETER Rebase
    Use rebase instead of merge when pulling changes.

.PARAMETER Stash
    Automatically stash uncommitted changes before pulling.

.PARAMETER Branch
    Specific branch to sync. Default is current branch.

.EXAMPLE
    .\Sync-Repository.ps1

.EXAMPLE
    .\Sync-Repository.ps1 -Rebase -Stash

.EXAMPLE
    .\Sync-Repository.ps1 -Branch "main"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Rebase,

    [Parameter(Mandatory = $false)]
    [switch]$Stash,

    [Parameter(Mandatory = $false)]
    [string]$Branch
)

$ErrorActionPreference = "Stop"

try {
    # Ensure we're in a git repository
    $gitRoot = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # Get current branch if not specified
    if (-not $Branch) {
        $Branch = git branch --show-current
    }

    Write-Host "Syncing branch: $Branch" -ForegroundColor Cyan

    # Check for uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Warning "You have uncommitted changes"
        
        if ($Stash) {
            Write-Host "Stashing changes..." -ForegroundColor Yellow
            git stash push -m "Auto-stash before sync $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Write-Host "✓ Changes stashed" -ForegroundColor Green
            $hasStash = $true
        } else {
            Write-Host "Uncommitted changes:" -ForegroundColor Yellow
            git status --short
            Write-Host ""
            $continue = Read-Host "Continue without stashing? (y/n)"
            if ($continue -ne 'y') {
                exit 0
            }
        }
    }

    # Fetch remote changes
    Write-Host "Fetching remote changes..." -ForegroundColor Yellow
    git fetch origin

    # Check if remote branch exists
    $remoteBranch = git rev-parse --verify "origin/$Branch" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Remote branch 'origin/$Branch' does not exist"
        exit 0
    }

    # Check if behind remote
    $behindCount = git rev-list --count HEAD..origin/$Branch 2>&1
    if ($LASTEXITCODE -ne 0 -or $behindCount -eq 0) {
        Write-Host "✓ Already up to date" -ForegroundColor Green
        
        if ($hasStash) {
            Write-Host "Restoring stashed changes..." -ForegroundColor Yellow
            git stash pop
            Write-Host "✓ Changes restored" -ForegroundColor Green
        }
        
        exit 0
    }

    Write-Host "Branch is $behindCount commit(s) behind remote" -ForegroundColor Yellow

    # Pull changes
    Write-Host "Pulling changes..." -ForegroundColor Cyan

    if ($Rebase) {
        git pull --rebase origin $Branch
    } else {
        git pull origin $Branch
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Successfully synced with remote" -ForegroundColor Green
    } else {
        Write-Warning "Merge conflicts detected"
        Write-Host ""
        Write-Host "Conflicted files:" -ForegroundColor Yellow
        git diff --name-only --diff-filter=U
        Write-Host ""
        Write-Host "Resolve conflicts manually, then run:" -ForegroundColor Cyan
        Write-Host "  git add <resolved-files>"
        if ($Rebase) {
            Write-Host "  git rebase --continue"
        } else {
            Write-Host "  git commit"
        }
        exit 1
    }

    # Restore stash if needed
    if ($hasStash) {
        Write-Host "Restoring stashed changes..." -ForegroundColor Yellow
        git stash pop
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Changes restored" -ForegroundColor Green
        } else {
            Write-Warning "Conflicts while restoring stash"
            Write-Host "Resolve conflicts manually"
        }
    }

    Write-Host ""
    Write-Host "✓ Repository synced successfully" -ForegroundColor Green

} catch {
    Write-Error "Failed to sync repository: $_"
    exit 1
}
