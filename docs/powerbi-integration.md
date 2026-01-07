# Power BI Integration Guide

## Overview

Export your Adaptive Cloud inventory data from Azure Resource Graph to Power BI for advanced analytics, custom dashboards, and automated reporting.

**Cost:** 100% FREE - uses Azure Resource Graph API (no charges)

## Quick Start

### 1. Export Data from Azure

```powershell
# Navigate to the scripts directory
cd scripts/powerbi

# Run the export script
.\Export-ToPowerBI.ps1 -OpenOutputFolder
```

This creates CSV files in `powerbi-exports/` directory with all your inventory data.

### 2. Import to Power BI Desktop

1. **Open Power BI Desktop**
2. **Get Data** → **Text/CSV**
3. **Import each CSV file** from the export folder
4. **Load** the data

### 3. Create Relationships

In Power BI, go to **Model View** and create relationships:

| From Table | From Column | To Table | To Column |
|------------|-------------|----------|-----------|
| Resource Summary | ResourceId | Connectivity Status | ResourceId |
| Resource Summary | SubscriptionId | Policy Compliance | SubscriptionId |
| Hardware Capacity | ClusterName | Configuration | ClusterName |
| Arc Extensions | ParentResource | Resource Summary | ResourceName |

### 4. Build Your Dashboards!

Use the pre-built template or create custom visuals.

---

## Exported Data Files

### Core Inventory

| File | Description | Key Metrics |
|------|-------------|-------------|
| `01-resource-summary.csv` | All resources inventory | Resource counts by type, subscription, location |
| `02-hardware-capacity.csv` | Azure Local hardware | CPU cores, memory (TB), nodes per cluster |
| `03-connectivity-status.csv` | Connection health | Last sync time, health status (Healthy/Warning/Critical) |
| `11-resource-lifecycle.csv` | Resource age analysis | Creation dates, days old, age categories |

### Configuration & Compliance

| File | Description | Key Metrics |
|------|-------------|-------------|
| `04-configuration.csv` | Azure Local config | Billing model, Windows sub, Software Assurance |
| `05-security-posture.csv` | Security features | IMDS, Isolated VM, Entra ID integration |
| `06-governance-tags.csv` | Tag compliance | Owner, Environment, CostCenter tags |
| `07-policy-compliance.csv` | Policy violations | Compliance state, policy names |

### Operational Insights

| File | Description | Key Metrics |
|------|-------------|-------------|
| `08-arc-extensions.csv` | Extension inventory | Extension status (Succeeded/Failed), types, versions |
| `09-kubernetes-versions.csv` | K8s version tracking | Kubernetes versions, distributions, agent versions |
| `10-arc-agent-versions.csv` | Arc agent versions | Agent versions, OS types |

### Cost Optimization

| File | Description | Key Metrics |
|------|-------------|-------------|
| `12-zombie-resources.csv` | Disconnected resources | Days disconnected, zombie categories (30/60/90+ days) |
| `13-location-distribution.csv` | Regional costs | Expensive regions (20-30% premium) |
| `14-rightsizing.csv` | Server sizing | CPU/memory, size categories (Small/Medium/Large) |

---

## Power BI Best Practices

### DAX Measures

#### Total Resources
```dax
Total Resources = COUNTROWS('Resource Summary')
```

#### Compliance Rate
```dax
Compliance Rate = 
DIVIDE(
    COUNTROWS(FILTER('Policy Compliance', 'Policy Compliance'[IsCompliant] = TRUE)),
    COUNTROWS('Policy Compliance'),
    0
) * 100
```

#### Critical Connections
```dax
Critical Connections = 
COUNTROWS(
    FILTER('Connectivity Status', 'Connectivity Status'[HealthStatus] = "Critical")
)
```

#### Zombie Resource Cost Risk
```dax
Zombie Resources = 
COUNTROWS(
    FILTER('Zombie Resources', 'Zombie Resources'[DaysDisconnected] >= 90)
)
```

#### Tag Compliance
```dax
Tag Compliance % = 
DIVIDE(
    COUNTROWS(FILTER('Governance Tags', 'Governance Tags'[HasOwnerTag] = TRUE)),
    COUNTROWS('Governance Tags'),
    0
) * 100
```

#### Total Hardware Capacity
```dax
Total CPU Cores = SUM('Hardware Capacity'[CPUCores])
Total Memory TB = SUM('Hardware Capacity'[MemoryTB])
```

### Recommended Visuals

#### Executive Dashboard Page
- **Card**: Total Resources, Compliance Rate %, Critical Connections
- **Pie Chart**: Resources by Type
- **Map**: Resources by Location
- **Line Chart**: Resources Created by Month

#### Health & Operations Page
- **Gauge**: Connectivity Health (% Healthy)
- **Table**: Critical/Warning connections with last sync times
- **Stacked Bar**: Extension Status (Succeeded/Failed/Updating)
- **Clustered Bar**: Top Policy Violations

#### Cost Optimization Page
- **Card**: Zombie Resources (90+ days), Resources in Expensive Regions
- **Waterfall Chart**: Cost reduction opportunities
- **Table**: Zombie resources with days disconnected, resource group
- **Matrix**: Region distribution with cost categories

#### Hardware Capacity Page
- **Card**: Total CPU Cores, Total Memory TB, Total Nodes
- **Clustered Column**: CPU/Memory by Cluster
- **Treemap**: Clusters by size category

