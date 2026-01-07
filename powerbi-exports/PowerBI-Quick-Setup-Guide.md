# Power BI Dashboard - Quick Setup Guide

## 🚀 5-Minute Setup (All Pre-Configured)

### Step 1: Import All DAX Measures (2 minutes)

1. **Open Power BI Desktop** (you already have your 14 tables loaded!)
2. **Open the DAX Measures file** in Notepad: `PowerBI-DAX-Measures.txt`
3. **For each measure** (copy/paste method):
   - Click **"Home"** ribbon → **"New Measure"**
   - Copy the measure formula from the text file
   - Paste into the formula bar
   - Press **Enter**
   - Repeat for all ~45 measures

**💡 PRO TIP:** The measures are grouped by section. Copy 5-10 at a time, create them in Power BI, then move to the next group.

---

### Step 2: Create Dashboard Pages (3 minutes)

I'll create each page layout for you below. Follow the visual placement guide.

---

## 📊 PAGE 1: Executive Summary

**Create New Page:** Click **"+"** at bottom, rename to **"Executive Summary"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Visual Type: Card
   - Field: `[Total Resources]`
   - Title: "Total Resources"

2. **Card Visual (Top Row, Middle-Left)**
   - Visual Type: Card
   - Field: `[Compliance Rate %]`
   - Title: "Policy Compliance"
   - Format: Show as percentage

3. **Card Visual (Top Row, Middle-Right)**
   - Visual Type: Card
   - Field: `[Health Score %]`
   - Title: "Health Score"
   - Format: Show as percentage

4. **Card Visual (Top Row, Right)**
   - Visual Type: Card
   - Field: `[Total Zombie Resources]`
   - Title: "Zombie Resources"
   - Conditional Formatting: Red if > 0

5. **Donut Chart (Middle Row, Left Half)**
   - Visual Type: Donut Chart
   - Legend: `01-resource-summary[type]`
   - Values: `[Total Resources]`
   - Title: "Resources by Type"

6. **Map Visual (Middle Row, Right Half)**
   - Visual Type: Map
   - Location: `13-location-distribution[location]`
   - Size: `[Total Resources]`
   - Title: "Geographic Distribution"

7. **Clustered Bar Chart (Bottom Row, Full Width)**
   - Visual Type: Clustered Bar Chart
   - Axis: `01-resource-summary[resourceGroup]`
   - Values: `[Total Resources]`
   - Title: "Top 10 Resource Groups"
   - Filter: Top 10 by Total Resources

---

## 🖥️ PAGE 2: Hardware Capacity

