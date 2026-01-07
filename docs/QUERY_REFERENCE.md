# Query Reference

This document provides comprehensive reference documentation for all KQL queries in the Adaptive Cloud Health Dashboard.

## Query Categories

- [Inventory Queries](#inventory-queries)
- [Health Queries](#health-queries)
- [Compliance Queries](#compliance-queries)
- [Performance Queries](#performance-queries)
- [Predictive Queries](#predictive-queries)

---

## Inventory Queries

### Azure Local Inventory

**File**: `src/queries/inventory/azure-local-inventory.kql`

**Purpose**: Retrieve complete inventory of Azure Local (Azure Stack HCI) clusters.

**Parameters**:
- `{Subscriptions}`: Array of subscription IDs to query
- `{TimeRange:range}`: Time range for the query

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| ClusterName | string | Name of the cluster |
| ResourceGroup | string | Resource group containing the cluster |
| Location | string | Azure region |
| Status | string | Current cluster status |
| NodeCount | int | Number of nodes in cluster |
| Tags | dynamic | Resource tags |

**Example Usage**:
```kusto
// Query all Azure Local clusters in specific subscription
let subscriptions = dynamic(["sub-id-1"]);
// ... rest of query
```

### AKS Arc Inventory

**File**: `src/queries/inventory/aks-arc-inventory.kql`

**Purpose**: List all AKS Arc clusters with their configuration details.

**Parameters**:
- `{Subscriptions}`: Target subscriptions
- `{TimeRange:range}`: Query time range

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| ClusterName | string | Kubernetes cluster name |
| ConnectivityStatus | string | Connection status to Azure |
| KubernetesVersion | string | K8s version |
| TotalNodeCount | int | Number of nodes |

### Arc-Enabled Servers Inventory

**File**: `src/queries/inventory/arc-servers-inventory.kql`

**Purpose**: Enumerate all Arc-enabled servers with OS and agent information.

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| MachineName | string | Server hostname |
| OSType | string | Operating system type |
| AgentVersion | string | Arc agent version |
| Status | string | Connection status |

---

## Health Queries

### Cluster Health Score

**File**: `src/queries/health/cluster-health-score.kql`

**Purpose**: Calculate comprehensive health score based on CPU, memory, and disk metrics.

**Calculation Logic**:
```
Health Score = (CPU Health × Weight) + (Memory Health × Weight) + (Disk Health × Weight)

Default Weights:
- CPU: 33.3%
- Memory: 33.3%
- Disk: 33.3%

Component Health:
- Critical (0): > 90% utilization
- Warning (50): 70-90% utilization
- Good (75): 50-70% utilization
- Healthy (100): < 50% utilization
```

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| ClusterName | string | Cluster identifier |
| OverallHealthScore | real | 0-100 health score |
| HealthLevel | string | Healthy/Warning/Degraded/Critical |
| CPUHealth | real | CPU component score |
| MemoryHealth | real | Memory component score |
| DiskHealth | real | Disk component score |

**Customization**:
Modify weights in query:
```kusto
let cpuWeight = 0.4;    // 40%
let memoryWeight = 0.35; // 35%
let diskWeight = 0.25;   // 25%
```

---

## Compliance Queries

### Policy Compliance

**File**: `src/queries/compliance/policy-compliance.kql`

**Purpose**: Aggregate Azure Policy compliance status across resources.

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| PolicyDefinitionName | string | Policy name |
| CompliancePercentage | real | % of compliant resources |
| CompliantResources | long | Count of compliant |
| NonCompliantResources | long | Count of non-compliant |
| ComplianceLevel | string | Compliant/Warning/Risk/Critical |

**Thresholds**:
- Compliant: ≥ 95%
- Warning: 80-94%
- Risk: 60-79%
- Critical: < 60%

---

## Performance Queries

### Resource Utilization

**File**: `src/queries/performance/resource-utilization.kql`

**Purpose**: Track CPU, memory, disk, and network performance metrics.

**Aggregation**: 5-minute time bins

**Metrics Collected**:
- **CPU**: Processor utilization percentage
- **Memory**: Used percentage (calculated from available MB)
- **Disk**: Used space percentage
- **Network**: In/Out throughput (MB/s)

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| TimeGenerated | datetime | Metric timestamp |
| Computer | string | Source computer |
| MetricType | string | CPU/Memory/Disk/NetworkIn/NetworkOut |
| AvgValue | real | Average value in time window |
| P95Value | real | 95th percentile |
| PerformanceLevel | string | Healthy/Warning/Critical |

**Performance Thresholds**:
- **CPU**: Warning > 70%, Critical > 90%
- **Memory**: Warning > 80%, Critical > 95%
- **Disk**: Warning > 75%, Critical > 90%

---

## Predictive Queries

### Capacity Forecast

**File**: `src/queries/predictive/capacity-forecast.kql`

**Purpose**: Predict when disk capacity will be exhausted using linear regression.

**Algorithm**: 
Uses `series_fit_line()` function to calculate trend line from historical data:
```
Projected Value = Intercept + (Slope × Days Ahead)
Days Until Full = (100 - Current Usage) / Growth Rate
```

**Returns**:
| Column | Type | Description |
|--------|------|-------------|
| ResourceName | string | Resource identifier |
| CurrentUsage | real | Current disk usage % |
| ProjectedUsageIn30Days | real | Forecasted usage |
| DaysUntilFull | real | Days until 100% capacity |
| TrendDirection | string | Increasing/Decreasing/Stable |
| CapacityRisk | string | Critical/High/Medium/Low |

**Risk Levels**:
- Critical: < 30 days until full
- High: 30-60 days
- Medium: 60-90 days
- Low: > 90 days

**Customization**:
Change forecast period:
```kusto
let forecastDays = 60; // Forecast 60 days ahead
```

---

## Common Parameters

All queries support these standard parameters:

### Subscriptions
```kusto
let subscriptions = dynamic({Subscriptions});
```
- Array of subscription IDs
- Use `dynamic([])` for all subscriptions

### TimeRange
```kusto
let timeRange = {TimeRange:range};
```
- Workbook parameter for time selection
- Typical values: 1h, 24h, 7d, 30d

### Resource Groups
```kusto
| where resourceGroup in ({ResourceGroups})
```
- Filter by specific resource groups
- Optional parameter

---

## Query Optimization Tips

### 1. Use Time Filters Early
```kusto
| where TimeGenerated > ago(timeRange)  // Early in query
```

### 2. Filter Subscriptions
```kusto
| where subscriptionId in (subscriptions)
```

### 3. Limit Columns
```kusto
| project only, columns, you, need
```

### 4. Summarize Before Join
```kusto
| summarize ... by key
| join kind=leftouter (...)
```

### 5. Use Resource Graph for Inventory
- Faster than Log Analytics for resource metadata
- No ingestion costs
- Real-time data

---

## Custom Query Development

### Template Structure
```kusto
// Query Description
// Purpose: What this query does
// Returns: What data it returns

let subscriptions = dynamic({Subscriptions});
let timeRange = {TimeRange:range};

// Additional parameters
let threshold = 80;

// Main query logic
YourTable
| where TimeGenerated > ago(timeRange)
| where _SubscriptionId in (subscriptions)
| extend CustomCalculation = ...
| summarize Metrics = ... by DimensionColumn
| project 
    DisplayColumn1,
    DisplayColumn2,
    CalculatedMetric
| order by SortColumn desc
```

### Testing Queries

Use Log Analytics workspace to test:
1. Navigate to Logs in Azure Portal
2. Paste query
3. Replace parameters with actual values
4. Run and validate results
5. Copy to `.kql` file when complete

### Best Practices

1. **Add Comments**: Explain complex logic
2. **Use Parameters**: Never hardcode values
3. **Handle Nulls**: Use `iff()` or `coalesce()`
4. **Validate Data Types**: Cast explicitly if needed
5. **Test with Production Scale**: Validate performance

---

## Workbook Integration

### Using Queries in Workbooks

1. **Add Query Step**:
   - Edit workbook
   - Add > Query
   - Paste KQL query
   - Set data source (Log Analytics or Resource Graph)

2. **Reference Parameters**:
   ```json
   {
     "query": "let subscriptions = dynamic({Subscriptions});\n...",
     "queryType": 0
   }
   ```

3. **Visualization Options**:
   - Table/Grid
   - Line Chart
   - Bar Chart
   - Pie Chart
   - Map
   - Tiles

---

## Additional Resources

- [Kusto Query Language Reference](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [Azure Resource Graph Query Examples](https://docs.microsoft.com/azure/governance/resource-graph/samples/starter)
- [Azure Monitor Log Queries](https://docs.microsoft.com/azure/azure-monitor/logs/queries)

---

For examples of queries in use, see the [examples directory](../examples/queries/).
