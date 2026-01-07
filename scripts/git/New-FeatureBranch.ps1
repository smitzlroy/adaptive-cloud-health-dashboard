<#
.SYNOPSIS
    Creates a new feature branch for development.

.DESCRIPTION
    Creates a new Git branch from the current branch (typically main) and 
    optionally pushes it to the remote repository.

.PARAMETER BranchName
    Name of the new branch to create. Should follow naming convention:
    - feature/description
    - bugfix/description
    - hotfix/description
    - custom/org-name

.PARAMETER Push
    If specified, pushes the new branch to remote repository.

.PARAMETER FromBranch
    Base branch to create from. Default is 'main'.

.EXAMPLE
    .\New-FeatureBranch.ps1 -BranchName "feature/add-new-query"

.EXAMPLE
    .\New-FeatureBranch.ps1 -BranchName "custom/contoso" -Push
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    [Parameter(Mandatory = $false)]
    [switch]$Push,

    [Parameter(Mandatory = $false)]
    [string]$FromBranch = "main"
)

$ErrorActionPreference = "Stop"

# Validate branch name format
$validPrefixes = @("feature/", "bugfix/", "hotfix/", "custom/", "docs/", "test/")
$hasValidPrefix = $false

foreach ($prefix in $validPrefixes) {
    if ($BranchName.StartsWith($prefix)) {
        $hasValidPrefix = $true
        break
    }
}

if (-not $hasValidPrefix) {
    Write-Warning "Branch name should start with one of: $($validPrefixes -join ', ')"
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
}

try {
    Write-Host "Creating new branch: $BranchName" -ForegroundColor Cyan

    # Ensure we're in a git repository
    $gitRoot = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # Check if branch already exists
    $branchExists = git branch --list $BranchName
    if ($branchExists) {
        Write-Error "Branch '$BranchName' already exists"
        exit 1
    }

    # Fetch latest changes
    Write-Host "Fetching latest changes..." -ForegroundColor Yellow
    git fetch origin

    # Ensure we're on the base branch
    Write-Host "Switching to base branch: $FromBranch" -ForegroundColor Yellow
    git checkout $FromBranch

    # Pull latest changes
    Write-Host "Pulling latest changes..." -ForegroundColor Yellow
    git pull origin $FromBranch

    # Create new branch
    Write-Host "Creating branch: $BranchName" -ForegroundColor Green
    git checkout -b $BranchName

    Write-Host "✓ Branch created successfully" -ForegroundColor Green

    # Push to remote if requested
    if ($Push) {
        Write-Host "Pushing branch to remote..." -ForegroundColor Yellow
        git push -u origin $BranchName
        Write-Host "✓ Branch pushed to remote" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Branch '$BranchName' is ready for development!" -ForegroundColor Cyan
    Write-Host "Current branch: $(git branch --show-current)" -ForegroundColor Gray

} catch {
    Write-Error "Failed to create branch: $_"
    exit 1
}