**Create New Page:** Rename to **"Hardware Capacity"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[Total CPU Cores]`
   - Title: "Total CPU Cores"

2. **Card Visual (Top Row, Middle)**
   - Field: `[Total Memory TB]`
   - Title: "Total Memory (TB)"

3. **Card Visual (Top Row, Right)**
   - Field: `[Total Nodes]`
   - Title: "Total Nodes"

4. **Card Visual (Top Row, Far Right)**
   - Field: `[Total Clusters]`
   - Title: "Total Clusters"

5. **Stacked Bar Chart (Middle Row, Full Width)**
   - Axis: `02-hardware-capacity[ClusterName]`
   - Values: `[Total CPU Cores]`, `[Total Memory TB]`
   - Title: "Capacity by Cluster"

6. **Treemap (Bottom Row, Left Half)**
   - Group: `02-hardware-capacity[ClusterName]`
   - Values: `[Total CPU Cores]`
   - Title: "CPU Distribution"

7. **Table (Bottom Row, Right Half)**
   - Columns: ClusterName, CPUCores, MemoryTB, NodeCount
   - Sort by: CPUCores descending
   - Title: "Cluster Details"

---

## 🔌 PAGE 3: Connectivity & Health

**Create New Page:** Rename to **"Connectivity & Health"**

### Add These Visuals:

1. **Gauge Visual (Top Row, Left)**
   - Value: `[Health Score %]`
   - Maximum: 100
   - Target: 95
   - Title: "Health Score"

2. **Card Visual (Top Row, Middle-Left)**
   - Field: `[Healthy Resources]`
   - Title: "Healthy"
   - Color: Green

3. **Card Visual (Top Row, Middle-Right)**
   - Field: `[Warning Resources]`
   - Title: "Warning"
   - Color: Orange

4. **Card Visual (Top Row, Right)**
   - Field: `[Critical Resources]`
   - Title: "Critical"
   - Color: Red

5. **Stacked Column Chart (Middle Row, Full Width)**
   - Axis: `03-connectivity-status[ResourceName]`
   - Values: Count of rows
   - Legend: `03-connectivity-status[HealthStatus]`
   - Title: "Health Status by Resource"
   - Colors: Green (Healthy), Orange (Warning), Red (Critical)

6. **Table (Bottom Row, Full Width)**
   - Columns: ResourceName, HealthStatus, LastSyncTime, HoursSinceSync
   - Filter: Show only Warning and Critical
   - Sort by: HoursSinceSync descending
   - Title: "Resources Requiring Attention"

---

## 🏷️ PAGE 4: Governance & Tags

**Create New Page:** Rename to **"Governance & Tags"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[Tag Compliance %]`
   - Title: "Tag Compliance"

2. **Card Visual (Top Row, Middle-Left)**
   - Field: `[Resources with Owner Tag]`
   - Title: "Has Owner Tag"

3. **Card Visual (Top Row, Middle-Right)**
   - Field: `[Resources with Environment Tag]`
   - Title: "Has Environment Tag"

4. **Card Visual (Top Row, Right)**
   - Field: `[Untagged Resources]`
   - Title: "Untagged Resources"
   - Color: Red

5. **Donut Chart (Middle Row, Left Half)**
   - Legend: Tag Status (Owner, Environment, CostCenter, None)
   - Values: Count of resources
   - Title: "Tag Compliance Breakdown"

6. **Table (Middle Row, Right Half)**
   - Columns: ResourceName, HasOwnerTag, HasEnvironmentTag, HasCostCenterTag
   - Filter: Show only untagged (False values)
   - Title: "Untagged Resources - Action Required"

7. **Stacked Bar Chart (Bottom Row, Full Width)**
   - Axis: `06-governance-tags[resourceGroup]`
   - Values: Count of resources
   - Legend: Tag status
   - Title: "Tag Compliance by Resource Group"

---

## 🛡️ PAGE 5: Security Posture

**Create New Page:** Rename to **"Security Posture"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[IMDS Enabled Count]`
   - Title: "IMDS Attestation Enabled"

2. **Card Visual (Top Row, Middle)**
   - Field: `[Entra ID Integrated]`
   - Title: "Entra ID Integrated"

3. **Card Visual (Top Row, Right)**
   - Field: `[Windows Server Subscription Enabled]`
   - Title: "Windows Server Subscription"

4. **Funnel Chart (Middle Row, Left Half)**
   - Values: 
     - Total Resources
     - IMDS Enabled Count
     - Entra ID Integrated
   - Title: "Security Feature Adoption Funnel"

5. **Clustered Bar Chart (Middle Row, Right Half)**
   - Axis: `05-security-posture[ResourceName]`
   - Values: Security features enabled (calculated)
   - Title: "Security Score by Resource"

6. **Table (Bottom Row, Full Width)**
   - Columns: ResourceName, ImdsAttestation, HasEntraIntegration, Status
   - Filter: Show resources missing security features
   - Title: "Security Gaps - Action Required"

---

## 📋 PAGE 6: Policy Compliance

**Create New Page:** Rename to **"Policy Compliance"**

### Add These Visuals:

1. **Gauge Visual (Top Row, Left)**
   - Value: `[Compliance Rate %]`
   - Maximum: 100
   - Target: 100
   - Title: "Compliance Rate"

2. **Card Visual (Top Row, Middle-Left)**
   - Field: `[Compliant Resources]`
   - Title: "Compliant"
   - Color: Green

3. **Card Visual (Top Row, Middle-Right)**
   - Field: `[Non-Compliant Resources]`
   - Title: "Non-Compliant"
   - Color: Red

4. **Clustered Bar Chart (Middle Row, Full Width)**
   - Axis: `07-policy-compliance[PolicyName]`
   - Values: Count of violations
   - Title: "Top Policy Violations"
   - Sort by: Count descending
   - Show Top 10

5. **Table (Bottom Row, Full Width)**
   - Columns: ResourceName, PolicyName, IsCompliant, Reason
   - Filter: Show only non-compliant (False)
   - Sort by: ResourceName
   - Title: "Non-Compliant Resources - Remediation Required"

---

## 🔌 PAGE 7: Arc Extensions

**Create New Page:** Rename to **"Arc Extensions"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[Total Extensions]`
   - Title: "Total Extensions"

