<#
.SYNOPSIS
    Initializes a Git repository and connects it to GitHub.

.DESCRIPTION
    Initializes a local Git repository, creates an initial commit, and 
    optionally creates and connects to a remote GitHub repository.

.PARAMETER RepositoryName
    Name of the GitHub repository to create.

.PARAMETER Description
    Description for the GitHub repository.

.PARAMETER Private
    Create a private repository. Default is public.

.PARAMETER SkipGitHubCreate
    Skip GitHub repository creation (only initialize local repo).

.PARAMETER Organization
    GitHub organization name (if creating in an org).

.EXAMPLE
    .\Initialize-Repository.ps1 -RepositoryName "adaptive-cloud-health-dashboard"

.EXAMPLE
    .\Initialize-Repository.ps1 -RepositoryName "my-dashboard" -Private -Organization "myorg"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "Adaptive Cloud Health Dashboard for Azure Local, AKS Arc, and Arc-enabled services",

    [Parameter(Mandatory = $false)]
    [switch]$Private,

    [Parameter(Mandatory = $false)]
    [switch]$SkipGitHubCreate,

    [Parameter(Mandatory = $false)]
    [string]$Organization
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "Initializing Git repository..." -ForegroundColor Cyan

    # Check if already a git repository
    $isGitRepo = Test-Path ".git"
    if ($isGitRepo) {
        Write-Warning "Already a Git repository"
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 0
        }
    } else {
        # Initialize git repository
        git init
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
    }

    # Configure git if not already configured
    $userName = git config user.name 2>&1
    if (-not $userName -or $LASTEXITCODE -ne 0) {
        $userName = Read-Host "Enter your Git username"
        git config user.name $userName
    }

    $userEmail = git config user.email 2>&1
    if (-not $userEmail -or $LASTEXITCODE -ne 0) {
        $userEmail = Read-Host "Enter your Git email"
        git config user.email $userEmail
    }

    Write-Host "✓ Git configured for user: $userName <$userEmail>" -ForegroundColor Green

    # Check if there are files to commit
    $files = git ls-files 2>&1
    if (-not $files -or $LASTEXITCODE -ne 0) {
        Write-Host "Staging initial files..." -ForegroundColor Yellow
        git add .
        
        Write-Host "Creating initial commit..." -ForegroundColor Yellow
        git commit -m "chore: Initial commit - Adaptive Cloud Health Dashboard"
        Write-Host "✓ Initial commit created" -ForegroundColor Green
    } else {
        Write-Host "Repository already has commits" -ForegroundColor Gray
    }

    # Create GitHub repository if requested
    if (-not $SkipGitHubCreate) {
        Write-Host ""
        Write-Host "Creating GitHub repository..." -ForegroundColor Cyan

        # Check if GitHub CLI is installed
        $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
        if (-not $ghInstalled) {
            Write-Warning "GitHub CLI (gh) is not installed"
            Write-Host "Install from: https://cli.github.com/"
            Write-Host ""
            Write-Host "After installing, run this script again or create repository manually:"
            Write-Host "  gh repo create $RepositoryName --public --description `"$Description`""
            exit 0
        }

        # Check GitHub authentication
        $ghAuth = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Authenticating with GitHub..." -ForegroundColor Yellow
            gh auth login
        }

        # Build gh repo create command
        $repoArgs = @("repo", "create", $RepositoryName)
        
        if ($Private) {
            $repoArgs += "--private"
        } else {
            $repoArgs += "--public"
        }

        $repoArgs += @("--description", $Description, "--source", ".")

        if ($Organization) {
            # Create in organization
            $repoFullName = "$Organization/$RepositoryName"
        } else {
            $repoFullName = $RepositoryName
        }

        Write-Host "Creating repository: $repoFullName" -ForegroundColor Gray
        & gh @repoArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ GitHub repository created" -ForegroundColor Green

            # Push to GitHub
            Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
            git push -u origin main

            Write-Host "✓ Repository pushed to GitHub" -ForegroundColor Green
        } else {
            Write-Warning "Failed to create GitHub repository"
            Write-Host "You can create it manually and add the remote:"
            Write-Host "  git remote add origin https://github.com/$repoFullName.git"
            Write-Host "  git push -u origin main"
        }
    } else {
        Write-Host ""
        Write-Host "Skipping GitHub repository creation" -ForegroundColor Gray
        Write-Host "To add remote later:"
        Write-Host "  git remote add origin <repository-url>"
        Write-Host "  git push -u origin main"
    }

    Write-Host ""
    Write-Host "✓ Repository initialization completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review and customize the dashboard templates"
    Write-Host "  2. Update configuration files with your environment details"
    Write-Host "  3. Deploy to Azure using deployment scripts"
    Write-Host ""
    Write-Host "See README.md for more information"

} catch {
    Write-Error "Failed to initialize repository: $_"
    exit 1
}
