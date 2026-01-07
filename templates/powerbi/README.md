# Power BI Template Placeholder

This directory will contain the Power BI Desktop template (.pbix file) for advanced analytics and predictive insights.

## Template Features (To Be Developed)

The Power BI template will include:

### Dashboard Pages
1. **Executive Overview** - High-level KPIs and summary metrics
2. **Health Analysis** - Detailed health monitoring with drill-through
3. **Compliance Dashboard** - Policy compliance tracking
4. **Performance Analytics** - Resource utilization trends
5. **Predictive Insights** - Capacity forecasting and predictions
6. **Inventory Management** - Complete resource catalog

### Data Connections
- Azure Log Analytics workspace
- Azure Resource Graph
- Optional: Custom data sources

### Advanced Features
- Predictive analytics using linear regression
- Anomaly detection for performance metrics
- Capacity forecasting (30, 60, 90-day projections)
- Custom KPIs and calculated measures
- Row-level security for multi-tenant scenarios
- Scheduled refresh configuration

### Custom Measures (DAX)
- Health Score Calculation
- Compliance Index
- Capacity Risk Score
- Growth Rate Analysis
- Trend Indicators
- Cost Projections

## Creating the Template

To create the Power BI template:

1. **Install Power BI Desktop**
   - Download from https://powerbi.microsoft.com/desktop/

2. **Connect to Data Sources**
   - Configure Log Analytics connection
   - Set up Azure Resource Graph queries
   - Import custom queries from `/src/queries`

3. **Build Data Model**
   - Create relationships between tables
   - Define hierarchies (Subscription > Resource Group > Resource)
   - Create date table for time intelligence

4. **Create Measures**
   - Import DAX measures for health, compliance, performance
   - Configure parameters for thresholds
   - Add predictive measures

5. **Design Dashboards**
   - Create visuals for each page
   - Configure interactivity and drill-through
   - Apply formatting and theme

6. **Save as Template**
   - File > Save As > Template (.pbit)
   - Include parameter prompts
   - Add template description

## Quick Start (Manual Setup)

If you want to create the Power BI dashboard manually:

### Step 1: Connect to Log Analytics

```powerquery
let
    Source = AzureLogAnalytics.Workspaces(),
    #"Your Workspace" = Source{[WorkspaceId="your-workspace-id"]}[Data],
    #"Your Table" = #"Your Workspace"{[Name="InsightsMetrics"]}[Data]
in
    #"Your Table"
```

### Step 2: Load KQL Queries

Create custom queries for each table:
- Health Metrics
- Performance Data
- Compliance Status
- Inventory Data

### Step 3: Create Relationships

- Link tables using ResourceId
- Create date relationships for time-based analysis

### Step 4: Build Visualizations

Refer to the [Power BI Setup Guide](../../docs/customization/POWERBI_SETUP.md) for detailed instructions.

## Sample DAX Measures

```dax
// Overall Health Score
Health Score = 
VAR CPUHealth = AVERAGE(Metrics[CPUUtilization])
VAR MemoryHealth = AVERAGE(Metrics[MemoryUtilization])
VAR DiskHealth = AVERAGE(Metrics[DiskUtilization])
RETURN
    (
        (100 - CPUHealth) * 0.4 +
        (100 - MemoryHealth) * 0.35 +
        (100 - DiskHealth) * 0.25
    )

// Compliance Percentage
Compliance % = 
DIVIDE(
    COUNTROWS(FILTER(Compliance, Compliance[Status] = "Compliant")),
    COUNTROWS(Compliance),
    0
) * 100

// Capacity Forecast
Forecasted Capacity = 
VAR CurrentCapacity = [Current Disk Usage %]
VAR DailyGrowth = [Daily Growth Rate]
VAR DaysAhead = [Forecast Days Parameter]
RETURN
    CurrentCapacity + (DailyGrowth * DaysAhead)
```

## Resources

- [Power BI Template Documentation](../../docs/customization/POWERBI_SETUP.md)
- [Sample Queries](../../examples/queries/)
- [DAX Formula Reference](https://docs.microsoft.com/dax/)

## Contributing

If you create a Power BI template for this solution:
1. Save as `.pbix` file in this directory
2. Include `.pbit` template version
3. Document data source requirements
4. Update this README with instructions
5. Submit a pull request

---

**Note**: The Power BI template is an optional advanced feature. The core dashboard functionality is provided through Azure Workbooks, which require no additional licensing.
