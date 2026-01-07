<#
.SYNOPSIS
    Export Adaptive Cloud inventory data to Power BI

.DESCRIPTION
    Queries Azure Resource Graph and exports data to CSV files that Power BI can import.
    Creates separate files for each dashboard section with all metrics.
    
    All queries are FREE (Azure Resource Graph API - no cost)

.PARAMETER OutputPath
    Directory where CSV files will be saved (default: .\powerbi-exports)

.PARAMETER SubscriptionIds
    Array of subscription IDs to query (optional - queries all accessible subscriptions if not specified)

.PARAMETER OpenOutputFolder
    Open the output folder after export completes

.EXAMPLE
    .\Export-ToPowerBI.ps1
    
.EXAMPLE
    .\Export-ToPowerBI.ps1 -OutputPath "C:\Reports\PowerBI" -OpenOutputFolder

.EXAMPLE
    .\Export-ToPowerBI.ps1 -SubscriptionIds @("sub-id-1", "sub-id-2")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\powerbi-exports",

    [Parameter(Mandatory = $false)]
    [string[]]$SubscriptionIds,

    [Parameter(Mandatory = $false)]
    [switch]$OpenOutputFolder
)

$ErrorActionPreference = "Stop"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$OutputPath = Resolve-Path $OutputPath

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Adaptive Cloud → Power BI Export                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Build subscription filter
$subscriptionFilter = if ($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
    $subList = ($SubscriptionIds | ForEach-Object { "'$_'" }) -join ", "
    "| where subscriptionId in ($subList)"
} else {
    ""
}

function Export-Query {
    param(
        [string]$Name,
        [string]$Query,
        [string]$FileName
    )
    
    Write-Host "📊 Exporting: $Name..." -ForegroundColor Yellow
    
    try {
        $fullQuery = $Query + $subscriptionFilter
        $result = az graph query -q $fullQuery --output json | ConvertFrom-Json
        
        if ($result.data -and $result.data.Count -gt 0) {
            $outputFile = Join-Path $OutputPath "$FileName.csv"
            $result.data | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
            Write-Host "   ✓ Exported $($result.data.Count) rows → $FileName.csv" -ForegroundColor Green
            return $result.data.Count
        } else {
            Write-Host "   ⚠ No data found" -ForegroundColor Gray
            return 0
        }
    } catch {
        Write-Host "   ✗ Error: $_" -ForegroundColor Red
        return 0
    }
}

$timestamp = Get-Date
$totalRecords = 0

Write-Host "🔍 Querying Azure Resource Graph..." -ForegroundColor Cyan
Write-Host ""

# 1. Resource Summary
$totalRecords += Export-Query -Name "Resource Summary" -FileName "01-resource-summary" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend ResourceType = case(
    type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
    type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
    type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
    'Other'
)
| extend 
    SubscriptionName = tostring(split(id, '/')[2]),
    ResourceGroupName = resourceGroup,
    Location = location,
    CreatedDate = tostring(properties.provisioningTimestamp)
| project 
    ResourceName = name,
    ResourceType,
    SubscriptionId = subscriptionId,
    ResourceGroup = ResourceGroupName,
    Location,
    CreatedDate,
    ResourceId = id
"@

# 2. Hardware Capacity (Azure Local)
$totalRecords += Export-Query -Name "Hardware Capacity" -FileName "02-hardware-capacity" -Query @"
Resources
| where type =~ 'microsoft.azurestackhci/clusters'
| mv-expand nodes = properties.reportedProperties.nodes
| extend 
    ClusterName = name,
    NodeName = tostring(nodes.name),
    CPUCores = toint(nodes.coreCount),
    MemoryGB = toint(nodes.memoryInGiB),
    DiskCapacityGB = toint(nodes.totalPhysicalMemoryInGiB)
