# Customization Guide

This guide explains how to customize the Adaptive Cloud Health Dashboard to meet your specific requirements.

## Overview

All dashboard components are designed to be fully customizable without requiring code changes. Customization is achieved through:

- **Parameters**: JSON-based parameter files
- **Query Variables**: Kusto query parameters
- **Workbook Parameters**: Azure Workbook parameter controls
- **Configuration Files**: JSON configuration for scripts and automation

## Customizing Workbooks

### 1. Modifying Parameters

Workbooks use parameters to filter and customize data. Edit parameters directly in the Azure Portal or modify the JSON template.

#### Common Parameters

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| `Subscriptions` | Target subscriptions | `["sub-id-1", "sub-id-2"]` |
| `ResourceGroups` | Filter by resource groups | `["rg-prod-*"]` |
| `TimeRange` | Data time range | `Last 24 hours`, `Last 7 days` |
| `ClusterType` | Type of clusters | `Azure Local`, `AKS Arc`, `All` |
| `HealthThreshold` | Health score threshold | `70` (0-100) |

#### Editing Parameters in Portal

1. Open workbook in Azure Portal
2. Click **Edit** button
3. Select parameter control to modify
4. Click **Advanced Editor** for JSON editing
5. Save changes

#### Editing Parameter JSON

```json
{
  "type": "parameter",
  "name": "Subscriptions",
  "label": "Subscriptions",
  "description": "Select subscriptions to monitor",
  "typeSettings": {
    "additionalResourceOptions": [],
    "includeAll": true
  }
}
```

### 2. Customizing Queries

All queries are parameterized and can be customized.

#### Example: Modify Health Score Calculation

Edit the query in `src/queries/health/cluster-health-score.kql`:

```kusto
// Original: Simple average
let healthScore = (cpuHealth + memoryHealth + storageHealth) / 3;

// Custom: Weighted average
let healthScore = (cpuHealth * 0.4) + (memoryHealth * 0.3) + (storageHealth * 0.3);
```

#### Adding Custom Metrics

Create new query file in `src/queries/custom/`:

```kusto
// custom-metric.kql
let subscription = dynamic({Subscriptions});
let timeRange = {TimeRange};

InsightsMetrics
| where TimeGenerated > ago(timeRange)
| where _SubscriptionId in (subscription)
| where Namespace == "CustomNamespace"
| where Name == "CustomMetric"
| summarize AvgValue = avg(Val) by bin(TimeGenerated, 5m), Computer
| render timechart
```

### 3. Adding New Visualizations

#### Add a New Chart to Existing Workbook

1. Open workbook in edit mode
2. Click **Add** > **Add query**
3. Enter your KQL query
4. Select visualization type (line chart, bar chart, grid, etc.)
5. Configure visualization settings
6. Save workbook

#### Create New Workbook Section

```json
{
  "type": "group",
  "name": "customSection",
  "title": "Custom Metrics",
  "items": [
    {
      "type": "query",
      "query": "// Your KQL query here",
      "size": "large",
      "visualization": "chart"
    }
  ]
}
```

## Customizing Thresholds and Alerts

### Health Score Thresholds

Edit `src/queries/health/thresholds.json`:

```json
{
  "health": {
    "critical": 40,
    "warning": 70,
    "healthy": 90
  },
  "compliance": {
    "critical": 60,
    "warning": 80,
    "compliant": 95
  },
  "performance": {
    "cpu": {
      "warning": 70,
      "critical": 90
    },
    "memory": {
      "warning": 80,
      "critical": 95
    },
    "storage": {
      "warning": 75,
      "critical": 90
    }
  }
}
```

### Custom KPI Calculations

Modify `src/queries/kpis/custom-kpis.kql`:

```kusto
// Example: Custom Capacity Risk Index
let capacityRisk = 
  case(
    storageUsedPercent > 90, 100,  // Critical risk
    storageUsedPercent > 75, 75,   // High risk
    storageUsedPercent > 60, 50,   // Medium risk
    storageUsedPercent > 40, 25,   // Low risk
    10                              // Minimal risk
  );
```