#### Governance & Security Page
- **Donut Chart**: Tag Compliance (Owner/Environment/CostCenter)
- **Funnel**: Security feature adoption (IMDS, Isolated VM, Entra ID)
- **Table**: Untagged resources (IsUntagged = true)

---

## Automation & Refresh

### Schedule Automatic Exports

Create a scheduled task to export data daily:

```powershell
# Create daily export task
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\AI\adaptive-cloud-health-dashboard\scripts\powerbi\Export-ToPowerBI.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "Adaptive Cloud - Power BI Export" `
    -Description "Daily export of Adaptive Cloud inventory to Power BI"
```

### Power BI Automatic Refresh

#### Option 1: Manual Refresh in Power BI Desktop
1. Open your `.pbix` file
2. **Home** → **Refresh**
3. Power BI re-imports the latest CSV files

#### Option 2: Power BI Service (Pro/Premium)
1. Publish to Power BI Service
2. Configure **Scheduled Refresh** in dataset settings
3. Use **On-Premises Data Gateway** to access local CSV files

#### Option 3: Direct Query to Azure (Advanced)
Instead of CSV files, connect Power BI directly to Azure Resource Graph using Power Query M:

```m
let
    Source = AzureResourceGraph.Query(
        "Resources
        | where type in ('microsoft.azurestackhci/clusters', 'microsoft.kubernetes/connectedclusters')
        | project name, type, location, subscriptionId"
    )
in
    Source
```

**Note:** Requires Power BI Premium or Azure-enabled data source.

---

## Advanced: Power Query Transformations

### Merge Last Sync Time with Resource Summary

```m
= Table.NestedJoin(
    #"Resource Summary", {"ResourceId"}, 
    #"Connectivity Status", {"ResourceId"}, 
    "Connectivity", JoinKind.LeftOuter
)
```

### Calculate Days Since Last Sync

```m
= Table.AddColumn(
    #"Previous Step", 
    "Days Since Sync", 
    each Duration.Days(DateTime.LocalNow() - [LastSyncTime])
)
```

### Categorize Expensive Regions

```m
= Table.AddColumn(
    #"Previous Step",
    "Cost Tier",
    each if List.Contains(
        {"australiaeast", "australiasoutheast", "brazilsouth", "japaneast", "japanwest", "uksouth", "ukwest"},
        [Location]
    ) then "Expensive (20-30% premium)" else "Standard Cost"
)
```

---

## Troubleshooting

### "No data exported"
**Solution:** Verify Azure CLI is logged in and has access to subscriptions:
```powershell
az login
az account list --output table
```

### "CSV import failed"
**Solution:** Ensure files are UTF-8 encoded. Re-run export script.

### "Relationships not working"
**Solution:** Check column names match exactly. Use **Manage Relationships** in Power BI Model View.

### "Performance issues with large datasets"
**Solution:** 
1. Use **Import Mode** instead of DirectQuery for CSVs
2. Create aggregated summary tables
3. Apply filters to reduce row counts

---

## Sample Power BI Reports

### KPI Scorecard
```
╔════════════════════════════════════════════════════════╗
║  Total Resources: 57          Compliance: 92%         ║
║  Azure Local: 21              AKS Arc: 15             ║
║  Critical Alerts: 3           Zombie Resources: 5     ║
╚════════════════════════════════════════════════════════╝
```

### Health Status Matrix
| Resource Type | Healthy | Warning | Critical |
|--------------|---------|---------|----------|
| Azure Local  | 18      | 2       | 1        |
| AKS Arc      | 14      | 1       | 0        |
| Arc Servers  | 15      | 3       | 3        |

### Top Cost Optimization Opportunities
1. **5 Zombie Resources** (90+ days disconnected) - Delete to save management costs
2. **8 Resources in Expensive Regions** - Migrate to standard cost regions (20-30% savings)
3. **12 Untagged Resources** - Add tags for accurate cost allocation
4. **4 Large Servers** - Review for right-sizing opportunities

---

## Next Steps

1. **Run the export**: `.\Export-ToPowerBI.ps1 -OpenOutputFolder`
2. **Open Power BI Desktop** and import CSV files
3. **Use pre-built template** (coming soon: `templates/powerbi/adaptive-cloud-template.pbit`)
4. **Customize visuals** to match your reporting needs
5. **Schedule automatic exports** for daily/weekly updates
6. **Publish to Power BI Service** for team sharing

---

## Cost Comparison

| Solution | Cost | Setup Time | Data Freshness |
|----------|------|------------|----------------|
| **Azure Workbook** | $0 | 5 min | Real-time |
| **Power BI (CSV Export)** | $0 | 15 min | On-demand refresh |
| **Power BI Service (Pro)** | $10/user/month | 30 min | Scheduled (up to 8x daily) |
| **Power BI Premium** | $5,000/month | 1 hour | Real-time DirectQuery |

**Recommendation:** Start with CSV exports (FREE) and upgrade to Power BI Pro if you need scheduled refreshes and team collaboration.

---

## Support

For issues or questions:
- Check Azure CLI is logged in: `az account show`
- Verify Resource Graph access: `az graph query -q "Resources | take 5"`
- Review export logs in PowerShell output
- Open an issue on GitHub with error details