| project 
    ClusterName,
    NodeName,
    CPUCores,
    MemoryGB,
    MemoryTB = round(todouble(MemoryGB) / 1024, 2),
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 3. Connectivity Status
$totalRecords += Export-Query -Name "Connectivity Status" -FileName "03-connectivity-status" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend 
    ResourceType = case(
        type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
        type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
        type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
        'Other'
    ),
    LastSyncTime = tostring(coalesce(
        properties.connectivityStatus.lastConnected,
        properties.lastHeartbeat,
        properties.reportedProperties.lastUpdated
    )),
    ConnectionStatus = tostring(coalesce(
        properties.connectivityStatus.status,
        properties.status,
        properties.provisioningState
    ))
| extend 
    MinutesSinceSync = datetime_diff('minute', now(), todatetime(LastSyncTime)),
    HealthStatus = case(
        MinutesSinceSync < 30, 'Healthy',
        MinutesSinceSync < 120, 'Warning',
        'Critical'
    )
| project 
    ResourceName = name,
    ResourceType,
    ConnectionStatus,
    LastSyncTime,
    MinutesSinceSync,
    HealthStatus,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 4. Configuration & Compliance (Azure Local)
$totalRecords += Export-Query -Name "Configuration & Compliance" -FileName "04-configuration" -Query @"
Resources
| where type =~ 'microsoft.azurestackhci/clusters'
| extend 
    BillingModel = tostring(properties.desiredProperties.diagnosticLevel),
    WindowsServerSubscription = tobool(properties.desiredProperties.windowsServerSubscription),
    SoftwareAssurance = tobool(properties.softwareAssuranceProperties.softwareAssuranceIntent),
    DiagnosticLevel = tostring(properties.desiredProperties.diagnosticLevel),
    RemoteSupportEnabled = tobool(properties.reportedProperties.supportPackageProperties.remoteSupport.enabled)
| project 
    ClusterName = name,
    BillingModel,
    WindowsServerSubscription,
    SoftwareAssurance,
    DiagnosticLevel,
    RemoteSupportEnabled,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 5. Security Posture (Azure Local)
$totalRecords += Export-Query -Name "Security Posture" -FileName "05-security-posture" -Query @"
Resources
| where type =~ 'microsoft.azurestackhci/clusters'
| extend 
    ImdsAttestation = tostring(properties.reportedProperties.imdsAttestation),
    IsolatedVmAttestation = tostring(properties.desiredProperties.isolatedVmAttestationConfiguration),
    AadClientId = tostring(properties.aadClientId),
    AadTenantId = tostring(properties.aadTenantId),
    HasEntraIntegration = isnotempty(properties.aadClientId)
| project 
    ClusterName = name,
    ImdsAttestation,
    IsolatedVmAttestation,
    HasEntraIntegration,
    AadTenantId,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 6. Governance Tags
$totalRecords += Export-Query -Name "Governance Tags" -FileName "06-governance-tags" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend 
    ResourceType = case(
        type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
        type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
        type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
        'Other'
    ),
    HasOwnerTag = isnotempty(tags['Owner']),
    HasEnvironmentTag = isnotempty(tags['Environment']),
    HasCostCenterTag = isnotempty(tags['CostCenter']),
    OwnerTag = tostring(tags['Owner']),
    EnvironmentTag = tostring(tags['Environment']),
    CostCenterTag = tostring(tags['CostCenter']),
    TagCount = array_length(todynamic(tags))
| project 
    ResourceName = name,
    ResourceType,
    HasOwnerTag,
    HasEnvironmentTag,
    HasCostCenterTag,
    OwnerTag,
    EnvironmentTag,
    CostCenterTag,
    TagCount,
    IsUntagged = (TagCount == 0),
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 7. Policy Compliance
$totalRecords += Export-Query -Name "Policy Compliance" -FileName "07-policy-compliance" -Query @"
PolicyResources
| where type =~ 'microsoft.policyinsights/policystates'
| extend 
    ComplianceState = tostring(properties.complianceState),
    PolicyDefinitionName = tostring(properties.policyDefinitionName),
    PolicyAssignmentName = tostring(properties.policyAssignmentName),
    ResourceId = tostring(properties.resourceId),
    ResourceType = tostring(properties.resourceType)
