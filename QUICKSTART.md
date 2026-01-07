# ⚡ Quick Start Guide

Deploy your Adaptive Cloud Dashboard with **ONE command** - choose the option that fits your needs.

---

## 🎯 Which Dashboard Should You Deploy?

### Option 1: Inventory Dashboard (FREE) ⭐ Recommended to Start

**Best for**: Quick inventory view, compliance tracking, zero cost evaluation

✅ **Advantages:**
- Completely FREE (uses Azure Resource Graph)
- No agents required
- 5-minute deployment
- Real-time data
- Perfect for evaluating the solution

❌ **Limitations:**
- No performance metrics (CPU, Memory, Disk)
- No health monitoring or heartbeat data
- No custom application metrics

[👉 Jump to Inventory Dashboard Deployment](#inventory-dashboard-deployment)

---

### Option 2: Full Dashboard (PAID) 💰

**Best for**: Production monitoring with performance metrics and alerting

✅ **Advantages:**
- Complete performance metrics (CPU, Memory, Disk, Network)
- Health monitoring with heartbeat tracking
- Custom application metrics support
- Detailed logging and diagnostics

❌ **Costs & Requirements:**
- Log Analytics workspace: ~$2.30/GB ingestion + $0.10/GB retention
- Azure Monitor Agent required on ALL monitored VMs
- Estimated monthly cost:
  - Small (10 servers): $70-80/month
  - Medium (50 servers): $350-400/month
  - Large (200 servers): $1,400-1,600/month
- 20+ minute deployment + agent installation time

[👉 Jump to Full Dashboard Deployment](#full-dashboard-deployment)

---

## Prerequisites (Both Options)

- **Azure CLI** - [Install](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **PowerShell 7+** - [Install](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- **Azure Subscription** with permissions to create resources

---

## Inventory Dashboard Deployment

### 1️⃣ Login to Azure

```powershell
az login
```

### 2️⃣ Create Your Configuration

Copy the template and edit with your subscription ID:

```powershell
# Copy template
Copy-Item .\scripts\deployment\config.template.json .\scripts\deployment\config.json

# Edit config.json and replace YOUR-SUBSCRIPTION-ID-HERE
code .\scripts\deployment\config.json
```

**Example config.json:**
```json
{
  "subscriptions": [
    "12345678-1234-1234-1234-123456789abc"
  ],
  "resourceGroup": "rg-adaptive-cloud-dashboard",
  "location": "eastus"
}
```

💡 **Tip**: Get your subscription ID with:
```powershell
az account list --output table
```

### 3️⃣ Deploy Inventory Dashboard

```powershell
.\scripts\deployment\Deploy-Inventory-Dashboard.ps1
```

That's it! ✨ **Zero cost, zero agents, instant value.**

### 📊 What Gets Deployed?

- ✅ **Azure Workbook** with inventory queries
- ✅ **Resource Group** (if doesn't exist)

### 🎯 Access Your Dashboard

1. Open the [Azure Portal](https://portal.azure.com)
2. Navigate to **Monitor** → **Workbooks**
3. Find **"Adaptive Cloud - Inventory Dashboard"**

### 📈 What You'll See

- Resource counts by type (Azure Local, AKS Arc, Arc Servers, etc.)
- Complete resource inventory with names, locations, SKUs
- Policy compliance status by resource
- Tag analysis and coverage
- Multi-subscription aggregation

---

## Full Dashboard Deployment

⚠️ **WARNING**: This option creates billable Azure resources and requires agent installation.

### 1️⃣ Login to Azure

```powershell
az login
```

### 2️⃣ Create Your Configuration

```powershell
# Copy template
Copy-Item .\scripts\deployment\config.template.json .\scripts\deployment\config.json

# Edit with your settings
code .\scripts\deployment\config.json
```

### 3️⃣ Deploy Full Dashboard

```powershell
.\scripts\deployment\Deploy-Full-Dashboard.ps1
```

**You will see a cost warning** - type `yes` to confirm and continue.

### 📊 What Gets Deployed?

- ✅ **Resource Group** with proper tags
- ✅ **Log Analytics Workspace** (pay-per-GB ingestion)
- ✅ **Data Collection Rules** for performance metrics
- ✅ **Azure Workbook** with performance queries

### ⚠️ Required Post-Deployment Steps

**IMPORTANT**: The dashboard won't show data until you install agents on your VMs.

#### Install Azure Monitor Agent on Azure Local/Arc Servers

```powershell
# For Windows machines
az connectedmachine extension create \
  --machine-name <machine-name> \
  --resource-group <resource-group> \
  --name AzureMonitorWindowsAgent \
  --publisher Microsoft.Azure.Monitor \
  --type AzureMonitorWindowsAgent \
  --location <location>

# For Linux machines
az connectedmachine extension create \
  --machine-name <machine-name> \
  --resource-group <resource-group> \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --type AzureMonitorLinuxAgent \
  --location <location>
```

#### Associate Data Collection Rule

```powershell
# Get your DCR ID (from deployment output or portal)
$dcrId = "<your-dcr-resource-id>"

# Associate with Arc machine
az monitor data-collection rule association create \
  --name "configurationAccessEndpoint" \
  --rule-id $dcrId \
  --resource "<machine-resource-id>"
```

### 🎯 Access Your Dashboard

1. Open the [Azure Portal](https://portal.azure.com)
2. Navigate to **Monitor** → **Workbooks**
3. Find **"Adaptive Cloud - Full Dashboard"**

### 📈 What You'll See

- Everything from Inventory Dashboard PLUS:
- CPU, Memory, Disk utilization trends
- VM heartbeat and availability
- Performance anomaly detection
- Health scoring and KPIs
- Custom metrics from applications

---

## 🔄 Upgrade from Inventory to Full

Already deployed the Inventory Dashboard? Upgrade anytime:

1. Run the Full Dashboard deployment script
2. Install agents on your VMs
3. Both dashboards coexist - use the one you need

---

## ❓ Troubleshooting

### "Not logged in to Azure"
```powershell
az login
az account set --subscription <your-subscription-id>
```

### "Azure CLI is not installed"
Install from: https://docs.microsoft.com/cli/azure/install-azure-cli

### "Configuration file not found"
```powershell
# Ensure you're in the project root directory
cd c:\AI\adaptive-cloud-health-dashboard

# Create config from template
Copy-Item .\scripts\deployment\config.template.json .\scripts\deployment\config.json
```

### "Permission denied"
Ensure your account has these roles:
- **Contributor** or **Owner** on the target subscription
- **Log Analytics Contributor** role (Full Dashboard only)

### "Workbook deployment failed"
Check Azure CLI application-insights extension is installed:
```powershell
az extension add --name application-insights
```

---

## 💬 Need Help?

- 📚 Check deployment [README](scripts/deployment/README.md)
- 🐛 Report issues on [GitHub](https://github.com/smitzlroy/adaptive-cloud-health-dashboard/issues)
- 📖 Review [Microsoft Docs](https://docs.microsoft.com/azure/azure-monitor/)

---

**Happy Monitoring! 📈**
