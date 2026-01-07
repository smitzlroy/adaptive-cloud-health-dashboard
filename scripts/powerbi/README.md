# Power BI Integration - Quick Start

## 🎯 Overview

Export your Adaptive Cloud inventory from Azure to Power BI for advanced analytics and custom dashboards.

**Cost:** 100% FREE (uses Azure Resource Graph API)

---

## ⚡ Quick Start (3 Steps)

### Step 1: Export Data from Azure

```powershell
cd scripts/powerbi
.\Export-ToPowerBI.ps1 -OpenOutputFolder
```

**Result:** 14 CSV files created in `powerbi-exports/` folder

### Step 2: Generate Power BI Import Script

```powershell
.\Generate-PowerBIModel.ps1 -CsvPath "..\..\powerbi-exports"
```

**Result:** Creates `PowerBI-DataModel.m` script for automatic import

### Step 3: Import to Power BI

1. Open **Power BI Desktop**
2. **Get Data** → **Blank Query**
3. **Home** → **Advanced Editor**
4. Copy & paste contents from `powerbi-exports/PowerBI-DataModel.m`
5. Click **Done**
6. Expand the **Output** record in Queries pane
7. **Load** all tables

Done! All 14 tables are now imported.

---

## 📊 What Data Gets Exported?

| Category | Tables | Key Metrics |
|----------|--------|-------------|
| **Inventory** | Resource Summary, Hardware Capacity, Connectivity | Resource counts, CPU/memory, health status |
| **Compliance** | Configuration, Security, Tags, Policy | Billing models, security features, tag compliance |
| **Operations** | Extensions, K8s Versions, Agent Versions | Extension status, version tracking |
| **Cost Optimization** | Zombie Resources, Location, Right-Sizing | Disconnected resources, expensive regions, oversized servers |

---

## 🔄 Automatic Refresh

### Schedule Daily Exports

```powershell
# Create scheduled task (runs daily at 6 AM)
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\AI\adaptive-cloud-health-dashboard\scripts\powerbi\Export-ToPowerBI.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "Adaptive Cloud - Power BI Export" `
    -Description "Daily export of Adaptive Cloud inventory"
```

### Refresh in Power BI

- **Power BI Desktop:** Click **Home** → **Refresh**
- **Power BI Service:** Configure **Scheduled Refresh** (requires Pro license)

---

## 📈 Sample Reports

### Executive Dashboard
- **Cards:** Total Resources (57), Compliance (92%), Critical Alerts (3)
- **Pie Chart:** Resources by Type (Azure Local, AKS Arc, Arc Servers)
- **Map:** Geographic Distribution

### Health & Operations
- **Gauge:** Connectivity Health (% Healthy)
- **Table:** Critical/Warning Resources with last sync times
- **Bar Chart:** Extension Status (Succeeded/Failed/Updating)

### Cost Optimization
- **Cards:** Zombie Resources (5), Expensive Regions (8)
- **Table:** Deletion Candidates (90+ days disconnected)
- **Matrix:** Regional cost analysis with 20-30% premium regions

---

## 📁 Files Generated

```
powerbi-exports/
├── 01-resource-summary.csv         # All resources inventory
├── 02-hardware-capacity.csv        # CPU, memory, nodes
├── 03-connectivity-status.csv      # Last sync, health status
├── 04-configuration.csv            # Billing, subscriptions
├── 05-security-posture.csv         # IMDS, Entra ID
├── 06-governance-tags.csv          # Tag compliance
├── 07-policy-compliance.csv        # Policy violations
├── 08-arc-extensions.csv           # Extension status
├── 09-kubernetes-versions.csv      # K8s versions
├── 10-arc-agent-versions.csv       # Arc agent versions
├── 11-resource-lifecycle.csv       # Resource age
├── 12-zombie-resources.csv         # Disconnected resources
├── 13-location-distribution.csv    # Regional costs
├── 14-rightsizing.csv              # Server sizing
├── PowerBI-DataModel.m             # Import script
├── PowerBI-Relationships.txt       # Relationship guide
└── PowerBI-QuickReference.txt      # Quick reference card
```

---

## 💡 Key DAX Measures

Copy these into Power BI to get started:

```dax
// Total Resources
Total Resources = COUNTROWS('ResourceSummary')

// Compliance Rate
Compliance Rate = 
DIVIDE(
    COUNTROWS(FILTER('PolicyCompliance', 'PolicyCompliance'[IsCompliant] = "True")),
    COUNTROWS('PolicyCompliance'), 0
) * 100

// Critical Connections
Critical Connections = 
COUNTROWS(FILTER('ConnectivityStatus', 'ConnectivityStatus'[HealthStatus] = "Critical"))

// Zombie Resources
Zombie Resources = 
COUNTROWS(FILTER('ZombieResources', VALUE('ZombieResources'[DaysDisconnected]) >= 90))

// Tag Compliance
Tag Compliance % = 
DIVIDE(
    COUNTROWS(FILTER('GovernanceTags', 'GovernanceTags'[HasOwnerTag] = "True")),
    COUNTROWS('GovernanceTags'), 0
) * 100
```

---

## 🔗 Recommended Relationships

Create these in **Model View**:

| From Table | Column | To Table | Column |
|------------|--------|----------|--------|
| ResourceSummary | ResourceId | ConnectivityStatus | ResourceId |
| ResourceSummary | ResourceName | HardwareCapacity | ClusterName |
| ResourceSummary | ResourceName | Configuration | ClusterName |
| ResourceSummary | ResourceName | ArcExtensions | ParentResource |
| ResourceSummary | SubscriptionId | PolicyCompliance | SubscriptionId |

See `powerbi-exports/PowerBI-Relationships.txt` for complete list.

---

## 🆚 Comparison: Workbook vs Power BI

| Feature | Azure Workbook | Power BI |
|---------|---------------|----------|
| **Cost** | $0 | $0 (Desktop) / $10/user (Pro) |
| **Data Freshness** | Real-time | On-demand refresh |
| **Customization** | Limited | Unlimited |
| **Sharing** | Azure Portal link | .pbix file / Power BI Service |
| **Advanced Analytics** | Basic | Advanced (DAX, AI visuals) |
| **Export** | Limited | Excel, PDF, PowerPoint |

**Recommendation:** Use both!
- **Workbook:** Quick real-time checks in Azure Portal
- **Power BI:** Executive reports, trend analysis, custom dashboards

---

## 🛠 Troubleshooting

### "No data exported"
```powershell
# Verify Azure CLI login
az login
az account show
```

### "CSV import failed"
Re-run export with UTF-8 encoding (already default)

### "Performance issues"
- Use **Import Mode** (not DirectQuery)
- Filter date ranges in queries
- Create aggregated tables

---

## 📚 Full Documentation

- **Complete Guide:** [docs/powerbi-integration.md](../../docs/powerbi-integration.md)
- **Advanced Techniques:** DAX measures, Power Query transformations
- **Automation:** Scheduled exports, Power BI Service refresh

---

## ✅ Next Steps

1. ✅ Export data: `.\Export-ToPowerBI.ps1`
2. ✅ Generate model: `.\Generate-PowerBIModel.ps1`
3. ✅ Import to Power BI Desktop
4. ⏭️ Create relationships (use guide)
5. ⏭️ Add DAX measures
6. ⏭️ Build custom visuals
7. ⏭️ Schedule daily exports
8. ⏭️ Publish to Power BI Service (optional)

---

**Questions?** Check `powerbi-exports/PowerBI-QuickReference.txt` for common tasks and tips.
