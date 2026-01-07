# Deployment Scripts

Two deployment options for the Adaptive Cloud Health Dashboard.

---

## 🎯 Choose Your Deployment

### Option 1: Inventory Dashboard (FREE) ⭐

**Deploy inventory-only dashboard with zero cost:**

```powershell
.\Deploy-Inventory-Dashboard.ps1
```

**What you get:**
- Resource inventory across subscriptions
- Policy compliance tracking
- Tag analysis
- Resource counts and lists
- **NO COST** - uses Azure Resource Graph (free)
- **NO AGENTS** required

**Best for:** Quick inventory, compliance view, evaluating the solution

---

### Option 2: Full Dashboard (PAID) 💰

**Deploy complete monitoring with performance metrics:**

```powershell
.\Deploy-Full-Dashboard.ps1
```

**What you get:**
- Everything from Inventory Dashboard PLUS:
- Performance metrics (CPU, Memory, Disk, Network)
- VM health monitoring and heartbeat
- Custom application metrics
- Detailed diagnostics and logging

**Requirements:**
- Log Analytics workspace (~$2.30/GB ingestion)
- Azure Monitor Agent on ALL monitored VMs
- Data Collection Rules

**Estimated costs:** $100-500+/month depending on scale

**Best for:** Production monitoring, alerting, performance tracking

---

## 📋 Prerequisites (Both Options)

1. **Azure CLI** installed
   ```powershell
   az --version
   ```

2. **PowerShell 7+**
   ```powershell
   $PSVersionTable.PSVersion
   ```

3. **Azure Authentication**
   ```powershell
   az login
   ```

4. **Configuration file created**
   ```powershell
   Copy-Item .\config.template.json .\config.json
   # Edit config.json with your subscription ID
   ```

---

## 🚀 Quick Start

### Inventory Dashboard Deployment

```powershell
# 1. Login
az login

# 2. Create config
Copy-Item .\config.template.json .\config.json
code .\config.json  # Edit with your subscription ID

# 3. Deploy
.\Deploy-Inventory-Dashboard.ps1
```

**Deployment time:** ~2-5 minutes

