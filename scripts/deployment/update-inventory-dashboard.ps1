<#
.SYNOPSIS
    Update existing Inventory Dashboard workbook

.DESCRIPTION
    Updates an already-deployed inventory dashboard with the latest changes.
    Use this after modifying the workbook JSON file.

.PARAMETER WorkbookId
    The GUID of the existing workbook (from initial deployment)

.PARAMETER ResourceGroup
    Resource group containing the workbook

.EXAMPLE
    .\update-inventory-dashboard.ps1 -WorkbookId "64ee0796-b0b9-4e69-b654-1de305f9e949" -ResourceGroup "dashboard-test"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkbookId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Updating Adaptive Cloud Inventory Dashboard..." -ForegroundColor Cyan
Write-Host ""

try {
    # Get workbook file path
    $workbookFile = Resolve-Path (Join-Path $PSScriptRoot "..\..\src\workbooks\inventory-dashboard.workbook.json")
    
    if (-not (Test-Path $workbookFile)) {
        throw "Workbook file not found: $workbookFile"
    }

    Write-Host "📄 Loading workbook from: $workbookFile" -ForegroundColor Yellow
    Write-Host ""

    # Update the workbook
    Write-Host "☁️  Updating Azure Workbook..." -ForegroundColor Yellow
    
    az monitor app-insights workbook update `
        --name $WorkbookId `
        --resource-group $ResourceGroup `
        --serialized-data "@$workbookFile" `
        --output none

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "    Update Completed Successfully!     " -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Updated Workbook:" -ForegroundColor Cyan
        Write-Host "  ID: $WorkbookId" -ForegroundColor White
        Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
        Write-Host ""
        Write-Host "🌐 View your updated dashboard:" -ForegroundColor Yellow
        Write-Host "  https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks" -ForegroundColor Blue
        Write-Host ""
        Write-Host "✨ Latest improvements:" -ForegroundColor Cyan
        Write-Host "  ✅ Friendly labels on all tiles (e.g., 'Resources with Owner Tag')" -ForegroundColor Green
        Write-Host "  ✅ Context blocks explaining each section" -ForegroundColor Green
        Write-Host "  ✅ Improved Policy Compliance readability" -ForegroundColor Green
        Write-Host "  ✅ Clear descriptions for cost optimization areas" -ForegroundColor Green
        Write-Host ""
    } else {
        throw "Failed to update workbook"
    }

} catch {
    Write-Host ""
    Write-Host "❌ Update failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify workbook ID is correct: az monitor app-insights workbook show --name $WorkbookId --resource-group $ResourceGroup" -ForegroundColor White
    Write-Host "  2. Check resource group exists: az group show --name $ResourceGroup" -ForegroundColor White
    Write-Host "  3. Verify Azure CLI is logged in: az account show" -ForegroundColor White
    Write-Host ""
    exit 1
}
