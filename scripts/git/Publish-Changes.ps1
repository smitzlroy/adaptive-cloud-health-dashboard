<#
.SYNOPSIS
    Pushes local commits to remote repository and optionally creates a pull request.

.DESCRIPTION
    Pushes committed changes to the remote repository. Can optionally create 
    a pull request using GitHub CLI (gh).

.PARAMETER Force
    Force push to remote (use with caution).

.PARAMETER CreatePR
    Create a pull request after pushing.

.PARAMETER PRTitle
    Title for the pull request. If not specified, uses the last commit message.

.PARAMETER PRBody
    Description for the pull request.

.PARAMETER SetUpstream
    Set upstream tracking for the branch.

.EXAMPLE
    .\Publish-Changes.ps1

.EXAMPLE
    .\Publish-Changes.ps1 -CreatePR -PRTitle "Add new health dashboard"

.EXAMPLE
    .\Publish-Changes.ps1 -Force -SetUpstream
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$CreatePR,

    [Parameter(Mandatory = $false)]
    [string]$PRTitle,

    [Parameter(Mandatory = $false)]
    [string]$PRBody,

    [Parameter(Mandatory = $false)]
    [switch]$SetUpstream
)

$ErrorActionPreference = "Stop"

try {
    # Ensure we're in a git repository
    $gitRoot = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a Git repository"
    }

    # Get current branch
    $currentBranch = git branch --show-current
    Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

    # Check if there are commits to push
    $unpushedCommits = git log origin/$currentBranch..$currentBranch --oneline 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Branch not yet pushed to remote. Setting upstream..." -ForegroundColor Yellow
        $SetUpstream = $true
    } elseif (-not $unpushedCommits) {
        Write-Host "No commits to push" -ForegroundColor Yellow
        if (-not $CreatePR) {
            exit 0
        }
    } else {
        Write-Host ""
        Write-Host "Commits to be pushed:" -ForegroundColor Yellow
        Write-Host $unpushedCommits
        Write-Host ""
    }

    # Push commits
    Write-Host "Pushing to remote..." -ForegroundColor Cyan

    $pushArgs = @("push")
    
    if ($SetUpstream) {
        $pushArgs += @("--set-upstream", "origin", $currentBranch)
    }
    
    if ($Force) {
        Write-Warning "Force pushing to remote!"
        $confirm = Read-Host "Are you sure? (y/n)"
        if ($confirm -ne 'y') {
            exit 1
        }
        $pushArgs += "--force"
    }

    & git @pushArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Changes pushed successfully" -ForegroundColor Green
    } else {
        throw "Push failed"
    }

    # Create pull request if requested
    if ($CreatePR) {
        Write-Host ""
        Write-Host "Creating pull request..." -ForegroundColor Cyan

        # Check if GitHub CLI is installed
        $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
        if (-not $ghInstalled) {
            Write-Warning "GitHub CLI (gh) is not installed"
            Write-Host "Install from: https://cli.github.com/"
            Write-Host "Or create PR manually at: https://github.com/your-org/adaptive-cloud-health-dashboard/pull/new/$currentBranch"
            exit 0
        }

        # Get PR title from last commit if not provided
        if (-not $PRTitle) {
            $PRTitle = git log -1 --pretty=%s
            Write-Host "Using commit message as PR title: $PRTitle" -ForegroundColor Gray
        }

        # Create PR
        $prArgs = @("pr", "create", "--title", $PRTitle, "--base", "main")
        
        if ($PRBody) {
            $prArgs += @("--body", $PRBody)
        } else {
            $prArgs += "--fill"
        }

        & gh @prArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Pull request created successfully" -ForegroundColor Green
        } else {
            Write-Warning "Failed to create pull request"
        }
    }

    Write-Host ""
    Write-Host "✓ Publish completed" -ForegroundColor Green

} catch {
    Write-Error "Failed to publish changes: $_"
    exit 1
}
