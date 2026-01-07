<#
.SYNOPSIS
    Deploy FULL Adaptive Cloud Health Dashboard (with Performance & Health Monitoring)

.DESCRIPTION
    ⚠️ WARNING: This deployment CREATES PAID RESOURCES and REQUIRES agents on all monitored resources.
    
    Deploys:
    - Log Analytics workspace (COSTS MONEY based on data ingestion)
    - Data Collection Rules
    - Full dashboard workbook with performance metrics
    
    REQUIREMENTS:
    - Azure Monitor Agent must be installed on all resources you want to monitor
    - Data ingestion costs: ~$2.30/GB
    - Typical cost: $100-500/month for small-medium environments
    
    For FREE inventory-only dashboard (no agents), use: Deploy-Inventory-Dashboard.ps1

.PARAMETER ConfigFile
    Path to configuration file (default: .\config.json)

.PARAMETER SkipWorkbooks
    Skip workbook import (only deploy infrastructure)

.PARAMETER TestMode
    Show what would be deployed without actually deploying (dry run)

.EXAMPLE
    .\Deploy-Full-Dashboard.ps1
    
.EXAMPLE
    .\Deploy-Full-Dashboard.ps1 -ConfigFile .\my-config.json

.EXAMPLE
    .\Deploy-Full-Dashboard.ps1 -TestMode
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = ".\config.json",

    [Parameter(Mandatory = $false)]
    [switch]$SkipWorkbooks,

    [Parameter(Mandatory = $false)]
    [switch]$TestMode
)

$ErrorActionPreference = "Stop"

#region Helper Functions

