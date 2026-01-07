<#
.SYNOPSIS
    Deploys Azure resources required for the Adaptive Cloud Health Dashboard.

.DESCRIPTION
    Creates Log Analytics workspace, configures data collection rules, and sets up
    required permissions for the dashboard solution.

.PARAMETER ConfigFile
    Path to configuration JSON file.

.PARAMETER SubscriptionId
    Azure subscription ID.

.PARAMETER ResourceGroup
    Resource group name (will be created if doesn't exist).

.PARAMETER Location
    Azure region for resources.

.PARAMETER WorkspaceName
    Log Analytics workspace name.

.EXAMPLE
    .\Deploy-Resources.ps1 -ConfigFile ".\config.json"

.EXAMPLE
    .\Deploy-Resources.ps1 -SubscriptionId "xxx" -ResourceGroup "rg-dashboard" -Location "eastus"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName
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
    Write-Log "Starting deployment of Adaptive Cloud Health Dashboard resources..." -Level "Info"

    # Load configuration if provided
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        Write-Log "Loading configuration from $ConfigFile" -Level "Info"
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        
        if (-not $SubscriptionId) { $SubscriptionId = $config.subscriptions[0] }
        if (-not $ResourceGroup) { $ResourceGroup = $config.resourceGroup }
        if (-not $Location) { $Location = $config.location }
        if (-not $WorkspaceName) { $WorkspaceName = $config.logAnalytics.name }
    }

    # Validate parameters
    if (-not $SubscriptionId) {
        throw "SubscriptionId is required. Provide via parameter or config file."
    }
    if (-not $ResourceGroup) {
        throw "ResourceGroup is required. Provide via parameter or config file."
    }
    if (-not $WorkspaceName) {
        $WorkspaceName = "law-adaptive-cloud-$(Get-Random -Minimum 1000 -Maximum 9999)"
    }

    # Check if Azure CLI is installed
    $azInstalled = Get-Command az -ErrorAction SilentlyContinue
    if (-not $azInstalled) {
        throw "Azure CLI is not installed. Please install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    }

    # Login and set subscription
    Write-Log "Setting Azure subscription..." -Level "Info"
    az account set --subscription $SubscriptionId
    
    $currentSub = az account show --query name -o tsv
    Write-Log "Using subscription: $currentSub" -Level "Success"

    # Create resource group
    Write-Log "Creating resource group: $ResourceGroup" -Level "Info"
    az group create --name $ResourceGroup --location $Location --output none
    Write-Log "✓ Resource group created" -Level "Success"

    # Create Log Analytics workspace
    Write-Log "Creating Log Analytics workspace: $WorkspaceName" -Level "Info"
    $workspace = az monitor log-analytics workspace create `
        --resource-group $ResourceGroup `
        --workspace-name $WorkspaceName `
        --location $Location `
        --query "{id:id, customerId:customerId}" `
        -o json | ConvertFrom-Json

    if ($workspace) {
        Write-Log "✓ Log Analytics workspace created" -Level "Success"
        Write-Log "  Workspace ID: $($workspace.customerId)" -Level "Info"
    } else {
        throw "Failed to create Log Analytics workspace"
    }

    # Enable solutions
    Write-Log "Enabling monitoring solutions..." -Level "Info"
    
    $solutions = @(
        "Updates",
        "Security",
        "ChangeTracking",
        "AzureActivity"
    )

    foreach ($solution in $solutions) {
        try {
            Write-Log "  Enabling $solution..." -Level "Info"
            az monitor log-analytics solution create `
                --resource-group $ResourceGroup `
                --solution-type $solution `
                --workspace $WorkspaceName `
                --output none
        } catch {
            Write-Log "  Warning: Could not enable $solution" -Level "Warning"
        }
    }

    # Create data collection rule
    Write-Log "Creating data collection rule..." -Level "Info"
    
    $dcrName = "dcr-adaptive-cloud"
    $dcrConfig = @{
        location = $Location
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

    $dcrFile = "$env:TEMP\dcr-config.json"
    $dcrConfig | Out-File -FilePath $dcrFile -Encoding utf8

    az monitor data-collection rule create `
        --resource-group $ResourceGroup `
        --location $Location `
        --name $dcrName `
        --rule-file $dcrFile `
        --output none

    Remove-Item $dcrFile
    Write-Log "✓ Data collection rule created" -Level "Success"

    # Set up RBAC permissions
    Write-Log "Configuring RBAC permissions..." -Level "Info"
    
    $currentUser = az ad signed-in-user show --query id -o tsv
    
    az role assignment create `
        --role "Log Analytics Reader" `
        --assignee $currentUser `
        --scope $workspace.id `
        --output none

    Write-Log "✓ RBAC permissions configured" -Level "Success"

    # Output summary
    Write-Log "" -Level "Info"
    Write-Log "========================================" -Level "Success"
    Write-Log "Deployment completed successfully!" -Level "Success"
    Write-Log "========================================" -Level "Success"
    Write-Log "" -Level "Info"
    Write-Log "Resources created:" -Level "Info"
    Write-Log "  Resource Group: $ResourceGroup" -Level "Info"
    Write-Log "  Log Analytics Workspace: $WorkspaceName" -Level "Info"
    Write-Log "  Workspace ID: $($workspace.customerId)" -Level "Info"
    Write-Log "  Location: $Location" -Level "Info"
    Write-Log "" -Level "Info"
    Write-Log "Next steps:" -Level "Info"
    Write-Log "  1. Import workbooks: .\Import-Workbooks.ps1" -Level "Info"
    Write-Log "  2. Configure data collection on your clusters" -Level "Info"
    Write-Log "  3. Access dashboards in Azure Portal > Monitor > Workbooks" -Level "Info"

} catch {
    Write-Log "Deployment failed: $_" -Level "Error"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 1
}
