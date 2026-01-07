# Solution Architecture

This document describes the architecture of the Adaptive Cloud Health Dashboard solution.

## Overview

The solution uses Azure-native services to collect, aggregate, analyze, and visualize data from Azure Local (formerly Azure Stack HCI), AKS Arc, and Arc-enabled services across multiple subscriptions.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Data Sources                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Azure Local  │  │  AKS Arc     │  │ Arc-Enabled  │              │
│  │   Clusters   │  │  Clusters    │  │   Services   │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
└────────────────────────────┼─────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Data Collection Layer                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│  │ Azure Monitor   │  │ Arc Agents       │  │ Custom Metrics   │   │
│  │ Agent           │  │ (Connected M/c)  │  │ Collection       │   │
│  └────────┬────────┘  └────────┬─────────┘  └────────┬─────────┘   │
│           │                    │                      │             │
│           └────────────────────┴──────────────────────┘             │
│                                │                                     │
└────────────────────────────────┼─────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Data Storage & Processing                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │             Log Analytics Workspace                       │       │
│  │  • Ingestion & Retention                                  │       │
│  │  • KQL Query Engine                                       │       │
│  │  • Data Transformation                                    │       │
│  └────────────────────┬─────────────────────────────────────┘       │
│                       │                                              │
│  ┌────────────────────┴─────────────────────────────────────┐       │
│  │          Azure Resource Graph                             │       │
│  │  • Resource Inventory                                     │       │
│  │  • Cross-Subscription Queries                             │       │
│  │  • Relationship Mapping                                   │       │
│  └────────────────────┬─────────────────────────────────────┘       │
│                       │                                              │
└───────────────────────┼──────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐           ┌──────────────────────┐        │
│  │  Azure Workbooks     │           │  Power BI            │        │
│  │  • Health Dashboard  │           │  • Predictive        │        │
│  │  • Compliance View   │◄─────────►│    Analytics         │        │
│  │  • Performance       │           │  • Advanced Reports  │        │
│  │  • Inventory         │           │  • Custom Visuals    │        │
│  └──────────────────────┘           └──────────────────────┘        │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Data Sources

#### Azure Local (Azure Stack HCI) Clusters
- **Metrics**: CPU, memory, storage, network performance
- **Health**: Cluster health status, node status, fault domains
- **Events**: System events, alerts, updates
- **Collection Method**: Azure Monitor Agent, Arc integration

#### AKS Arc Clusters
- **Metrics**: Node metrics, pod metrics, container performance
- **Health**: Cluster status, node readiness, deployment health
- **Logs**: Container logs, Kubernetes events
- **Collection Method**: Azure Monitor Container Insights

#### Arc-Enabled Services
- **Servers**: Performance metrics, security posture, update status
- **SQL**: Database metrics, query performance
- **Data Services**: Azure Arc-enabled data services metrics
- **Collection Method**: Arc agents, Azure Monitor

### 2. Data Collection Layer

#### Azure Monitor Agent (AMA)
- Collects performance counters and logs
- Supports Windows and Linux
- Data Collection Rules (DCR) for targeted collection
- Minimal performance impact

#### Arc Connected Machine Agent
- Enables Azure management capabilities
- Provides inventory and metadata
- Supports extensions for monitoring
- Secure communication via Azure Arc

#### Custom Metrics Collection
- PowerShell-based collectors for specific metrics
- Azure Functions for data transformation
- API-based collection for external systems

### 3. Data Storage & Processing

#### Log Analytics Workspace
- **Purpose**: Central data repository for all telemetry
- **Retention**: Configurable (default: 90 days)
- **Query Language**: Kusto Query Language (KQL)
- **Features**:
  - Real-time ingestion
  - Advanced analytics
  - Integration with Azure Monitor
  - Cost-effective storage

#### Azure Resource Graph
- **Purpose**: Resource inventory and relationship queries
- **Features**:
  - Cross-subscription queries
  - Fast resource discovery
  - Change tracking
  - Compliance queries
- **Limits**: Throttling at 5,000 queries/5 min per tenant

### 4. Presentation Layer

#### Azure Workbooks
- **Technology**: JSON-based interactive reports
- **Features**:
  - Parameterized queries
  - Interactive visualizations
  - Responsive design
  - Version control support
- **Advantages**:
  - No additional cost
  - Native Azure integration
  - Easy to share and deploy
  - Access control via Azure RBAC

#### Power BI (Optional)
- **Technology**: Power BI Desktop and Service
- **Features**:
  - Advanced visualizations
  - Predictive analytics
  - Custom calculations (DAX)
  - Scheduled refresh
