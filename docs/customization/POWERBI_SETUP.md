# Power BI Setup Guide

This guide explains how to set up and use the Power BI template for advanced analytics and predictive insights.

## Prerequisites

- Power BI Desktop (latest version)
- Power BI Pro or Premium license (for sharing reports)
- Access to Azure Log Analytics workspace
- Azure Resource Graph access

## Setup Steps

### 1. Install Power BI Desktop

Download and install from: https://powerbi.microsoft.com/desktop/

### 2. Open the Power BI Template

1. Open Power BI Desktop
2. File > Open > Browse for file
3. Navigate to `templates/powerbi/adaptive-cloud-dashboard.pbix`
4. The template will open with parameter prompts

### 3. Configure Data Sources

#### Connect to Log Analytics

1. Click **Transform data** > **Data source settings**
2. Select **Azure Log Analytics** connection
3. Click **Edit**
4. Enter your workspace details:
   - **Workspace ID**: Your Log Analytics workspace ID
   - **Subscription ID**: Your Azure subscription ID
5. Click **OK** and authenticate with Azure AD

#### Connect to Azure Resource Graph

1. In Power Query Editor, select **Azure Resource Graph** query
2. Update the subscription IDs in the query
3. Click **Close & Apply**

### 4. Configure Parameters

The template uses parameters for flexibility:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `SubscriptionIds` | Comma-separated subscription IDs | `sub1,sub2,sub3` |
| `TimeRangeDays` | Number of days of historical data | `30` |
| `HealthThreshold` | Threshold for health alerts | `70` |
| `ComplianceThreshold` | Minimum compliance percentage | `90` |

To edit parameters:
1. Home > Transform data > Edit Parameters
2. Update values
3. Click OK

### 5. Refresh Data

1. Home > Refresh
2. Wait for data to load (may take several minutes for large datasets)
3. Review any refresh errors in the Messages pane

## Dashboard Pages

### Overview
- Executive summary with key metrics
- Resource count by type and location
- Overall health score and compliance percentage
- Trend indicators

### Health Analysis
- Detailed health metrics per resource
- Time-series health score trends
- Alert distribution and prioritization
- Capacity utilization gauges

### Compliance Dashboard
- Policy compliance status
- Non-compliant resources by policy
- Compliance trends over time
- Remediation recommendations

### Performance Analytics
- CPU, memory, and disk utilization
- Performance trends and patterns
- Peak usage identification
- Anomaly detection

### Predictive Insights
- Capacity forecasting (30, 60, 90 days)
- Growth trend analysis
- Resource exhaustion predictions
- Cost projection based on growth

### Inventory
- Complete resource inventory
- Filtering by subscription, location, type
- Tag-based organization
- Export capabilities

## Custom Visualizations

### Health Score Gauge
Shows overall health score (0-100) with color-coded indicators:
- **Green** (90-100): Healthy
- **Yellow** (70-89): Warning
- **Red** (<70): Critical

### Capacity Forecast Chart
Line chart with:
- Historical usage (solid line)
- Predicted usage (dashed line)
- Capacity threshold (red line)
- Confidence intervals (shaded area)

### Compliance Heatmap
Matrix showing compliance by:
- Policy definition (rows)
- Resource type (columns)
- Color intensity indicates compliance percentage

## Advanced Features

### Predictive Analytics

The template includes DAX measures for forecasting:

```dax
Predicted Capacity = 
VAR CurrentUsage = [Average Capacity Used]
VAR GrowthRate = [Daily Growth Rate]
VAR DaysAhead = [Forecast Days Parameter]
RETURN
    CurrentUsage + (GrowthRate * DaysAhead)
```

### Custom Alerts

Create alerts in Power BI Service:
1. Publish report to Power BI Service
2. Select a visual (e.g., health score gauge)
3. Click ellipsis (...) > Manage alerts
4. Configure threshold and notification

### Scheduled Refresh

Set up automatic data refresh:
1. Publish report to Power BI Service
2. Navigate to dataset settings
3. Configure refresh schedule:
   - Frequency: Daily recommended
   - Time: Off-peak hours
   - Credentials: Service principal or user account

## Customization

### Add Custom Metrics

1. Transform data > New Source
2. Create connection to your data source
3. Write KQL or SQL query
4. Create relationships in Model view
5. Add visuals to report

### Modify Thresholds

Edit DAX measures in Power BI Desktop:
1. Model view
2. Select measure (e.g., `Health Score`)
3. Modify formula in formula bar
4. Update threshold values

### Change Color Schemes

1. View > Themes
2. Select built-in theme or import custom
3. Or manually set colors per visual

## Performance Optimization

### Reduce Data Size

- **Filtering**: Apply filters to source queries
- **Aggregation**: Pre-aggregate data in Power Query
- **Incremental Refresh**: Configure for large datasets
- **Archive**: Remove old data beyond retention period

### Optimize Queries

- Use query folding where possible
- Minimize calculated columns (use measures instead)
- Remove unused columns
- Disable auto date/time

### Use Aggregations

For large datasets (>1M rows):
1. Create aggregation table
2. Configure in Model view
3. Power BI automatically uses aggregations

## Sharing and Collaboration

### Publish to Power BI Service

1. File > Publish > Publish to Power BI
2. Select workspace
3. Configure dataset settings
4. Share with users or create app

### Row-Level Security (RLS)

Restrict data access by user:
1. Modeling > Manage roles
2. Create role with filter (e.g., `[SubscriptionId] = USERPRINCIPALNAME()`)
3. Test in Power BI Desktop (View > View as)
4. Assign users to roles in Power BI Service

### Embed in Applications

Use Power BI Embedded:
- Get embed token via API
- Use Power BI JavaScript SDK
- Embed in web app or portal

## Troubleshooting

### Data Refresh Failures

**Issue**: Refresh fails with authentication error
- **Solution**: Update credentials in Power BI Service > Dataset settings

**Issue**: Query timeout
- **Solution**: Reduce time range or optimize query

### Performance Issues

**Issue**: Report loads slowly
- **Solution**: Reduce data volume, use aggregations, optimize DAX

**Issue**: Visuals don't respond
- **Solution**: Check for circular dependencies in relationships

### Missing Data

**Issue**: Some resources don't appear
- **Solution**: Verify data collection is enabled and agents are running

**Issue**: Metrics show zero
- **Solution**: Check Log Analytics query returns data, verify time range

## Best Practices

1. **Incremental Refresh**: For historical data >1 year
2. **Composite Models**: Mix imported and DirectQuery data
3. **Dataflows**: Share data prep across reports
4. **Version Control**: Export .pbix to Git regularly
5. **Documentation**: Add tooltips and info pages
6. **Testing**: Test with production-scale data

## Resources

- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [DAX Reference](https://docs.microsoft.com/dax/)
- [Power BI Community](https://community.powerbi.com/)

## Template File Structure

The Power BI template includes:
- **6 dashboard pages** (Overview, Health, Compliance, Performance, Predictive, Inventory)
- **20+ custom measures** for calculations
- **Data model** with relationships
- **Parameter configuration** for flexibility
- **Custom theme** aligned with Azure branding

---

For questions or issues, open an issue on GitHub or refer to the [main documentation](../../README.md).