| where ResourceType in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| project 
    ResourceId,
    ResourceType,
    ComplianceState,
    PolicyDefinitionName,
    PolicyAssignmentName,
    IsCompliant = (ComplianceState =~ 'Compliant'),
    SubscriptionId = subscriptionId
"@

# 8. Arc Extensions
$totalRecords += Export-Query -Name "Arc Extensions" -FileName "08-arc-extensions" -Query @"
Resources
| where type =~ 'microsoft.hybridcompute/machines/extensions' or 
        type =~ 'microsoft.azurestackhci/clusters/arcextensions' or
        type =~ 'microsoft.kubernetes/connectedclusters/extensions'
| extend 
    ParentResource = tostring(split(id, '/')[8]),
    ExtensionName = name,
    ExtensionType = tostring(properties.type),
    Publisher = tostring(properties.publisher),
    Version = tostring(properties.typeHandlerVersion),
    ProvisioningState = tostring(properties.provisioningState),
    AutoUpgrade = tobool(properties.enableAutomaticUpgrade)
| extend 
    Status = case(
        ProvisioningState =~ 'Succeeded', 'Succeeded',
        ProvisioningState =~ 'Failed', 'Failed',
        ProvisioningState =~ 'Updating', 'Updating',
        'Other'
    )
| project 
    ParentResource,
    ExtensionName,
    ExtensionType,
    Publisher,
    Version,
    Status,
    AutoUpgrade,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 9. Version Management (Kubernetes)
$totalRecords += Export-Query -Name "Kubernetes Versions" -FileName "09-kubernetes-versions" -Query @"
Resources
| where type =~ 'microsoft.kubernetes/connectedclusters'
| extend 
    K8sVersion = tostring(properties.kubernetesVersion),
    Distribution = tostring(properties.distribution),
    AgentVersion = tostring(properties.agentVersion)
| project 
    ClusterName = name,
    K8sVersion,
    Distribution,
    AgentVersion,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 10. Arc Agent Versions
$totalRecords += Export-Query -Name "Arc Agent Versions" -FileName "10-arc-agent-versions" -Query @"
Resources
| where type =~ 'microsoft.hybridcompute/machines'
| extend 
    AgentVersion = tostring(properties.agentVersion),
    OSType = tostring(properties.osType),
    OSVersion = tostring(properties.osVersion)
| project 
    ServerName = name,
    AgentVersion,
    OSType,
    OSVersion,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 11. Resource Lifecycle
$totalRecords += Export-Query -Name "Resource Lifecycle" -FileName "11-resource-lifecycle" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend 
    ResourceType = case(
        type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
        type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
        type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
        'Other'
    ),
    CreatedDate = todatetime(properties.provisioningTimestamp),
    DaysOld = datetime_diff('day', now(), todatetime(properties.provisioningTimestamp))
| extend 
    AgeCategory = case(
        DaysOld < 30, '< 30 days',
        DaysOld < 90, '30-90 days',
        DaysOld < 180, '90-180 days',
        DaysOld < 365, '180-365 days',
        '> 365 days'
    )
| project 
    ResourceName = name,
    ResourceType,
    CreatedDate,
    DaysOld,
    AgeCategory,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 12. Zombie Resources (Disconnected)
$totalRecords += Export-Query -Name "Zombie Resources" -FileName "12-zombie-resources" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend 
    ResourceType = case(
        type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
        type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
        type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
        'Other'
    ),
    LastSync = todatetime(coalesce(
        properties.connectivityStatus.lastConnected,
        properties.lastHeartbeat,
        properties.reportedProperties.lastUpdated
    )),
    DaysDisconnected = datetime_diff('day', now(), todatetime(coalesce(
        properties.connectivityStatus.lastConnected,
        properties.lastHeartbeat,
        properties.reportedProperties.lastUpdated
    )))