## Branding and Appearance

### Workbook Styling

Modify workbook JSON to customize colors, fonts, and layout:

```json
{
  "styleSettings": {
    "palette": "custom",
    "colors": {
      "healthy": "#00ff00",
      "warning": "#ffaa00",
      "critical": "#ff0000"
    }
  }
}
```

### Logo and Title

Edit workbook header section:

```json
{
  "type": "text",
  "content": {
    "version": "MarkdownV2",
    "markdown": "# ![Your Logo](logo-url) Your Organization - Adaptive Cloud Dashboard"
  }
}
```

## Multi-Subscription Configuration

### Configure Subscription List

Edit `scripts/deployment/config.json`:

```json
{
  "subscriptions": [
    {
      "id": "sub-id-1",
      "name": "Production",
      "environment": "prod"
    },
    {
      "id": "sub-id-2",
      "name": "Development",
      "environment": "dev"
    }
  ],
  "defaultSubscription": "sub-id-1"
}
```

### Cross-Subscription Queries

Queries automatically handle multiple subscriptions using Resource Graph:

```kusto
arg("").Resources
| where subscriptionId in ({Subscriptions})
| where type =~ 'microsoft.azurestackhci/clusters'
| summarize ClusterCount = count() by subscriptionId
```

## Custom Resource Filters

### Filter by Tags

Add tag-based filtering to queries:

```kusto
Resources
| where subscriptionId in ({Subscriptions})
| where tags["environment"] == "{Environment}"
| where tags["criticality"] in ({CriticalityLevels})
```

### Filter by Naming Convention

```kusto
Resources
| where subscriptionId in ({Subscriptions})
| where name matches regex "{NamingPattern}"
| where resourceGroup startswith "{ResourceGroupPrefix}"
```

## Advanced Customization

### Custom Data Sources

#### Add Application Insights Data

```kusto
union
  (InsightsMetrics | where _ResourceId contains "azurestackhci"),
  (app("your-app-insights").customMetrics | where name == "CustomMetric")
| summarize Value = avg(value) by bin(TimeGenerated, 5m)
```

#### Integrate External Data

Use Azure Functions to inject external data into Log Analytics.

### Custom Predictive Models

See [Power BI Setup Guide](POWERBI_SETUP.md) for implementing custom ML models.

## Testing Customizations

### Validate Queries

```powershell
# Test query locally
.\scripts\deployment\Test-Query.ps1 -QueryFile "src/queries/custom/my-query.kql"
```

### Preview Workbook Changes

1. Edit workbook in Azure Portal
2. Use preview mode before saving
3. Test with different parameter combinations
4. Verify across different subscriptions

## Version Control for Customizations

### Save Customizations

```powershell
# Export customized workbook
.\scripts\git\Export-Workbook.ps1 -WorkbookName "health-overview" -OutputPath "src/workbooks/health-overview.custom.json"

# Commit changes
.\scripts\git\Save-Changes.ps1 -Message "Customize health thresholds" -Type "feat"
```

### Maintain Custom Branch

```powershell
# Create custom branch for your organization
.\scripts\git\New-FeatureBranch.ps1 -BranchName "custom/org-name"

# Keep base updates while preserving customizations
git merge main --strategy-option theirs
```

## Examples

See the `/examples` directory for:
- Custom query examples
- Modified workbook templates
- Specialized dashboard configurations
- Industry-specific customizations

## Best Practices

1. **Test in Non-Production First**: Always test customizations in dev/test environments
2. **Document Changes**: Keep notes on customizations for future reference
3. **Use Parameters**: Avoid hardcoding values; use parameters instead
4. **Version Control**: Commit customizations to version control
5. **Backup Original**: Keep copy of original templates before customizing
6. **Performance Testing**: Test query performance with production-scale data

## Getting Help

- Review [Query Reference](../QUERY_REFERENCE.md)
- Check [examples](../../examples/) directory
- Open an issue on GitHub

---

Next: [Power BI Setup](POWERBI_SETUP.md) | [Query Reference](../QUERY_REFERENCE.md)
