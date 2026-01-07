# Validate Power BI Dashboard Setup
# Checks CSV files, data quality, and provides troubleshooting help

param(
    [string]$ExportPath = "$PSScriptRoot\..\..\powerbi-exports"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Power BI Dashboard Setup Validator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if export folder exists
if (-not (Test-Path $ExportPath)) {
    Write-Host "❌ ERROR: Export folder not found: $ExportPath" -ForegroundColor Red
    Write-Host "   Run Export-ToPowerBI.ps1 first!" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Export folder found: $ExportPath" -ForegroundColor Green
Write-Host ""

# Expected CSV files
$expectedFiles = @(
    "01-resource-summary.csv",
    "02-hardware-capacity.csv",
    "03-connectivity-status.csv",
    "04-configuration.csv",
    "05-security-posture.csv",
    "06-governance-tags.csv",
    "07-policy-compliance.csv",
    "08-arc-extensions.csv",
    "09-kubernetes-versions.csv",
    "10-arc-agent-versions.csv",
    "11-resource-lifecycle.csv",
    "12-zombie-resources.csv",
    "13-location-distribution.csv",
    "14-rightsizing.csv"
)

Write-Host "Checking CSV files..." -ForegroundColor Cyan
$missingFiles = @()
$fileStats = @()

foreach ($file in $expectedFiles) {
    $filePath = Join-Path $ExportPath $file
    if (Test-Path $filePath) {
        $content = Get-Content $filePath
        $rowCount = ($content | Measure-Object).Count
        $fileSize = (Get-Item $filePath).Length
        
        Write-Host "  ✅ $file" -ForegroundColor Green
        Write-Host "     Rows: $rowCount | Size: $([Math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Gray
        
        $fileStats += [PSCustomObject]@{
            File = $file
            Rows = $rowCount
            SizeKB = [Math]::Round($fileSize/1KB, 2)
        }
    } else {
        Write-Host "  ❌ MISSING: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing $($missingFiles.Count) file(s)!" -ForegroundColor Red
    Write-Host "   Run: .\scripts\powerbi\Export-ToPowerBI.ps1" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "✅ All 14 CSV files present!" -ForegroundColor Green
    Write-Host ""
}

# Check for empty files
$emptyFiles = $fileStats | Where-Object { $_.Rows -le 1 }
if ($emptyFiles) {
    Write-Host "⚠️  WARNING: Files with no data (header only):" -ForegroundColor Yellow
    $emptyFiles | ForEach-Object {
        Write-Host "   - $($_.File)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Total data summary
$totalRows = ($fileStats | Measure-Object -Property Rows -Sum).Sum
$totalSizeKB = ($fileStats | Measure-Object -Property SizeKB -Sum).Sum

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATA SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Records: $totalRows" -ForegroundColor White
Write-Host "Total Size: $([Math]::Round($totalSizeKB/1024, 2)) MB" -ForegroundColor White
Write-Host ""

# Check for helper files
Write-Host "Checking helper files..." -ForegroundColor Cyan
$helperFiles = @(
    "PowerBI-DAX-Measures.txt",
    "PowerBI-Quick-Setup-Guide.md",
    "PowerBI-Dashboard-Builder-README.md",
    "PowerBI-Visual-Layout-Reference.txt"
)

foreach ($file in $helperFiles) {
    $filePath = Join-Path $ExportPath $file
    if (Test-Path $filePath) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ MISSING: $file" -ForegroundColor Red
    }
}

Write-Host ""

# Sample data check - validate first CSV has proper structure
$sampleFile = Join-Path $ExportPath "01-resource-summary.csv"
if (Test-Path $sampleFile) {
    Write-Host "Validating data structure (01-resource-summary.csv)..." -ForegroundColor Cyan
    $firstLine = Get-Content $sampleFile -First 1
    
    # Check if first line looks like a header or data
    if ($firstLine -match "subscriptionId|resourceGroup|name|type") {
        Write-Host "  ✅ CSV has header row" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  WARNING: CSV may be missing headers" -ForegroundColor Yellow
        Write-Host "     First line: $($firstLine.Substring(0, [Math]::Min(80, $firstLine.Length)))..." -ForegroundColor Gray
        Write-Host ""
        Write-Host "     FIX IN POWER BI:" -ForegroundColor Yellow
        Write-Host "     1. Open Power Query Editor" -ForegroundColor White
        Write-Host "     2. Select table → Transform → Use First Row as Headers" -ForegroundColor White
    }
}

Write-Host ""

# Power BI readiness check
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "POWER BI READINESS CHECKLIST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$checklistItems = @(
    @{Item = "14 CSV files exported"; Status = ($missingFiles.Count -eq 0)},
    @{Item = "CSV files have data (>1 row)"; Status = ($emptyFiles.Count -eq 0)},
    @{Item = "Helper files present"; Status = (Test-Path (Join-Path $ExportPath "PowerBI-DAX-Measures.txt"))},
    @{Item = "Power BI Desktop installed"; Status = $null} # Can't check this
)

foreach ($item in $checklistItems) {
    if ($null -eq $item.Status) {
        Write-Host "  ⚠️  $($item.Item) - VERIFY MANUALLY" -ForegroundColor Yellow
    } elseif ($item.Status) {
        Write-Host "  ✅ $($item.Item)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($item.Item)" -ForegroundColor Red
    }
}

Write-Host ""

# Next steps
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($missingFiles.Count -gt 0 -or $emptyFiles.Count -gt 0) {
    Write-Host "1. Re-run data export:" -ForegroundColor Yellow
    Write-Host "   .\scripts\powerbi\Export-ToPowerBI.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "✅ Your data is ready for Power BI!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Open these files to build your dashboard:" -ForegroundColor Cyan
    Write-Host "  1. PowerBI-Dashboard-Builder-README.md (overview)" -ForegroundColor White
    Write-Host "  2. PowerBI-Quick-Setup-Guide.md (step-by-step)" -ForegroundColor White
    Write-Host "  3. PowerBI-DAX-Measures.txt (copy/paste measures)" -ForegroundColor White
    Write-Host "  4. PowerBI-Visual-Layout-Reference.txt (layout diagrams)" -ForegroundColor White
    Write-Host ""
    Write-Host "Open in Explorer:" -ForegroundColor Cyan
    Write-Host "  explorer.exe `"$ExportPath`"" -ForegroundColor Gray
    Write-Host ""
}

# Data insights
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK DATA INSIGHTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Parse resource summary for quick counts
$summaryFile = Join-Path $ExportPath "01-resource-summary.csv"
if (Test-Path $summaryFile) {
    $summaryData = Import-Csv $summaryFile -Header @("subscriptionId", "resourceGroup", "name", "type", "location", "properties") -ErrorAction SilentlyContinue
    
    if ($summaryData) {
        $azureLocalCount = ($summaryData | Where-Object { $_.type -like "*azurestackhci/clusters*" } | Measure-Object).Count
        $aksArcCount = ($summaryData | Where-Object { $_.type -like "*kubernetes/connectedclusters*" } | Measure-Object).Count
        $arcServerCount = ($summaryData | Where-Object { $_.type -like "*hybridcompute/machines*" } | Measure-Object).Count
        
        Write-Host "Azure Local Clusters: $azureLocalCount" -ForegroundColor White
        Write-Host "AKS Arc Clusters: $aksArcCount" -ForegroundColor White
        Write-Host "Arc Servers: $arcServerCount" -ForegroundColor White
        Write-Host "Total Resources: $($summaryData.Count)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