- **Use Cases**:
  - Executive dashboards
  - Capacity forecasting
  - Trend analysis
  - Custom ML models

## Data Flow

### 1. Collection
```
Source Systems → Agents → Data Collection Rules → Log Analytics
```

### 2. Processing
```
Log Analytics → KQL Queries → Aggregation/Transformation → Results
Resource Graph → API → JSON Response
```

### 3. Visualization
```
Workbook/Power BI → Query Execution → Render Visuals → User Interaction
```

## Security Architecture

### Identity & Access Management
- **Azure RBAC**: Role-based access to workbooks and data
- **Managed Identities**: For automated scripts and functions
- **Azure AD Integration**: Single sign-on for all users

### Data Security
- **Encryption at Rest**: Log Analytics data encrypted with Microsoft-managed keys
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Private Link**: Optional private connectivity to Log Analytics
- **Network Isolation**: VNet integration for enhanced security

### Compliance
- **Audit Logging**: All access and queries logged
- **Data Residency**: Control over data storage location
- **Retention Policies**: Automated data lifecycle management

## Scalability

### Performance Optimization
- **Query Optimization**: Efficient KQL queries with filters and summarization
- **Caching**: Workbook parameter caching
- **Partitioning**: Time-based query partitioning
- **Resource Graph**: For fast inventory queries

### Capacity Planning
- **Log Analytics**: Scales automatically with data ingestion
- **Query Performance**: Optimized for < 30 second query execution
- **Concurrent Users**: Supports hundreds of concurrent workbook users

### Limits & Quotas
- **Log Analytics Ingestion**: 4 MB/min per source (default)
- **Query Timeout**: 3 minutes (can be extended)
- **Resource Graph**: Rate limiting applies
- **Workbook Size**: Recommended < 10 MB JSON

## High Availability & Disaster Recovery

### Azure Services HA
- **Log Analytics**: Zone-redundant (in supported regions)
- **Resource Graph**: Global service with automatic failover
- **Workbooks**: Stored in Azure Resource Manager (ARM)

### Backup & Recovery
- **Workbook Backup**: Export to JSON, store in Git
- **Query Backup**: Versioned in source control
- **Log Analytics**: Built-in data redundancy

### Business Continuity
- **RTO**: < 1 hour (re-import workbooks)
- **RPO**: Zero (live data from sources)
- **Failover**: No manual failover required

## Cost Optimization

### Cost Structure
- **Log Analytics**: Pay per GB ingested + retention
- **Resource Graph**: Free (subject to throttling)
- **Workbooks**: Free
- **Power BI**: Pro or Premium license (if used)

### Cost Optimization Strategies
1. **Optimize Data Collection**: Collect only necessary metrics
2. **Set Appropriate Retention**: Use shorter retention for verbose logs
3. **Query Optimization**: Reduce query complexity and frequency
4. **Data Sampling**: Use sampling for non-critical metrics
5. **Commitment Tiers**: Use Log Analytics commitment tiers for large volumes

### Estimated Costs (Example)
```
Assumptions:
- 50 Azure Local nodes
- 100 AKS Arc nodes
- 200 Arc-enabled servers
- ~500 GB/month ingestion
- 90-day retention

Monthly Cost:
- Log Analytics Ingestion: ~$100-150
- Log Analytics Retention: ~$50-75
- Total: ~$150-225/month
```

## Integration Points

### Azure Services
- Azure Monitor
- Azure Arc
- Azure Resource Graph
- Azure Policy
- Azure Sentinel (optional)

### External Services
- ServiceNow (via API)
- PagerDuty (for alerting)
- Slack/Teams (notifications)
- Custom ITSM systems

## Deployment Models

### 1. Single Subscription
- Simplest deployment
- All resources in one subscription
- Suitable for single-customer scenarios

### 2. Multi-Subscription (Hub-Spoke)
- Central Log Analytics workspace
- Data from multiple subscriptions
- Recommended for enterprise deployments

### 3. Multi-Tenant
- Lighthouse for cross-tenant access
- Separate workspaces per customer
- MSP/partner scenarios

## Technology Stack

- **Languages**: Kusto Query Language (KQL), PowerShell, JSON
- **Azure Services**: Log Analytics, Resource Graph, Workbooks, Azure Monitor, Arc
- **Optional**: Power BI, Azure Functions, Logic Apps
- **DevOps**: Git, GitHub Actions, Azure DevOps

## Future Enhancements

- Azure OpenAI integration for anomaly detection
- Auto-remediation via Azure Automation
- Enhanced predictive analytics
- Mobile app support
- Custom notification channels

---

For implementation details, see [Setup Guide](setup/SETUP.md).
