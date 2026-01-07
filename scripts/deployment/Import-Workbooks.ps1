<#
.SYNOPSIS
    Imports Azure Workbook templates to a subscription.

.DESCRIPTION
    Imports all or specific workbook templates from the src/workbooks directory
    to the specified Azure subscription and resource group.

.PARAMETER SubscriptionId
    Azure subscription ID where workbooks will be imported.

.PARAMETER ResourceGroup
    Resource group name for the workbooks.

.PARAMETER WorkbookName
    Specific workbook to import (optional). If not provided, imports all workbooks.

.PARAMETER Location
    Azure region for workbooks (default: eastus).

.EXAMPLE
    .\Import-Workbooks.ps1 -SubscriptionId "xxx" -ResourceGroup "rg-dashboard"

.EXAMPLE
    .\Import-Workbooks.ps1 -SubscriptionId "xxx" -ResourceGroup "rg-dashboard" -WorkbookName "health-overview"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$WorkbookName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

try {
    Write-Log "Starting workbook import..." -Level "Info"

    # Set subscription
    az account set --subscription $SubscriptionId
    Write-Log "Using subscription: $(az account show --query name -o tsv)" -Level "Success"

    # Get workbook files
    $workbooksPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "src\workbooks"
    
    if (-not (Test-Path $workbooksPath)) {
        throw "Workbooks directory not found: $workbooksPath"
    }

    if ($WorkbookName) {
        $workbookFiles = Get-ChildItem -Path $workbooksPath -Filter "$WorkbookName*.json" -File
    } else {
        $workbookFiles = Get-ChildItem -Path $workbooksPath -Filter "*.json" -File
    }

    if ($workbookFiles.Count -eq 0) {
        Write-Log "No workbook files found" -Level "Warning"
        exit 0
    }

    Write-Log "Found $($workbookFiles.Count) workbook(s) to import" -Level "Info"

    foreach ($file in $workbookFiles) {
        $name = $file.BaseName -replace '\.workbook$', ''
        $displayName = ($name -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' '
        
        Write-Log "Importing workbook: $displayName" -Level "Info"

        # Read workbook content
        $workbookContent = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        # Generate unique ID for workbook
        $workbookId = [guid]::NewGuid().ToString()

        # Create workbook using Azure REST API via CLI
        $workbookJson = @{
            location = $Location
            kind = "shared"
            properties = @{
                displayName = $displayName
                serializedData = ($workbookContent | ConvertTo-Json -Depth 100 -Compress)
                category = "Adaptive-Cloud"
                sourceId = "azure monitor"
            }
        } | ConvertTo-Json -Depth 100

        $tempFile = "$env:TEMP\workbook-$workbookId.json"
        $workbookJson | Out-File -FilePath $tempFile -Encoding utf8

        try {
            az resource create `
                --resource-group $ResourceGroup `
                --resource-type "Microsoft.Insights/workbooks" `
                --name $workbookId `
                --properties "@$tempFile" `
                --output none

            Write-Log "✓ Imported: $displayName" -Level "Success"
        } catch {
            Write-Log "Failed to import $displayName : $_" -Level "Error"
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }

    Write-Log "" -Level "Info"
    Write-Log "Workbook import completed!" -Level "Success"
    Write-Log "Access your workbooks at: https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/workbooks" -Level "Info"

} catch {
    Write-Log "Import failed: $_" -Level "Error"
    exit 1
}
