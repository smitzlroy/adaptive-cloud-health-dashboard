# Git Automation Scripts

This directory contains PowerShell scripts to automate common Git workflows for the Adaptive Cloud Health Dashboard project.

## Available Scripts

### 1. Initialize-Repository.ps1
**Purpose**: Initialize a new Git repository and optionally create GitHub repository.

**Usage**:
```powershell
.\Initialize-Repository.ps1 -RepositoryName "adaptive-cloud-health-dashboard"
.\Initialize-Repository.ps1 -RepositoryName "my-dashboard" -Private -Organization "myorg"
```

**Features**:
- Initializes local Git repository
- Creates initial commit
- Creates GitHub repository (requires GitHub CLI)
- Sets up remote connection
- Pushes initial code

### 2. New-FeatureBranch.ps1
**Purpose**: Create a new feature or development branch.

**Usage**:
```powershell
.\New-FeatureBranch.ps1 -BranchName "feature/add-new-query"
.\New-FeatureBranch.ps1 -BranchName "bugfix/fix-chart" -Push
```

**Features**:
- Creates branch from main (or specified base)
- Validates branch naming convention
- Optionally pushes to remote
- Automatically switches to new branch

**Naming Conventions**:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Urgent fixes
- `custom/` - Organization-specific customizations
- `docs/` - Documentation changes

### 3. Save-Changes.ps1
**Purpose**: Stage and commit changes with standardized commit messages.

**Usage**:
```powershell
.\Save-Changes.ps1 -Message "Add health score query" -Type "feat"
.\Save-Changes.ps1 -Message "Fix typo" -Type "docs" -Scope "readme"
.\Save-Changes.ps1 -Message "Update template" -Type "feat" -Files "src/workbooks/health.json"
```

**Features**:
- Follows Conventional Commits specification
- Stages specific files or all changes
- Validates commit message format
- Shows preview of changes

**Commit Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code formatting
- `refactor` - Code refactoring
- `test` - Adding tests
- `chore` - Maintenance tasks

**Commit Message Format**:
```
<type>(<scope>): <message>

Examples:
feat: Add capacity forecasting
fix(workbook): Correct health score calculation
docs: Update setup instructions
```

### 4. Publish-Changes.ps1
**Purpose**: Push commits to remote and optionally create pull request.

**Usage**:
```powershell
.\Publish-Changes.ps1
.\Publish-Changes.ps1 -CreatePR -PRTitle "Add new dashboard"
.\Publish-Changes.ps1 -Force -SetUpstream
```

**Features**:
- Pushes commits to remote repository
- Creates pull request (requires GitHub CLI)
- Sets upstream tracking
- Shows list of commits to be pushed

**Pull Request Creation**:
```powershell
# Auto-generate PR from commit message
.\Publish-Changes.ps1 -CreatePR

# Specify PR details
.\Publish-Changes.ps1 -CreatePR -PRTitle "New Feature" -PRBody "Description"
```

### 5. Sync-Repository.ps1
**Purpose**: Sync local repository with remote changes.

**Usage**:
```powershell
.\Sync-Repository.ps1
.\Sync-Repository.ps1 -Rebase
.\Sync-Repository.ps1 -Stash -Branch "main"
```

**Features**:
- Fetches remote changes
- Merges or rebases changes
- Automatically stashes uncommitted changes
- Handles merge conflicts

**Conflict Resolution**:
If conflicts occur:
1. Script will notify you
2. Resolve conflicts manually
3. Run `git add <files>`
4. Run `git commit` or `git rebase --continue`

## Complete Workflow Example

### Starting New Feature

