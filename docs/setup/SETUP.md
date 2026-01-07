# Setup Guide

This guide will walk you through deploying the Adaptive Cloud Health Dashboard to your Azure environment.

## Prerequisites

### Required
- Azure subscription(s) with appropriate permissions (Contributor or higher)
- Azure CLI version 2.50.0 or higher
- PowerShell 7.0 or higher
- Azure Local (formerly Azure Stack HCI) and/or AKS Arc clusters deployed
- Log Analytics workspace (or ability to create one)

### Optional
- Power BI Desktop (for advanced analytics features)
- Visual Studio Code (for customization)
- Git (for version control)

## Installation Steps

### 1. Prepare Your Environment

#### Install Azure CLI
```powershell
# Windows (using winget)
winget install Microsoft.AzureCLI

# Verify installation
az --version
```

#### Install Required PowerShell Modules
```powershell
# Install Azure PowerShell modules
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# Install Arc-specific modules
Install-Module -Name Az.ConnectedMachine -Scope CurrentUser -Force
Install-Module -Name Az.Kubernetes -Scope CurrentUser -Force
```

#### Login to Azure
```powershell
# Login to Azure
Connect-AzAccount

# Set default subscription (if you have multiple)
Set-AzContext -SubscriptionId "<your-subscription-id>"
```

### 2. Configure Environment

#### Edit Configuration File
```powershell
# Navigate to scripts directory
cd scripts/deployment

# Copy template configuration
Copy-Item config.template.json config.json

# Edit config.json with your details:
# - Subscription IDs
# - Resource Group names
# - Log Analytics workspace details
# - Regions
```

Example `config.json`:
```json
{
  "subscriptions": [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ],
  "resourceGroup": "rg-adaptive-cloud-dashboard",
  "location": "eastus",
  "logAnalytics": {
    "name": "law-adaptive-cloud",
    "sku": "PerGB2018",
    "retentionDays": 90
  },
  "tags": {
    "environment": "production",
    "solution": "adaptive-cloud-dashboard"
  }
}
```

### 3. Deploy Azure Resources

#### Run Deployment Script
```powershell
# Execute deployment script
.\Deploy-Resources.ps1 -ConfigFile .\config.json

# This script will:
# - Create resource group
# - Deploy Log Analytics workspace
# - Configure data collection rules
# - Set up required permissions
```

### 4. Import Dashboard Workbooks

```powershell
# Import all workbook templates
.\Import-Workbooks.ps1 -SubscriptionId "<your-subscription-id>" -ResourceGroup "rg-adaptive-cloud-dashboard"

# Or import specific workbooks
.\Import-Workbooks.ps1 -SubscriptionId "<your-subscription-id>" -ResourceGroup "rg-adaptive-cloud-dashboard" -WorkbookName "health-overview"
```

### 5. Configure Data Collection

#### For Azure Local Clusters
```powershell
# Enable monitoring extension on Azure Local clusters
az stack-hci arc-setting update `
  --resource-group "<your-rg>" `
  --cluster-name "<cluster-name>" `
  --name "default" `
  --monitoring-enabled true `
  --log-analytics-workspace-id "<workspace-id>"
```

#### For AKS Arc Clusters
```powershell
# Enable monitoring for AKS Arc clusters
az k8s-extension create `
  --name azuremonitor-containers `
  --cluster-name "<cluster-name>" `
  --resource-group "<your-rg>" `
  --cluster-type connectedClusters `
  --extension-type Microsoft.AzureMonitor.Containers `
  --configuration-settings logAnalyticsWorkspaceResourceID="<workspace-resource-id>"
```

### 6. Verify Installation

```powershell
# Run verification script
.\Verify-Installation.ps1

# This will check:
# - Resource deployment status
# - Data collection status
# - Workbook availability
# - Query execution
```

### 7. Access Dashboards

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Go to **Monitor** > **Workbooks**
3. Select **Adaptive Cloud Health Dashboard** workbooks

## Post-Installation Configuration

### Configure Alerts (Optional)
```powershell
# Deploy alert rules
.\Deploy-Alerts.ps1 -ConfigFile .\alerts.config.json
```

### Set Up Power BI Integration (Optional)
See [Power BI Setup Guide](../customization/POWERBI_SETUP.md)

## Troubleshooting

### Common Issues

#### Issue: Workbooks show no data
- **Solution**: Verify data collection is enabled and agents are reporting
- Check Log Analytics workspace for data: `Heartbeat | take 10`

#### Issue: Permission errors during deployment
- **Solution**: Ensure you have Contributor role on the subscription
- Verify RBAC assignments: `az role assignment list --assignee <your-upn>`

#### Issue: Queries timeout
- **Solution**: Reduce time range or optimize queries
- Check workspace capacity and scaling

### Getting Help

- Review [Troubleshooting Guide](TROUBLESHOOTING.md)
- Check [FAQ](FAQ.md)
- Open an issue on GitHub

## Next Steps

- [Customize Dashboards](../customization/CUSTOMIZATION.md)
- [Add Custom Queries](../customization/CUSTOM_QUERIES.md)
- [Configure Alerts](../customization/ALERTS.md)
- [Set Up Power BI](../customization/POWERBI_SETUP.md)

## Uninstallation

To remove the solution:
```powershell
.\Uninstall-Dashboard.ps1 -ResourceGroup "rg-adaptive-cloud-dashboard" -Confirm
```

---

For more information, see the [main README](../../README.md).