2. **Card Visual (Top Row, Middle-Left)**
   - Field: `[Succeeded Extensions]`
   - Title: "Succeeded"
   - Color: Green

3. **Card Visual (Top Row, Middle-Right)**
   - Field: `[Failed Extensions]`
   - Title: "Failed"
   - Color: Red

4. **Card Visual (Top Row, Right)**
   - Field: `[Extension Success Rate %]`
   - Title: "Success Rate"

5. **Donut Chart (Middle Row, Left Half)**
   - Legend: `08-arc-extensions[Status]`
   - Values: Count
   - Title: "Extension Status Distribution"
   - Colors: Green (Succeeded), Red (Failed), Blue (Updating)

6. **Clustered Bar Chart (Middle Row, Right Half)**
   - Axis: `08-arc-extensions[ExtensionType]`
   - Values: Count
   - Legend: Status
   - Title: "Status by Extension Type"

7. **Table (Bottom Row, Full Width)**
   - Columns: ResourceName, ExtensionType, Status, Version
   - Filter: Show only Failed status
   - Sort by: ExtensionType
   - Title: "Failed Extensions - Action Required"

---

## 💰 PAGE 8: Cost Optimization - Zombies

**Create New Page:** Rename to **"Cost Optimization"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[Total Zombie Resources]`
   - Title: "Total Zombie Resources"
   - Color: Red

2. **Card Visual (Top Row, Middle-Left)**
   - Field: `[Zombie 30-60 Days]`
   - Title: "30-60 Days (Review)"
   - Color: Yellow

3. **Card Visual (Top Row, Middle-Right)**
   - Field: `[Zombie 60-90 Days]`
   - Title: "60-90 Days (Delete Soon)"
   - Color: Orange

4. **Card Visual (Top Row, Right)**
   - Field: `[Zombie 90+ Days]`
   - Title: "90+ Days (DELETE NOW)"
   - Color: Red

5. **Stacked Column Chart (Middle Row, Full Width)**
   - Axis: `12-zombie-resources[ResourceName]`
   - Values: DaysDisconnected
   - Legend: ZombieCategory
   - Title: "Zombie Resources by Age"
   - Colors: Yellow (30-60), Orange (60-90), Red (90+)

6. **Table (Bottom Row, Full Width)**
   - Columns: ResourceName, ResourceType, DaysDisconnected, LastSyncTime, ZombieCategory
   - Sort by: DaysDisconnected descending
   - Title: "Zombie Resource Deletion Candidates"
   - Conditional Formatting: Red highlight for 90+ days

---

## 🌍 PAGE 9: Cost Optimization - Regions

**Create New Page:** Rename to **"Regional Costs"**

### Add These Visuals:

1. **Card Visual (Top Row, Left)**
   - Field: `[Resources in Expensive Regions]`
   - Title: "Resources in Expensive Regions"
   - Color: Red

2. **Card Visual (Top Row, Middle)**
   - Field: `[Resources in Standard Regions]`
   - Title: "Resources in Standard Regions"
   - Color: Green

3. **Card Visual (Top Row, Right)**
   - Field: `[Expensive Region Cost Impact %]`
   - Title: "Cost Impact %"

4. **Map Visual (Middle Row, Left Half)**
   - Location: `13-location-distribution[location]`
   - Size: Count of resources
   - Color: IsExpensiveRegion (Red = expensive, Green = standard)
   - Title: "Resource Distribution by Region Cost"

5. **Clustered Bar Chart (Middle Row, Right Half)**
   - Axis: `13-location-distribution[location]`
   - Values: Count of resources
   - Color: IsExpensiveRegion
   - Title: "Resources per Region"
   - Sort by: Count descending

6. **Table (Bottom Row, Full Width)**
   - Columns: location, ResourceCount, IsExpensiveRegion, CostMultiplier
   - Filter: Show only expensive regions (True)
   - Sort by: ResourceCount descending
   - Title: "Expensive Regions - Migration Candidates"

---

## 🎨 Final Touches

### Apply Theme:
1. Go to **View** ribbon → **Themes**
2. Choose **"Dark"** or **"Blue"** for professional look

### Enable Drill-Through:
1. Right-click any visual with resource names
2. Select **"Drill Through"** → **"See Details"**
3. This creates automatic detail pages

### Add Slicers (Filters):
Add these slicers to **Page 1** for filtering all pages:
- Slicer: `01-resource-summary[resourceGroup]`
- Slicer: `01-resource-summary[location]`
- Slicer: `01-resource-summary[type]`

Position slicers in left sidebar, make them sync across all pages:
- Select slicer → **View** ribbon → **Sync Slicers**
- Check all pages

---

## ⚡ Automation & Refresh

### Set Up Auto-Refresh:
1. **File** → **Options and Settings** → **Options**
2. **Data Load** → Check **"Background Data"**
3. **File** → **Publish to Power BI Service** (if you have Pro license)
4. In Power BI Service: Set scheduled refresh to run `Export-ToPowerBI.ps1` daily

### Manual Refresh Process:
```powershell
# Run this in PowerShell to update data
cd C:\AI\adaptive-cloud-health-dashboard
.\scripts\powerbi\Export-ToPowerBI.ps1
```

Then in Power BI Desktop:
- Click **"Refresh"** button in Home ribbon
- All visuals update automatically!

---

## 📝 Save Your Work

1. **File** → **Save As**
2. Save as: `Adaptive-Cloud-Dashboard.pbix`
3. Location: `C:\AI\adaptive-cloud-health-dashboard\powerbi-exports\`

---

## 🎉 You're Done!

You now have a complete replica of your Azure Workbook with:
- ✅ 9 dashboard pages
- ✅ 45+ calculated measures
- ✅ Interactive filtering
- ✅ Better visuals than Azure Workbook
- ✅ Drill-through capabilities
- ✅ Auto-refresh support

**Next Steps:**
1. Explore each page
2. Click on charts to filter related visuals
3. Use slicers to focus on specific resource groups
4. Right-click resources to drill into details
5. Share with your team!

---

## 🆘 Troubleshooting

**Issue: Measures show errors**
- Check that table names match exactly (case-sensitive)
- Verify column names have no spaces (use `[ColumnName]` syntax)

**Issue: Visuals show wrong data**
- Ensure "Don't summarize" is NOT selected
- Use "Sum" or "Count" aggregation

**Issue: Relationships not working**
- Go to **Model View** → Verify relationships exist between tables
- Create relationships: Drag ResourceId/Name columns between tables

**Issue: Refresh fails**
- Re-run `Export-ToPowerBI.ps1` to regenerate CSVs
- Check file paths in Power Query Editor

---

**Need help?** Check the console output from the export script for any warnings or errors.