```powershell
# 1. Create feature branch
.\New-FeatureBranch.ps1 -BranchName "feature/predictive-analytics"

# 2. Make your changes to files
# ... edit files ...

# 3. Commit changes
.\Save-Changes.ps1 -Message "Add predictive analytics query" -Type "feat" -Scope "queries"

# 4. Continue working
# ... more edits ...

# 5. Commit more changes
.\Save-Changes.ps1 -Message "Add visualization for forecast" -Type "feat" -Scope "workbook"

# 6. Push to remote and create PR
.\Publish-Changes.ps1 -CreatePR -PRTitle "Add Predictive Analytics Dashboard"
```

### Keeping Branch Updated

```powershell
# Sync with main branch
git checkout main
.\Sync-Repository.ps1

# Update feature branch
git checkout feature/my-feature
git merge main
# Or: git rebase main
```

### Hotfix Workflow

```powershell
# 1. Create hotfix branch from main
.\New-FeatureBranch.ps1 -BranchName "hotfix/urgent-fix" -FromBranch "main"

# 2. Make fix
# ... edit files ...

# 3. Commit
.\Save-Changes.ps1 -Message "Fix critical bug" -Type "fix"

# 4. Push immediately
.\Publish-Changes.ps1 -CreatePR -PRTitle "URGENT: Fix Critical Bug"
```

## GitHub CLI Setup

Several scripts use GitHub CLI (`gh`) for enhanced functionality:

### Installation

**Windows**:
```powershell
winget install GitHub.cli
```

**macOS**:
```bash
brew install gh
```

**Linux**:
```bash
# Debian/Ubuntu
sudo apt install gh

# RHEL/CentOS
sudo yum install gh
```

### Authentication

```powershell
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

## Best Practices

### 1. Commit Frequently
- Make small, focused commits
- Each commit should represent one logical change
- Makes code review easier

### 2. Write Clear Messages
- Use descriptive commit messages
- Follow the commit type conventions
- Include context when necessary

### 3. Keep Branches Updated
- Regularly sync with main branch
- Resolve conflicts early
- Don't let branches diverge too much

### 4. Review Before Pushing
- Check the diff before committing
- Test your changes locally
- Ensure no sensitive data is committed

### 5. Use Pull Requests
- Create PRs for all changes
- Request reviews from team members
- Link PRs to issues

## Troubleshooting

### Issue: "Not in a Git repository"
**Solution**: Run from project root directory

### Issue: GitHub CLI not found
**Solution**: Install GitHub CLI from https://cli.github.com/

### Issue: Authentication failed
**Solution**: Run `gh auth login` to authenticate

### Issue: Merge conflicts
**Solution**: 
1. Manually resolve conflicts in files
2. Stage resolved files: `git add <file>`
3. Continue merge/rebase: `git commit` or `git rebase --continue`

### Issue: Accidentally committed sensitive data
**Solution**:
```powershell
# Remove from last commit
git rm --cached <file>
git commit --amend

# If already pushed, contact team lead
```

## Advanced Usage

### Custom Commit Scopes

Add custom scopes to your commits:
```powershell
.\Save-Changes.ps1 -Message "Update CPU threshold" -Type "refactor" -Scope "health-query"
```

### Force Push (Use with Caution)

```powershell
.\Publish-Changes.ps1 -Force
```
⚠️ **Warning**: Only force push if you're certain it won't affect others.

### Batch Operations

```powershell
# Commit multiple types of changes separately
.\Save-Changes.ps1 -Message "Add new query" -Type "feat" -Files "src/queries/new.kql"
.\Save-Changes.ps1 -Message "Update docs" -Type "docs" -Files "docs/README.md"
```

## Integration with IDEs

### Visual Studio Code

Add these tasks to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Git: Commit Changes",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-File",
        "${workspaceFolder}/scripts/git/Save-Changes.ps1"
      ]
    }
  ]
}
```

## Contributing

When contributing to the Git automation scripts:
1. Test thoroughly before submitting
2. Update this README with new features
3. Follow PowerShell best practices
4. Add parameter validation
5. Include helpful error messages

---

For more information, see the [Contributing Guide](../../CONTRIBUTING.md).