| extend 
    ZombieCategory = case(
        DaysDisconnected < 30, 'Active',
        DaysDisconnected < 60, '30-60 days (Review)',
        DaysDisconnected < 90, '60-90 days (Delete Soon)',
        '90+ days (Delete Now)'
    )
| project 
    ResourceName = name,
    ResourceType,
    LastSync,
    DaysDisconnected,
    ZombieCategory,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 13. Location Distribution (Expensive Regions)
$totalRecords += Export-Query -Name "Location Distribution" -FileName "13-location-distribution" -Query @"
Resources
| where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters', 'microsoft.hybridcompute/machines')
| extend 
    ResourceType = case(
        type =~ 'microsoft.azurestackhci/clusters', 'Azure Local',
        type =~ 'microsoft.kubernetes/connectedclusters', 'AKS Arc',
        type =~ 'microsoft.hybridcompute/machines', 'Arc Servers',
        'Other'
    ),
    IsExpensiveRegion = location in ('australiaeast', 'australiasoutheast', 'brazilsouth', 'japaneast', 'japanwest', 'uksouth', 'ukwest')
| extend 
    RegionCostCategory = case(
        IsExpensiveRegion, 'Expensive (20-30% premium)',
        'Standard Cost'
    )
| project 
    ResourceName = name,
    ResourceType,
    Location = location,
    IsExpensiveRegion,
    RegionCostCategory,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# 14. Right-Sizing Opportunities (Arc Servers)
$totalRecords += Export-Query -Name "Right-Sizing Analysis" -FileName "14-rightsizing" -Query @"
Resources
| where type =~ 'microsoft.hybridcompute/machines'
| extend 
    CPUCores = toint(properties.detectedProperties.coreCount),
    MemoryMB = toint(properties.detectedProperties.totalPhysicalMemoryInBytes) / 1024 / 1024
| extend 
    MemoryGB = round(MemoryMB / 1024, 2),
    SizeCategory = case(
        CPUCores < 4 and MemoryGB < 16, 'Very Small',
        CPUCores <= 8 and MemoryGB <= 32, 'Small',
        CPUCores <= 16 and MemoryGB <= 64, 'Medium',
        'Large'
    )
| project 
    ServerName = name,
    CPUCores,
    MemoryGB,
    SizeCategory,
    Location = location,
    ResourceGroup = resourceGroup,
    SubscriptionId = subscriptionId
"@

# Create metadata file
$metadata = @{
    ExportDate = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
    TotalRecords = $totalRecords
    SubscriptionsQueried = if ($SubscriptionIds) { $SubscriptionIds.Count } else { "All accessible" }
    Files = (Get-ChildItem -Path $OutputPath -Filter "*.csv").Name
} | ConvertTo-Json -Depth 3

$metadata | Out-File -FilePath (Join-Path $OutputPath "export-metadata.json") -Encoding UTF8

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Export Complete!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Total Records: $totalRecords" -ForegroundColor White
Write-Host "   Export Date: $($timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "   Output Path: $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "📁 Files Created:" -ForegroundColor Cyan
Get-ChildItem -Path $OutputPath -Filter "*.csv" | ForEach-Object {
    Write-Host "   ✓ $($_.Name)" -ForegroundColor Green
}
Write-Host ""
Write-Host "🔄 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Open Power BI Desktop" -ForegroundColor White
Write-Host "   2. Get Data → Text/CSV" -ForegroundColor White
Write-Host "   3. Import each CSV file from: $OutputPath" -ForegroundColor White
Write-Host "   4. Create relationships between tables (use ResourceId, SubscriptionId)" -ForegroundColor White
Write-Host "   5. Build your custom visuals!" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: Use the Power BI template in templates/powerbi/ for pre-built visuals" -ForegroundColor Cyan
Write-Host ""

if ($OpenOutputFolder) {
    Start-Process explorer.exe -ArgumentList $OutputPath
}
