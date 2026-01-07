# Examples

This directory contains sample dashboards, queries, and configurations to help you get started and learn how to customize the Adaptive Cloud Health Dashboard.

## Directory Structure

```
examples/
├── queries/                    # Sample KQL queries
│   ├── custom-health-score.kql
│   └── multi-subscription-distribution.kql
└── workbooks/                  # Example workbook configurations (future)
```

## Available Examples

### 1. Custom Health Score Query

**File**: `queries/custom-health-score.kql`

**Purpose**: Demonstrates how to create a custom health score with weighted components and organization-specific thresholds.

**Features**:
- Custom CPU, Memory, and Disk thresholds
- Weighted health calculation (CPU: 40%, Memory: 35%, Disk: 25%)
- Custom health categories (Excellent, Good, Fair, Poor, Critical)
- Performance metric aggregation

**Use Cases**:
- Organizations with specific SLA requirements
- Different thresholds for production vs. development
- Custom health scoring methodologies

**How to Use**:
1. Copy query to Log Analytics
2. Modify thresholds for your environment
3. Adjust weights based on your priorities
4. Add to workbook as custom query

**Customization Points**:
```kusto
// Modify these values for your organization
let cpuCriticalThreshold = 95;
let cpuWarningThreshold = 80;
let memoryCriticalThreshold = 98;
let memoryWarningThreshold = 85;

// Adjust weights (must sum to 1.0)
CPUScore * 0.4 + MemoryScore * 0.35 + DiskScore * 0.25
```

### 2. Multi-Subscription Resource Distribution

**File**: `queries/multi-subscription-distribution.kql`

**Purpose**: Shows how to aggregate and visualize resource distribution across multiple subscriptions.

**Features**:
- Cross-subscription resource counting
- Resource group and location aggregation
- Subscription name resolution
- Resource type categorization

**Use Cases**:
- Multi-tenant environments
- Enterprise governance reporting
- Capacity planning across subscriptions
- Cost center allocation

**Visualizations**:
- Table: Detailed breakdown by subscription
- Bar chart: Resources per subscription
- Heatmap: Resources by type and subscription
- Treemap: Hierarchical view

**How to Use**:
1. Ensure you have access to multiple subscriptions
2. Run query in Resource Graph Explorer
3. Add to workbook for visual dashboard
4. Filter by specific subscriptions or resource types

## Query Categories

### Inventory Examples
Show different ways to query and organize resource inventory.

**Future Examples**:
- Tag-based resource grouping
- Custom resource properties
- Hierarchical inventory views
- Resource relationship mapping

### Health Monitoring Examples
Demonstrate various health calculation methods.

**Future Examples**:
- SLA-based health scoring
- Trend-based health indicators
- Anomaly detection in metrics
- Predictive health warnings

### Compliance Examples
Show different compliance tracking approaches.

**Future Examples**:
- Custom policy compliance
- Security baseline tracking
- Configuration drift detection
- Compliance trending and forecasting

### Performance Examples
Various performance analysis techniques.

**Future Examples**:
- Baseline performance comparison
- Performance regression detection
- Capacity utilization heatmaps
- Multi-dimensional performance analysis

## How to Use These Examples

### In Log Analytics

1. Open Azure Portal
2. Navigate to Log Analytics workspace
3. Click "Logs"
4. Copy query from example file
5. Replace parameters with actual values
6. Run and analyze results

### In Azure Workbooks

1. Edit workbook in Azure Portal
2. Add new query step
3. Paste example query
4. Configure parameters
5. Select visualization type
6. Save workbook

### In Power BI

1. Open Power BI Desktop
2. Get Data > Azure > Azure Log Analytics
3. Enter workspace details
4. Use Advanced Editor
5. Paste query (adjust syntax for M language)
6. Load and visualize

## Modifying Examples

### Change Time Range

```kusto
// Original
let timeRange = 7d;

// Modified for longer period
let timeRange = 30d;
```

### Add Filters

```kusto
// Add resource group filter
| where resourceGroup startswith "rg-prod-"

// Add location filter
| where location in ("eastus", "westus2")

// Add tag filter
| where tags["environment"] == "production"
```

### Customize Output

```kusto
// Add calculated columns
| extend DaysOld = datetime_diff('day', now(), createdTime)

// Custom formatting
| project 
    Name = name,
    Location = toupper(location),
    CreatedDate = format_datetime(createdTime, 'yyyy-MM-dd')
```

## Best Practices

### 1. Test Before Production
- Validate queries in Log Analytics first
- Test with production-scale data
- Check query performance (execution time)
- Verify results are accurate

### 2. Parameterize Everything
```kusto
// Good - Parameterized
let subscriptions = dynamic({Subscriptions});

// Bad - Hardcoded
let subscriptions = dynamic(["specific-sub-id"]);
```

### 3. Comment Your Code
```kusto
// Calculate weighted health score
// CPU: 40%, Memory: 35%, Disk: 25%
let healthScore = (cpuScore * 0.4) + (memoryScore * 0.35) + (diskScore * 0.25);
```

### 4. Handle Edge Cases
```kusto
// Handle null values
| extend SafeValue = coalesce(Value, 0)

// Handle division by zero
| extend Percentage = iff(Total > 0, (Count * 100.0) / Total, 0)
```

### 5. Optimize Performance
```kusto
// Good - Filter early
| where TimeGenerated > ago(7d)
| where _SubscriptionId in (subscriptions)
| summarize ... by ...

// Bad - Filter late
| summarize ... by ...
| where TimeGenerated > ago(7d)
```

## Contributing Examples

Have a useful query or dashboard configuration? Share it!

### Submission Guidelines

1. **Create Example File**
   - Use descriptive filename
   - Add comprehensive comments
   - Include example use cases

2. **Document the Example**
   - Purpose and use cases
   - How to customize
   - Expected output
   - Prerequisites

3. **Test Thoroughly**
   - Test with various parameters
   - Verify edge cases
   - Check performance

4. **Submit PR**
   - Use git scripts: `.\scripts\git\Save-Changes.ps1 -Message "Add example query" -Type "feat"`
   - Include documentation updates
   - Add screenshots if applicable

### Example Template

```kusto
// Example Name: [Descriptive Name]
// Purpose: [What this query does]
// Use Cases: [When to use this]
// Author: [Your name]
// Date: [Creation date]

// Parameters
let subscriptions = dynamic({Subscriptions});
let timeRange = {TimeRange:range};

// Main query logic
YourTable
| where TimeGenerated > ago(timeRange)
| where _SubscriptionId in (subscriptions)
// ... rest of query

// Expected Output:
// Column1: Description
// Column2: Description
```

## Resources

- [KQL Quick Reference](https://docs.microsoft.com/azure/data-explorer/kql-quick-reference)
- [Query Best Practices](https://docs.microsoft.com/azure/data-explorer/kusto/query/best-practices)
- [Azure Resource Graph Samples](https://docs.microsoft.com/azure/governance/resource-graph/samples/starter)
- [Workbook Visualizations](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-visualizations)

## Feedback

Found an issue with an example? Have suggestions for improvement?

- Open an issue on GitHub
- Submit a pull request with fixes
- Share your own examples

---

**Note**: Examples are provided as-is for educational purposes. Always test in non-production environments first.
