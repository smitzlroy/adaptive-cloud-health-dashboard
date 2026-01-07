# Deployment Scripts

This directory contains PowerShell scripts for deploying the Adaptive Cloud Health Dashboard to Azure.

## Scripts Overview

### Deploy-Resources.ps1
Deploys all required Azure resources including:
- Resource Group
- Log Analytics Workspace
- Data Collection Rules
- Monitoring Solutions
- RBAC permissions

### Import-Workbooks.ps1
Imports Azure Workbook templates to your subscription.

### Configure-Environment.ps1
*(Placeholder for future implementation)*

Configures Azure Local and AKS Arc clusters for data collection.

## Prerequisites

Before running deployment scripts:

1. **Install Azure CLI**:
   ```powershell
   winget install Microsoft.AzureCLI
   ```

2. **Install PowerShell Modules**:
   ```powershell
   Install-Module -Name Az -Scope CurrentUser -Force
   ```

3. **Login to Azure**:
   ```powershell
   az login
   Connect-AzAccount
   ```

4. **Set Subscription**:
   ```powershell
   az account set --subscription "your-subscription-id"
   ```

## Quick Start

### 1. Configure Settings

Copy and edit the configuration template:
```powershell
Copy-Item config.template.json config.json
# Edit config.json with your details
```

### 2. Deploy Resources

```powershell
.\Deploy-Resources.ps1 -ConfigFile .\config.json
```

Or specify parameters directly:
```powershell
.\Deploy-Resources.ps1 `
  -SubscriptionId "xxx-xxx-xxx" `
  -ResourceGroup "rg-dashboard" `
  -Location "eastus" `
  -WorkspaceName "law-dashboard"
```

### 3. Import Workbooks

```powershell
.\Import-Workbooks.ps1 `
  -SubscriptionId "xxx-xxx-xxx" `
  -ResourceGroup "rg-dashboard"
```

## Configuration File

The `config.json` file contains all deployment settings:

```json
{
  "subscriptions": ["sub-id-1", "sub-id-2"],
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

## Deployment Outputs

After successful deployment:

```
========================================
Deployment completed successfully!
========================================

Resources created:
  Resource Group: rg-adaptive-cloud-dashboard
  Log Analytics Workspace: law-adaptive-cloud
  Workspace ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Location: eastus

Next steps:
  1. Import workbooks: .\Import-Workbooks.ps1
  2. Configure data collection on your clusters
  3. Access dashboards in Azure Portal
```

## Post-Deployment Configuration

### Enable Monitoring on Azure Local

```powershell
az stack-hci arc-setting update `
  --resource-group "your-rg" `
  --cluster-name "cluster-name" `
  --name "default" `
  --monitoring-enabled true `
  --log-analytics-workspace-id "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/law-name"
```

### Enable Monitoring on AKS Arc

```powershell
az k8s-extension create `
  --name azuremonitor-containers `
  --cluster-name "cluster-name" `
  --resource-group "your-rg" `
  --cluster-type connectedClusters `
  --extension-type Microsoft.AzureMonitor.Containers `
  --configuration-settings logAnalyticsWorkspaceResourceID="/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/law-name"
```

### Enable Monitoring on Arc-Enabled Servers

```powershell
# Using Azure Portal
1. Navigate to Arc-enabled server
2. Select Extensions
3. Add "Azure Monitor Agent"
4. Configure with Log Analytics workspace

# Or using CLI
az connectedmachine extension create `
  --name AzureMonitorWindowsAgent `
  --machine-name "server-name" `
  --resource-group "your-rg" `
  --type AzureMonitorWindowsAgent `
  --publisher Microsoft.Azure.Monitor `
  --settings '{"workspaceId":"workspace-guid"}' `
  --protected-settings '{"workspaceKey":"workspace-key"}'
```

## Troubleshooting

### Permission Errors

**Issue**: Insufficient permissions to create resources

**Solution**: Ensure you have `Contributor` role on the subscription:
```powershell
az role assignment create `
  --role "Contributor" `
  --assignee "your-upn@domain.com" `
  --scope "/subscriptions/your-subscription-id"
```

### Workspace Creation Fails

**Issue**: Workspace name already exists

**Solution**: Use a different name or delete existing workspace:
```powershell
az monitor log-analytics workspace delete `
  --resource-group "rg-name" `
  --workspace-name "workspace-name"
```

### Data Not Appearing

**Issue**: Dashboards show no data after deployment

**Solution**:
1. Verify data collection is enabled on resources
2. Check agents are running:
   ```powershell
   Heartbeat | take 10
   ```
3. Wait 5-10 minutes for initial data ingestion

### Query Timeouts

**Issue**: Queries timeout in workbooks

**Solution**:
- Reduce time range
- Limit subscriptions in filter
- Optimize queries (add filters earlier)

## Manual Steps

Some configurations require manual steps in Azure Portal:

### Configure Alerts

1. Navigate to Monitor > Alerts
2. Create alert rule
3. Select Log Analytics workspace
4. Define condition (KQL query)
5. Configure action group (email, webhook)

### Set Up Dashboards

1. Navigate to Dashboard hub
2. Create new dashboard
3. Pin workbook charts
4. Arrange layout
5. Share with team

### Configure Workbook Permissions

1. Navigate to workbook
2. Click Access control (IAM)
3. Add role assignment
4. Select user/group and role
5. Save

## Best Practices

1. **Use Separate Resource Groups**: Create dedicated RG for dashboard resources
2. **Tag Resources**: Apply consistent tags for cost tracking
3. **Set Retention**: Configure appropriate data retention (30-365 days)
4. **Monitor Costs**: Set up cost alerts for Log Analytics ingestion
5. **Backup Workbooks**: Export workbooks to Git regularly
6. **Test in Dev**: Test changes in non-production first

## Cost Estimation

Typical monthly costs:

| Component | Volume | Cost (USD) |
|-----------|--------|------------|
| Log Analytics Ingestion | 500 GB | $100-150 |
| Log Analytics Retention | 90 days | $50-75 |
| Resource Graph Queries | Free | $0 |
| Workbooks | Free | $0 |
| **Total** | | **$150-225** |

*Costs vary by region and actual data volume*

## Cleanup

To remove all deployed resources:

```powershell
# Delete resource group (removes all resources)
az group delete --name "rg-adaptive-cloud-dashboard" --yes

# Or use planned cleanup script
.\Uninstall-Dashboard.ps1 -ResourceGroup "rg-adaptive-cloud-dashboard" -Confirm
```

## Advanced Deployment Options

### Multi-Region Deployment

Deploy to multiple regions for global coverage:

```powershell
$regions = @("eastus", "westeurope", "southeastasia")

foreach ($region in $regions) {
  .\Deploy-Resources.ps1 `
    -SubscriptionId "xxx" `
    -ResourceGroup "rg-dashboard-$region" `
    -Location $region
}
```

### Infrastructure as Code

Use Bicep/ARM templates for repeatable deployments:

```powershell
# Deploy using ARM template (future enhancement)
az deployment group create `
  --resource-group "rg-dashboard" `
  --template-file "./templates/arm/main.bicep" `
  --parameters @config.parameters.json
```

## Support

For deployment issues:
- Review [Setup Guide](../../docs/setup/SETUP.md)
- Check [Troubleshooting](../../docs/setup/SETUP.md#troubleshooting)
- Open issue on GitHub

---

For complete documentation, see [docs/setup/SETUP.md](../../docs/setup/SETUP.md).
