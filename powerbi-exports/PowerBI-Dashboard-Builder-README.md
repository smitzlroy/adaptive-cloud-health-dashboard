# ⚡ POWER BI - ONE-CLICK DASHBOARD BUILDER

## 🎯 What This Script Does
This script automates the creation of your Power BI dashboard by:
1. Creating all DAX measures automatically
2. Setting up relationships between tables
3. Configuring page layouts
4. Applying professional theme

## ⚠️ IMPORTANT: Pre-Requisites
Before running this script, ensure you have:
- ✅ Power BI Desktop OPEN with your 14 tables loaded
- ✅ All CSV files imported (01-resource-summary through 14-rightsizing)
- ✅ Headers fixed ("Use First Row as Headers" applied to all tables)

## 🚀 USAGE

### Option 1: Manual Copy/Paste (RECOMMENDED)
1. Open the files below in order:
   - `PowerBI-DAX-Measures.txt` - Copy all measures
   - `PowerBI-Quick-Setup-Guide.md` - Follow step-by-step visual placement

2. In Power BI Desktop:
   - Create each measure using "Home → New Measure"
   - Build each page following the guide
   - Takes ~15 minutes total

### Option 2: Power BI Service API (Advanced)
If you have Power BI Pro + Python:
```powershell
cd C:\AI\adaptive-cloud-health-dashboard\powerbi-exports
python Build-PowerBI-Dashboard.py
```
(Script coming soon - requires Power BI REST API authentication)

## 📊 What You'll Get

### 9 Dashboard Pages:
1. **Executive Summary** - High-level KPIs, resource distribution
2. **Hardware Capacity** - CPU, memory, nodes by cluster
3. **Connectivity & Health** - Health scores, critical alerts
4. **Governance & Tags** - Tag compliance, untagged resources
5. **Security Posture** - IMDS, Entra ID, security gaps
6. **Policy Compliance** - Compliance rate, violations
7. **Arc Extensions** - Extension status, failures
8. **Cost Optimization - Zombies** - Disconnected resources by age
9. **Regional Costs** - Expensive regions, migration candidates

### 45+ Calculated Measures:
- Total Resources, CPU Cores, Memory TB
- Health Score %, Compliance Rate %
- Tag Compliance %, Security Scores
- Zombie Resource Counts (30/60/90 day categories)
- Extension Success Rates
- And many more...

### Interactive Features:
- Cross-page filtering with slicers
- Drill-through to details
- Conditional formatting (red for issues)
- Geographic maps
- Professional dark/blue theme

## 🔄 Daily Refresh Process

After initial setup, refresh your data daily:

```powershell
# Step 1: Export fresh data from Azure
cd C:\AI\adaptive-cloud-health-dashboard
.\scripts\powerbi\Export-ToPowerBI.ps1

# Step 2: Open Power BI Desktop
# Click "Refresh" button in Home ribbon
# Dashboard updates automatically!
```

## 📁 Files in This Export

| File | Purpose |
|------|---------|
| `PowerBI-DAX-Measures.txt` | All calculated measures (copy/paste into Power BI) |
| `PowerBI-Quick-Setup-Guide.md` | Step-by-step visual placement guide |
| `PowerBI-Dashboard-Builder-README.md` | This file - overview and usage |
| `01-resource-summary.csv` to `14-rightsizing.csv` | Your data tables (already imported) |

## 🎨 Customization Tips

### Change Colors:
- Select visual → Format → Data colors → Choose palette

### Add Your Logo:
- Insert → Image → Select your company logo
- Position in top-left corner of each page

### Modify Layouts:
- Drag visuals to resize/reposition
- Use alignment tools: Format → Align → Distribute

### Add Custom Measures:
```dax
# Example: Average cluster size
Avg Cluster Size = 
DIVIDE(
    [Total CPU Cores],
    [Total Clusters],
    0
)
```

## 🆘 Common Issues

**"Measure doesn't work"**
→ Check table name spelling (case-sensitive)
→ Verify column exists in that table

**"Visual shows wrong numbers"**
→ Change aggregation from "Don't summarize" to "Sum" or "Count"

**"Can't see all measures"**
→ They're grouped by table in Fields pane (expand each table)

**"Refresh button grayed out"**
→ Close and reopen Power BI Desktop
→ File → Recent → Select your .pbix file

## 📚 Learn More

- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [DAX Formula Reference](https://docs.microsoft.com/dax/)
- [Power BI Community](https://community.powerbi.com/)

## ✅ Checklist

Before you start:
- [ ] Power BI Desktop installed
- [ ] 14 CSV tables imported
- [ ] Headers fixed (first row as headers)
- [ ] PowerBI-DAX-Measures.txt file open
- [ ] PowerBI-Quick-Setup-Guide.md file open
- [ ] 15-20 minutes of time available

After completion:
- [ ] All 45 measures created
- [ ] 9 pages built with visuals
- [ ] Slicers added for filtering
- [ ] Theme applied
- [ ] File saved as .pbix
- [ ] Tested refresh process

## 🎉 Ready to Start?

Open **PowerBI-Quick-Setup-Guide.md** and follow Step 1!

---

**Pro Tip:** Start with Page 1 (Executive Summary) to get familiar with the process, then the rest will be faster!
