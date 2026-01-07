<#
.SYNOPSIS
    Generate Power BI Data Model Script

.DESCRIPTION
    Creates a Power Query M script that can be pasted into Power BI to automatically
    load all CSV files and create relationships.

.PARAMETER CsvPath
    Path to the folder containing exported CSV files

.EXAMPLE
    .\Generate-PowerBIModel.ps1 -CsvPath "C:\exports\powerbi-exports"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = "..\..\powerbi-exports"
)

$CsvPath = Resolve-Path $CsvPath -ErrorAction SilentlyContinue

if (-not $CsvPath -or -not (Test-Path $CsvPath)) {
    Write-Host "❌ CSV path not found: $CsvPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Run Export-ToPowerBI.ps1 first to generate CSV files" -ForegroundColor Yellow
    exit 1
}

# Ensure we have the full path as a string
$CsvPathString = if ($CsvPath -is [System.Management.Automation.PathInfo]) {
    $CsvPath.Path
} else {
    $CsvPath.ToString()
}

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Power BI Data Model Generator                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$csvFiles = Get-ChildItem -Path $CsvPath -Filter "*.csv"

if ($csvFiles.Count -eq 0) {
    Write-Host "❌ No CSV files found in: $CsvPath" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $($csvFiles.Count) CSV files" -ForegroundColor Green
Write-Host ""

# Generate Power Query M script
$mScript = @"
// ===================================================
// Adaptive Cloud - Power BI Data Model
// Auto-generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// ===================================================

let
    // Configuration
    SourceFolder = "$($CsvPathString.Replace('\', '\\'))",
    
    // Helper function to load CSV files
    LoadCsv = (fileName as text, tableName as text) =>
        let
            Source = Csv.Document(
                File.Contents(SourceFolder & "\\" & fileName),
                [Delimiter=",", Columns=null, Encoding=65001, QuoteStyle=QuoteStyle.None]
            ),
            PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
            ChangedTypes = Table.TransformColumnTypes(
                PromotedHeaders,
                List.Transform(
                    Table.ColumnNames(PromotedHeaders),
                    each {_, type text}
                )
            )
        in
            ChangedTypes,
    
    // Load all tables
"@

$tables = @()

foreach ($file in $csvFiles) {
    $tableName = $file.BaseName -replace '^\d+-', '' -replace '-', ' '
    $tableName = (Get-Culture).TextInfo.ToTitleCase($tableName)
    $tableName = $tableName -replace ' ', ''
    
    $tables += $tableName
    
    $mScript += @"

    $tableName = LoadCsv("$($file.Name)", "$tableName"),
"@
}

# Remove trailing comma
$mScript = $mScript.TrimEnd(',')

$mScript += @"

    
    // Return all tables as a record
    Output = [
"@

foreach ($table in $tables) {
    $mScript += "`n        $table = $table,"
}

$mScript = $mScript.TrimEnd(',')

$mScript += @"

    ]
in
    Output
"@

# Save to file
$outputFile = Join-Path $CsvPath "PowerBI-DataModel.m"
$mScript | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "✅ Power Query M script generated!" -ForegroundColor Green
Write-Host ""
Write-Host "📄 Saved to: $outputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  How to Use in Power BI Desktop" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open Power BI Desktop" -ForegroundColor White
Write-Host ""
Write-Host "2. Get Data → Blank Query" -ForegroundColor White
Write-Host ""
Write-Host "3. Open Advanced Editor (Home → Advanced Editor)" -ForegroundColor White
Write-Host ""
Write-Host "4. Copy and paste the contents of:" -ForegroundColor White
Write-Host "   $outputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Click 'Done' - all tables will be imported automatically!" -ForegroundColor White
Write-Host ""
Write-Host "6. In Queries pane, expand the 'Output' record to see all tables" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Generate relationship script
$relationshipsScript = @"
// ===================================================
// Recommended Relationships for Data Model
// ===================================================

// Manual Steps in Power BI:
// 1. Go to Model View
// 2. Create the following relationships:

// Resource Summary (Hub Table)
- ResourceSummary[ResourceId] → ConnectivityStatus[ResourceId]
- ResourceSummary[ResourceId] → GovernanceTags[ResourceId]
- ResourceSummary[SubscriptionId] → PolicyCompliance[SubscriptionId]

// Azure Local Specific
- ResourceSummary[ResourceName] → HardwareCapacity[ClusterName]
- ResourceSummary[ResourceName] → Configuration[ClusterName]
- ResourceSummary[ResourceName] → SecurityPosture[ClusterName]

// Extensions
- ResourceSummary[ResourceName] → ArcExtensions[ParentResource]

// Lifecycle & Optimization
- ResourceSummary[ResourceId] → ResourceLifecycle[ResourceId]
- ResourceSummary[ResourceId] → ZombieResources[ResourceId]
- ResourceSummary[ResourceId] → LocationDistribution[ResourceId]

// Versions
- ResourceSummary[ResourceName] → KubernetesVersions[ClusterName] (for AKS Arc)
- ResourceSummary[ResourceName] → ArcAgentVersions[ServerName] (for Arc Servers)

// ===================================================
// DAX Measures to Create
// ===================================================

// Total Resources
Total Resources = COUNTROWS(ResourceSummary)

// Compliance Rate
Compliance Rate = 
DIVIDE(
    COUNTROWS(FILTER(PolicyCompliance, PolicyCompliance[IsCompliant] = "True")),
    COUNTROWS(PolicyCompliance),
    0
) * 100

// Critical Connections
Critical Connections = 
COUNTROWS(FILTER(ConnectivityStatus, ConnectivityStatus[HealthStatus] = "Critical"))

// Zombie Resources
Zombie Resources = 
COUNTROWS(FILTER(ZombieResources, VALUE(ZombieResources[DaysDisconnected]) >= 90))

// Tag Compliance
Tag Compliance % = 
DIVIDE(
    COUNTROWS(FILTER(GovernanceTags, GovernanceTags[HasOwnerTag] = "True")),
    COUNTROWS(GovernanceTags),
    0
) * 100

// Total CPU Cores
Total CPU Cores = SUM(VALUE(HardwareCapacity[CPUCores]))

// Total Memory TB
Total Memory TB = SUM(VALUE(HardwareCapacity[MemoryTB]))

// Failed Extensions
Failed Extensions = 
COUNTROWS(FILTER(ArcExtensions, ArcExtensions[Status] = "Failed"))

// Expensive Region Resources
Expensive Region Resources = 
COUNTROWS(FILTER(LocationDistribution, LocationDistribution[IsExpensiveRegion] = "True"))

"@

$relationshipsFile = Join-Path $CsvPath "PowerBI-Relationships.txt"
$relationshipsScript | Out-File -FilePath $relationshipsFile -Encoding UTF8

Write-Host "📊 Relationship guide saved: $relationshipsFile" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Open this file for step-by-step relationship setup and DAX measures" -ForegroundColor Cyan
Write-Host ""

# Create a quick reference card
$quickRef = @"
═══════════════════════════════════════════════════════
  POWER BI QUICK REFERENCE CARD
═══════════════════════════════════════════════════════

CSV FILES LOCATION:
$($CsvPath.Path)

IMPORT SCRIPT:
$outputFile

RELATIONSHIPS GUIDE:
$relationshipsFile

═══════════════════════════════════════════════════════
  KEY TABLES
═══════════════════════════════════════════════════════

HUB TABLE (for relationships):
→ ResourceSummary

CORE INVENTORY:
→ ResourceSummary, HardwareCapacity, ConnectivityStatus

COMPLIANCE:
→ PolicyCompliance, GovernanceTags, Configuration, SecurityPosture

COST OPTIMIZATION:
→ ZombieResources, LocationDistribution, Rightsizing

OPERATIONS:
→ ArcExtensions, KubernetesVersions, ArcAgentVersions

═══════════════════════════════════════════════════════
  RECOMMENDED PAGES
═══════════════════════════════════════════════════════

PAGE 1: Executive Summary
- Cards: Total Resources, Compliance %, Critical Alerts
- Pie: Resources by Type
- Map: Geographic Distribution

PAGE 2: Health & Operations
- Gauge: Connectivity Health
- Table: Critical/Warning Resources
- Bar: Extension Status

PAGE 3: Cost Optimization
- Cards: Zombie Resources, Expensive Regions
- Table: Deletion Candidates (90+ days)
- Matrix: Regional Cost Analysis

PAGE 4: Hardware Capacity
- Cards: Total CPUs, Total Memory, Clusters
- Column: Capacity by Cluster
- Treemap: Size Distribution

PAGE 5: Governance & Security
- Donut: Tag Compliance
- Funnel: Security Features
- Table: Untagged Resources

═══════════════════════════════════════════════════════
  REFRESH DATA
═══════════════════════════════════════════════════════

1. Run: .\Export-ToPowerBI.ps1
2. In Power BI: Home → Refresh

For automatic refresh, schedule Export-ToPowerBI.ps1 
using Windows Task Scheduler (daily at 6 AM recommended)

═══════════════════════════════════════════════════════
"@

$quickRefFile = Join-Path $CsvPath "PowerBI-QuickReference.txt"
$quickRef | Out-File -FilePath $quickRefFile -Encoding UTF8

Write-Host "📋 Quick reference saved: $quickRefFile" -ForegroundColor Green
Write-Host ""
Write-Host "✨ All files ready! Follow the instructions above to import into Power BI." -ForegroundColor Green
Write-Host ""
