<#
.SYNOPSIS
    Commits changes with standardized commit messages.

.DESCRIPTION
    Stages and commits changes following Conventional Commits specification.
    Automatically formats commit messages for consistency.

.PARAMETER Message
    Commit message description.

.PARAMETER Type
    Type of change. Valid values:
    - feat: New feature
    - fix: Bug fix
    - docs: Documentation changes
    - style: Code style changes
    - refactor: Code refactoring
    - test: Test changes
    - chore: Maintenance tasks

.PARAMETER Scope
    Optional scope of the change (e.g., 'workbook', 'query', 'deployment').

.PARAMETER Files
    Specific files to stage. If not provided, stages all changes.

.PARAMETER SkipValidation
    Skip commit message validation.

.EXAMPLE
    .\Save-Changes.ps1 -Message "Add health score query" -Type "feat"

.EXAMPLE
    .\Save-Changes.ps1 -Message "Fix typo in documentation" -Type "docs" -Scope "readme"

.EXAMPLE
    .\Save-Changes.ps1 -Message "Update workbook template" -Type "feat" -Files "src/workbooks/health.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter(Mandatory = $true)]
    [ValidateSet("feat", "fix", "docs", "style", "refactor", "test", "chore")]
    [string]$Type,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [string[]]$Files,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"

function Format-CommitMessage {
    param(
        [string]$Type,
        [string]$Scope,
        [string]$Message
    )

    if ($Scope) {
        return "${Type}(${Scope}): ${Message}"
    } else {
        return "${Type}: ${Message}"
    }
}

try {
    # Ensure we're in a git repository
    $gitRoot = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # Check for changes
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "No changes to commit" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Staging changes..." -ForegroundColor Cyan

    # Stage files
    if ($Files) {
        foreach ($file in $Files) {
            if (Test-Path $file) {
                git add $file
                Write-Host "  ✓ Staged: $file" -ForegroundColor Green
            } else {
                Write-Warning "File not found: $file"
            }
        }
    } else {
        git add -A
        Write-Host "  ✓ Staged all changes" -ForegroundColor Green
    }

    # Format commit message
    $commitMessage = Format-CommitMessage -Type $Type -Scope $Scope -Message $Message

    # Validate message length
    if (-not $SkipValidation) {
        if ($commitMessage.Length -gt 100) {
            Write-Warning "Commit message is longer than 100 characters ($($commitMessage.Length))"
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne 'y') {
                exit 1
            }
        }
    }

    # Show what will be committed
    Write-Host ""
    Write-Host "Changes to be committed:" -ForegroundColor Yellow
    git diff --cached --stat
    Write-Host ""

    # Commit
    Write-Host "Creating commit..." -ForegroundColor Cyan
    Write-Host "Message: $commitMessage" -ForegroundColor Gray
    git commit -m $commitMessage

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Changes committed successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "Commit hash: $(git rev-parse --short HEAD)" -ForegroundColor Gray
        Write-Host "Branch: $(git branch --show-current)" -ForegroundColor Gray
    } else {
        throw "Commit failed"
    }

} catch {
    Write-Error "Failed to commit changes: $_"
    exit 1
}