**Resources created:**
- Resource Group (if doesn't exist)
- Azure Workbook (Inventory Dashboard)

---

### Full Dashboard Deployment

```powershell
# 1. Login
az login

# 2. Create config
Copy-Item .\config.template.json .\config.json
code .\config.json  # Edit with your subscription ID

# 3. Deploy (you'll see cost warning)
.\Deploy-Full-Dashboard.ps1
# Type 'yes' to confirm deployment

# 4. Install agents on target VMs (see below)
```

**Deployment time:** ~15-20 minutes

**Resources created:**
- Resource Group
- Log Analytics Workspace
- Data Collection Rules
- Azure Workbook (Full Dashboard)

---

## ⚙️ Configuration File

### config.json Structure

```json
{
  "subscriptions": [
    "12345678-1234-1234-1234-123456789abc"
  ],
  "resourceGroup": "rg-adaptive-cloud-dashboard",
  "location": "eastus",
  "logAnalytics": {
    "name": "law-adaptive-cloud",
    "sku": "PerGB2018",
    "retentionDays": 30
  },
  "tags": {
    "environment": "production",
    "solution": "adaptive-cloud-dashboard"
  }
}
```

### Configuration Reference

| Setting | Required | Description | Example |
|---------|----------|-------------|---------|
| `subscriptions` | ✅ | Array of subscription IDs to monitor | `["sub-1", "sub-2"]` |
| `resourceGroup` | ✅ | Resource group name | `"rg-dashboard"` |
| `location` | ✅ | Azure region | `"eastus"`, `"westus2"` |
| `logAnalytics.name` | Full only | Workspace name | `"law-workspace"` |
| `logAnalytics.sku` | Full only | Pricing tier | `"PerGB2018"` |
| `logAnalytics.retentionDays` | Full only | Data retention (30-730) | `30`, `90`, `365` |
| `tags` | Optional | Resource tags | `{"env": "prod"}` |

**Note:** `logAnalytics` settings are only used by `Deploy-Full-Dashboard.ps1`.

---

## 🛠️ Script Parameters

### Deploy-Inventory-Dashboard.ps1

```powershell
# Basic deployment
.\Deploy-Inventory-Dashboard.ps1

# Custom config file
.\Deploy-Inventory-Dashboard.ps1 -ConfigFile .\my-config.json

# Test mode (dry run)
.\Deploy-Inventory-Dashboard.ps1 -TestMode
```

### Deploy-Full-Dashboard.ps1

```powershell
# Basic deployment (will prompt for confirmation)
.\Deploy-Full-Dashboard.ps1

# Custom config file
.\Deploy-Full-Dashboard.ps1 -ConfigFile .\my-config.json

# Skip workbook import
.\Deploy-Full-Dashboard.ps1 -SkipWorkbooks

# Test mode (dry run)
.\Deploy-Full-Dashboard.ps1 -TestMode
```

---

## 📊 Post-Deployment Steps

### For Inventory Dashboard

✅ **You're done!** Access your dashboard:

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Monitor** → **Workbooks**
3. Find **"Adaptive Cloud - Inventory Dashboard"**

---

### For Full Dashboard

⚠️ **Additional steps required** - the dashboard won't show data until agents are installed.

#### Step 1: Verify Deployment

```powershell
# List deployed resources
az resource list --resource-group rg-adaptive-cloud-dashboard --output table

# Get workspace details
az monitor log-analytics workspace show \
  --resource-group rg-adaptive-cloud-dashboard \
  --workspace-name law-adaptive-cloud
```

#### Step 2: Install Azure Monitor Agent

**On Windows Arc machines:**
```powershell
az connectedmachine extension create \
  --machine-name <machine-name> \
  --resource-group <machine-resource-group> \
  --name AzureMonitorWindowsAgent \
  --publisher Microsoft.Azure.Monitor \
  --type AzureMonitorWindowsAgent \
  --location <location>
```

**On Linux Arc machines:**
```powershell
az connectedmachine extension create \
  --machine-name <machine-name> \
  --resource-group <machine-resource-group> \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --type AzureMonitorLinuxAgent \
  --location <location>
```

**Batch install on multiple machines:**
```powershell
# Get list of Arc machines
$machines = az connectedmachine list --query "[].{name:name, rg:resourceGroup, location:location}" -o json | ConvertFrom-Json

# Install agent on each
foreach ($machine in $machines) {
    az connectedmachine extension create `
      --machine-name $machine.name `
      --resource-group $machine.rg `
      --name AzureMonitorWindowsAgent `
      --publisher Microsoft.Azure.Monitor `
      --type AzureMonitorWindowsAgent `
      --location $machine.location
}
```

#### Step 3: Associate Data Collection Rules

```powershell
# Get your DCR ID (from deployment output or portal)
$dcrId = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Insights/dataCollectionRules/dcr-adaptive-cloud"

# Associate with a machine
$machineId = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.HybridCompute/machines/<machine-name>"

az monitor data-collection rule association create \
  --name "configurationAccessEndpoint" \
  --rule-id $dcrId \
  --resource $machineId
```

#### Step 4: Verify Data Collection

Wait 5-10 minutes, then check if data is flowing:

```powershell
# Query for heartbeat data
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "Heartbeat | take 10" \
  --timespan P1D
```

---

## 🔄 Upgrade Path

### From Inventory to Full Dashboard

Already deployed the **Inventory Dashboard**? Upgrade to **Full Dashboard** anytime:

```powershell
# Simply run the Full Dashboard deployment
.\Deploy-Full-Dashboard.ps1
```

Both dashboards will coexist in the same resource group. Use whichever fits your needs.

---

## ❓ Troubleshooting

### "Azure CLI not found"

Install Azure CLI:
- Windows: https://aka.ms/installazurecliwindows
- macOS: `brew install azure-cli`
- Linux: https://docs.microsoft.com/cli/azure/install-azure-cli-linux

### "Not logged in to Azure"

```powershell
az login
az account set --subscription <your-subscription-id>
```

### "Configuration file not found"

```powershell
# Ensure you're in scripts/deployment directory
cd c:\AI\adaptive-cloud-health-dashboard\scripts\deployment

# Create config from template
Copy-Item .\config.template.json .\config.json
```

### "Workbook deployment failed"

Install the application-insights extension:
```powershell
az extension add --name application-insights
```

### "Permission denied"

Ensure your account has:
- **Contributor** or **Owner** role on the subscription
- **Log Analytics Contributor** role (for Full Dashboard)

Check your role assignments:
```powershell
az role assignment list --assignee <your-email> --output table
```

### "Data Collection Rule association failed"

Verify the DCR exists:
```powershell
az monitor data-collection rule show --name dcr-adaptive-cloud --resource-group <rg>
```

Verify the agent is installed:
```powershell
az connectedmachine extension show \
  --machine-name <machine> \
  --resource-group <rg> \
  --name AzureMonitorWindowsAgent
```

---

## 🔐 Security Notes

### Configuration File Security

⚠️ **IMPORTANT**: The `config.json` file is excluded from Git (via `.gitignore`).

**Never commit:**
- Subscription IDs (if they're sensitive)
- Customer-specific information
- Access credentials

**Safe to commit:**
- `config.template.json` (template with placeholders)
- Deployment scripts

### RBAC Permissions

The deployment scripts require:

**Inventory Dashboard:**
- `Reader` on subscriptions (to query Resource Graph)
- `Contributor` on target resource group

**Full Dashboard:**
- All Inventory permissions PLUS:
- `Log Analytics Contributor` (to create workspace)
- `Monitoring Contributor` (to create DCRs)

---

## 💰 Cost Management

### Inventory Dashboard

**Cost: $0/month** ✅
- Uses Azure Resource Graph (free)
- No data ingestion costs
- No storage costs

### Full Dashboard

**Costs apply** based on:

1. **Log Analytics Ingestion** (~$2.30/GB)
   - Arc server: ~10-50 MB/day per machine
   - Azure Local cluster: ~100-500 MB/day per cluster
   - AKS Arc cluster: ~50-200 MB/day per cluster

2. **Data Retention** ($0.10/GB after 31 days)
   - First 31 days included
   - Additional days: $0.10/GB/month

3. **Example Monthly Costs:**
   - 10 Arc servers: $70-80/month
   - 50 Arc servers: $350-400/month
   - 200 Arc servers: $1,400-1,600/month

**Cost optimization tips:**
- Start with 30-day retention (free)
- Use workspace commitment tiers for >100GB/day
- Monitor ingestion in Cost Management
- Archive old data to Azure Storage ($0.01/GB)

---

## 📖 Additional Resources

- [Quick Start Guide](../../QUICKSTART.md)
- [Main README](../../README.md)
- [Azure Monitor Pricing](https://azure.microsoft.com/pricing/details/monitor/)
- [Azure Resource Graph](https://docs.microsoft.com/azure/governance/resource-graph/)
- [Data Collection Rules](https://docs.microsoft.com/azure/azure-monitor/agents/data-collection-rule-overview)

---

## 💬 Support

For issues or questions:
- 🐛 Report issues: [GitHub Issues](https://github.com/smitzlroy/adaptive-cloud-health-dashboard/issues)
- 📖 Documentation: [Microsoft Learn](https://learn.microsoft.com/azure/azure-monitor/)
- 💡 Ideas: Create a pull request

---

**Happy Deploying! 🚀**