function Write-Log {
    param(
        [string]$Message, 
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Test-AzureCLI {
    $azInstalled = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azInstalled) {
        throw "Azure CLI is not installed. Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    }
    
    # Test if logged in
    $account = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in to Azure. Run 'az login' first."
    }
}

function Show-DeploymentSummary {
    param($Config, $WorkspaceId)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Deployment Completed Successfully!   " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resources Deployed:" -ForegroundColor Cyan
    Write-Host "  📦 Resource Group:    $($Config.resourceGroup)" -ForegroundColor White
    Write-Host "  📊 Log Analytics:     $($Config.logAnalytics.name)" -ForegroundColor White
    Write-Host "  🔑 Workspace ID:      $WorkspaceId" -ForegroundColor White
    Write-Host "  🌍 Location:          $($Config.location)" -ForegroundColor White
    Write-Host "  📋 Subscriptions:     $($Config.subscriptions.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure data collection on your resources:" -ForegroundColor White
    Write-Host "     • Azure Local clusters" -ForegroundColor Gray
    Write-Host "     • AKS Arc clusters" -ForegroundColor Gray
    Write-Host "     • Arc-enabled servers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Access your dashboard:" -ForegroundColor White
    Write-Host "     🌐 https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  3. Review documentation:" -ForegroundColor White
    Write-Host "     📚 docs/setup/SETUP.md" -ForegroundColor Gray
    Write-Host ""
}

#endregion

#region Main Script

try {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  ⚠️  FULL DASHBOARD DEPLOYMENT - COSTS APPLY  ⚠️      " -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This will create:" -ForegroundColor White
    Write-Host "  💰 Log Analytics Workspace (pay-per-GB ingestion)" -ForegroundColor Yellow
    Write-Host "  📊 Data Collection Rules" -ForegroundColor White
    Write-Host "  📈 Full Performance & Health Dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "REQUIREMENTS after deployment:" -ForegroundColor Red
    Write-Host "  ❗ Azure Monitor Agent on ALL monitored resources" -ForegroundColor Red
    Write-Host "  ❗ Data ingestion costs: ~$2.30/GB" -ForegroundColor Red
    Write-Host "  ❗ Estimated: $100-500+/month depending on scale" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Deploy-Inventory-Dashboard.ps1 (FREE)" -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "Do you want to continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
    
    Write-Log "🚀 Starting Adaptive Cloud Health Dashboard Deployment" -Level "Info"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level "Info"
    Write-Host ""

    # Step 1: Validate Prerequisites
    Write-Log "Step 1/6: Validating prerequisites..." -Level "Info"
    Test-AzureCLI
    Write-Log "✓ Azure CLI is installed and authenticated" -Level "Success"

    # Step 2: Load Configuration
    Write-Log "Step 2/6: Loading configuration..." -Level "Info"
    
    if (-not (Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile`nPlease copy config.template.json to config.json and edit with your details."
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Log "✓ Configuration loaded successfully" -Level "Success"
    Write-Log "  Target subscription: $($config.subscriptions[0])" -Level "Info"
    Write-Log "  Resource group: $($config.resourceGroup)" -Level "Info"
    Write-Log "  Location: $($config.location)" -Level "Info"

    if ($TestMode) {
        Write-Log "TestMode - no changes will be made" -Level "Warning"
        Write-Host ""
        Write-Host "Would deploy:" -ForegroundColor Yellow
        Write-Host "  • Resource Group: $($config.resourceGroup)" -ForegroundColor Gray
        Write-Host "  • Log Analytics: $($config.logAnalytics.name)" -ForegroundColor Gray
        Write-Host "  • Data Collection Rules" -ForegroundColor Gray
        Write-Host "  • Azure Workbooks" -ForegroundColor Gray
        return
    }

    # Step 3: Set Azure Subscription
    Write-Log "Step 3/6: Setting Azure subscription..." -Level "Info"
    az account set --subscription $config.subscriptions[0]
    
    $currentSub = az account show --query name -o tsv
    Write-Log "✓ Using subscription: $currentSub" -Level "Success"

    # Step 4: Deploy Azure Resources
    Write-Log "Step 4/6: Deploying Azure resources..." -Level "Info"
    
    # Create Resource Group
    Write-Log "  Creating resource group..." -Level "Info"
    az group create `
        --name $config.resourceGroup `
        --location $config.location `
        --tags environment=$($config.tags.environment) solution=$($config.tags.solution) `
        --output none
    Write-Log "  ✓ Resource group created" -Level "Success"

    # Create Log Analytics Workspace
    Write-Log "  Creating Log Analytics workspace..." -Level "Info"
    $workspace = az monitor log-analytics workspace create `
        --resource-group $config.resourceGroup `
        --workspace-name $config.logAnalytics.name `
        --location $config.location `
        --sku $config.logAnalytics.sku `
        --retention-time $config.logAnalytics.retentionDays `
        --query "{id:id, customerId:customerId}" `
        -o json | ConvertFrom-Json

    if (-not $workspace) {
        throw "Failed to create Log Analytics workspace"
    }
    Write-Log "  ✓ Log Analytics workspace created" -Level "Success"
    Write-Log "    Workspace ID: $($workspace.customerId)" -Level "Info"

    # Enable Solutions (optional, continue on error)
    Write-Log "  Enabling monitoring solutions..." -Level "Info"
    $solutions = @("Updates", "Security", "ChangeTracking", "AzureActivity")
    
    foreach ($solution in $solutions) {
        try {
            az monitor log-analytics solution create `
                --resource-group $config.resourceGroup `
                --solution-type $solution `
                --workspace $config.logAnalytics.name `
                --no-wait `
                --output none 2>$null
            Write-Log "    ✓ $solution queued" -Level "Info"
        } catch {
            Write-Log "    ⚠ Could not enable $solution (may already exist)" -Level "Warning"
        }
    }

    # Create Data Collection Rule
    Write-Log "  Creating data collection rule..." -Level "Info"
    
    $dcrName = "dcr-adaptive-cloud"
    $dcrConfig = @{
        location = $config.location
        properties = @{
            dataSources = @{
                performanceCounters = @(
                    @{
                        name = "perfCounterDataSource"
                        samplingFrequencyInSeconds = 60
                        streams = @("Microsoft-Perf")
                        counterSpecifiers = @(
                            "\\Processor(_Total)\\% Processor Time",
                            "\\Memory\\Available MBytes",
                            "\\LogicalDisk(_Total)\\% Free Space",
                            "\\Network Interface(*)\\Bytes Total/sec"
                        )
                    }
                )
                windowsEventLogs = @(
                    @{
                        name = "eventLogsDataSource"
                        streams = @("Microsoft-Event")
                        xPathQueries = @(
                            "System!*[System[(Level=1 or Level=2 or Level=3)]]",
                            "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
                        )
                    }
                )
            }
            destinations = @{
                logAnalytics = @(
                    @{
                        workspaceResourceId = $workspace.id
                        name = "law-destination"
                    }
                )
            }
            dataFlows = @(
                @{
                    streams = @("Microsoft-Perf", "Microsoft-Event")
                    destinations = @("law-destination")
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    $dcrFile = "$env:TEMP\dcr-config-$(Get-Random).json"
    $dcrConfig | Out-File -FilePath $dcrFile -Encoding utf8

    try {
        az monitor data-collection rule create `
            --resource-group $config.resourceGroup `
            --location $config.location `
            --name $dcrName `
            --rule-file $dcrFile `
            --output none 2>$null
        Write-Log "  ✓ Data collection rule created" -Level "Success"
    } catch {
        Write-Log "  ⚠ Data collection rule may already exist" -Level "Warning"
    } finally {
        Remove-Item $dcrFile -ErrorAction SilentlyContinue
    }

    Write-Log "✓ Azure resources deployed successfully" -Level "Success"

    # Step 5: Import Workbooks
    if (-not $SkipWorkbooks) {
        Write-Log "Step 5/6: Importing workbooks..." -Level "Info"
        
        # Ensure application-insights extension is installed
        $extInstalled = az extension list --query "[?name=='application-insights'].name" -o tsv 2>$null
        if (-not $extInstalled) {
            Write-Log "  Installing application-insights extension..." -Level "Info"
            az extension add --name application-insights --yes --only-show-errors 2>$null
        }
        
        $workbooksPath = Join-Path $PSScriptRoot "..\..\src\workbooks"
        
        if (Test-Path $workbooksPath) {
            $workbookFiles = Get-ChildItem -Path $workbooksPath -Filter "*.json" -File
            
            foreach ($file in $workbookFiles) {
                $name = $file.BaseName -replace '\.workbook$', ''
                $displayName = ($name -split '-' | ForEach-Object { 
                    $_.Substring(0,1).ToUpper() + $_.Substring(1) 
                }) -join ' '
                
                Write-Log "  Importing: $displayName" -Level "Info"
                
                $workbookId = [guid]::NewGuid().ToString()
                $workbookFile = Resolve-Path $file.FullName

                try {
                    az monitor app-insights workbook create `
                        --name $workbookId `
                        --resource-group $config.resourceGroup `
                        --location $config.location `
                        --kind shared `
                        --category "workbook" `
                        --display-name $displayName `
                        --serialized-data "@$workbookFile" `
                        --source-id "Azure Monitor" `
                        --output none 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "    ✓ $displayName imported" -Level "Success"
                    } else {
                        Write-Log "    ✗ Failed to import $displayName" -Level "Warning"
                    }
                } catch {
                    Write-Log "    ✗ Failed to import $displayName : $_" -Level "Warning"
                }
            }
        } else {
            Write-Log "  ⚠ Workbooks directory not found: $workbooksPath" -Level "Warning"
        }
        
        Write-Log "✓ Workbooks imported" -Level "Success"
    } else {
        Write-Log "Step 5/6: Skipping workbook import" -Level "Warning"
    }

    # Step 6: Configure RBAC
    Write-Log "Step 6/6: Configuring permissions..." -Level "Info"
    
    try {
        $currentUser = az ad signed-in-user show --query id -o tsv 2>$null
        
        if ($currentUser) {
            az role assignment create `
                --role "Log Analytics Reader" `
                --assignee $currentUser `
                --scope $workspace.id `
                --output none 2>$null
            Write-Log "✓ Permissions configured" -Level "Success"
        }
    } catch {
        Write-Log "⚠ Could not configure RBAC (may already exist)" -Level "Warning"
    }

    # Display Summary
    Show-DeploymentSummary -Config $config -WorkspaceId $workspace.customerId

} catch {
    Write-Log "❌ Deployment failed: $_" -Level "Error"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 1
}

#endregion
