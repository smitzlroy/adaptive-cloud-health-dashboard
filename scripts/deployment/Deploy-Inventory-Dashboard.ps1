<#
.SYNOPSIS
    Deploy Inventory-Only Dashboard (No Agents, No Costs)

.DESCRIPTION
    Deploys ONLY the inventory dashboard workbook using Azure Resource Graph.
    - ✅ No Log Analytics workspace
    - ✅ No data collection agents required
    - ✅ No ongoing costs
    - ✅ Read-only resource inventory

.PARAMETER SubscriptionId
    Azure subscription ID where the workbook will be created

.PARAMETER ResourceGroup
    Resource group for the workbook (will be created if doesn't exist)

.PARAMETER Location
    Azure region for resources (default: eastus)

.PARAMETER WorkbookName
    Display name for the workbook (default: "Adaptive Cloud Inventory Dashboard")

.EXAMPLE
    .\Deploy-Inventory-Dashboard.ps1 -SubscriptionId "xxx-xxx" -ResourceGroup "rg-dashboards"

.EXAMPLE
    .\Deploy-Inventory-Dashboard.ps1 -SubscriptionId "xxx-xxx" -ResourceGroup "rg-dashboards" -WorkbookName "My Inventory"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$WorkbookName = "Adaptive Cloud Inventory Dashboard"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "Cyan" }
    }
    Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $Message" -ForegroundColor $color
}

try {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  📦 Inventory Dashboard Deployment (FREE)     " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ No agents required" -ForegroundColor Green
    Write-Host "✅ No Log Analytics workspace" -ForegroundColor Green
    Write-Host "✅ No ongoing costs" -ForegroundColor Green
    Write-Host "✅ Uses Azure Resource Graph (free tier)" -ForegroundColor Green
    Write-Host ""

    # Check prerequisites
    Write-Log "Validating prerequisites..." -Level "Info"
    
    $azCli = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azCli) {
        throw "Azure CLI not installed. Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    }
    
    $account = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in to Azure. Run 'az login' first."
    }
    
    # Check for application-insights extension
    $extInstalled = az extension list --query "[?name=='application-insights'].name" -o tsv 2>$null
    if (-not $extInstalled) {
        Write-Log "Installing application-insights extension..." -Level "Info"
        az extension add --name application-insights --yes --only-show-errors 2>$null
    }
    
    Write-Log "✓ Prerequisites validated" -Level "Success"

    # Set subscription
    Write-Log "Setting subscription..." -Level "Info"
    az account set --subscription $SubscriptionId
    $currentSub = az account show --query name -o tsv
    Write-Log "✓ Using subscription: $currentSub" -Level "Success"

    # Create resource group
    Write-Log "Creating resource group: $ResourceGroup" -Level "Info"
    az group create --name $ResourceGroup --location $Location --output none
    Write-Log "✓ Resource group ready" -Level "Success"

    # Import workbook
    Write-Log "Importing inventory dashboard workbook..." -Level "Info"
    
    $workbookId = [guid]::NewGuid().ToString()
    $workbookFile = Resolve-Path (Join-Path $PSScriptRoot "..\..\src\workbooks\inventory-dashboard.workbook.json")

    az monitor app-insights workbook create `
        --name $workbookId `
        --resource-group $ResourceGroup `
        --location $Location `
        --kind shared `
        --category "workbook" `
        --display-name $WorkbookName `
        --serialized-data "@$workbookFile" `
        --source-id "Azure Monitor" `
        --output none 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Log "✓ Workbook imported successfully!" -Level "Success"
    } else {
        throw "Failed to import workbook"
    }

    # Success summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Deployment Completed Successfully!   " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Workbook Details:" -ForegroundColor Cyan
    Write-Host "  Name: $WorkbookName" -ForegroundColor White
    Write-Host "  ID: $workbookId" -ForegroundColor White
    Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "  Location: $Location" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Access your dashboard:" -ForegroundColor Yellow
    Write-Host "  https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks" -ForegroundColor Blue
    Write-Host ""
    Write-Host "💡 What's included:" -ForegroundColor Cyan
    Write-Host "  ✅ Resource inventory (Azure Local, AKS Arc, Arc Servers)" -ForegroundColor Green
    Write-Host "  ✅ Policy compliance status" -ForegroundColor Green
    Write-Host "  ✅ Resource distribution and trends" -ForegroundColor Green
    Write-Host "  ✅ Tag analysis" -ForegroundColor Green
    Write-Host ""
    Write-Host "💰 Cost: $0 (completely free)" -ForegroundColor Green
    Write-Host ""
    Write-Host "📈 Want performance metrics & health monitoring?" -ForegroundColor Yellow
    Write-Host "  Deploy the Full Dashboard: .\Deploy-Full-Dashboard.ps1" -ForegroundColor White
    Write-Host "  (Requires agents and Log Analytics - costs apply)" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Log "❌ Deployment failed: $_" -Level "Error"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 1
}
