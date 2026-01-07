# Adaptive Cloud Health Dashboard

A generic, reusable dashboard solution for monitoring and managing Adaptive Cloud environments across Azure Local (formerly Azure Stack HCI), AKS Arc, and Arc-enabled services.

## 🎯 Overview

This solution provides a centralized view of health, status, inventory, compliance, and performance across multiple Azure subscriptions. It's designed to be completely generic and customizable for any customer environment.

## ✨ Features

- **Multi-Subscription Support**: Aggregate data across multiple Azure subscriptions
- **Health & Status Monitoring**: Real-time health checks for Azure Local and AKS Arc clusters
- **Compliance Tracking**: Monitor policy compliance and configuration drift
- **Performance Metrics**: Track resource utilization, capacity, and performance trends
- **Predictive Insights**: Optional forecasting for capacity planning and risk assessment
- **Custom KPIs**: Health scores, compliance index, and capacity risk indicators

## 📁 Project Structure

```
/src                    # Core dashboard code
  /workbooks           # Azure Workbook JSON templates
  /queries             # Kusto (KQL) queries for data retrieval
  /functions           # Azure Functions for data processing (optional)
/docs                  # Documentation
  /setup              # Setup and deployment guides
  /customization      # Customization instructions
/templates             # Advanced templates
  /powerbi            # Power BI templates (.pbix)
  /arm                # ARM/Bicep templates for deployment
/scripts               # Automation scripts
  /git                # Git workflow automation
  /deployment         # Deployment automation
/examples              # Sample dashboards and queries
  /workbooks          # Example workbook configurations
  /queries            # Sample query collections
```

## 🚀 Quick Start

### Prerequisites

- Azure subscription(s) with:
  - Azure Local clusters and/or AKS Arc clusters
  - Azure Arc-enabled services
  - Log Analytics workspace
- Azure CLI installed
- PowerShell 7+ (for automation scripts)
- (Optional) Power BI Desktop for advanced visualizations

### Setup Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/adaptive-cloud-health-dashboard.git
   cd adaptive-cloud-health-dashboard
   ```

2. **Configure your environment**:
   ```powershell
   # Edit the configuration file with your subscription details
   .\scripts\deployment\Configure-Environment.ps1
   ```

3. **Deploy Azure resources**:
   ```powershell
   # Deploy Log Analytics workspace and required resources
   .\scripts\deployment\Deploy-Resources.ps1
   ```

4. **Import Workbooks**:
   ```powershell
   # Import workbook templates to your Azure subscription
   .\scripts\deployment\Import-Workbooks.ps1
   ```

5. **Access your dashboards**:
   - Navigate to Azure Portal > Monitor > Workbooks
   - Select "Adaptive Cloud Health Dashboard" from your workbooks

## 📊 Dashboard Components

### 1. Global Inventory Dashboard
- Complete inventory of Azure Local clusters
- AKS Arc cluster catalog
- Arc-enabled servers and services
- Resource distribution across subscriptions

### 2. Health & Status Overview
- Real-time health status of all resources
- Alert aggregation and prioritization
- Incident tracking and resolution status
- Overall health score calculation

### 3. Compliance Dashboard
- Azure Policy compliance status
- Configuration drift detection
- Security baseline compliance
- Compliance index scoring

### 4. Performance Dashboard
- CPU, memory, and storage utilization
- Network performance metrics
- Capacity trends and forecasting
- Performance anomaly detection

### 5. Predictive Analytics (Power BI)
- Capacity forecast modeling
- Resource growth predictions
- Cost optimization recommendations
- Risk assessment scoring

## 🔧 Customization

All dashboards are fully parameterized and can be customized without code changes:

- **Subscriptions**: Configure which subscriptions to monitor
- **Resource Groups**: Filter by specific resource groups
- **Cluster Names**: Target specific clusters or use wildcards
- **Thresholds**: Adjust alert thresholds and scoring criteria
- **Time Ranges**: Customize default time ranges for queries

See [docs/customization](./docs/customization/) for detailed instructions.

## 🤖 Git Automation

Automation scripts are provided for streamlined Git workflows:

```powershell
# Initialize new feature branch
.\scripts\git\New-FeatureBranch.ps1 -BranchName "feature/my-feature"

# Commit changes with standardized messages
.\scripts\git\Save-Changes.ps1 -Message "Add new query" -Type "feat"

# Push changes and create pull request
.\scripts\git\Publish-Changes.ps1 -CreatePR
```

## 📖 Documentation

- [Setup Guide](./docs/setup/SETUP.md) - Detailed deployment instructions
- [Customization Guide](./docs/customization/CUSTOMIZATION.md) - How to tailor dashboards
- [Query Reference](./docs/QUERY_REFERENCE.md) - KQL query documentation
- [Architecture](./docs/ARCHITECTURE.md) - Solution architecture and design
- [Contributing](./CONTRIBUTING.md) - Contribution guidelines

## 🔐 Security & Compliance

- Uses Azure RBAC for access control
- No hardcoded credentials or customer-specific data
- Follows Azure Well-Architected Framework principles
- Supports Azure Private Link for secure connectivity

## 🆘 Support

For issues, questions, or contributions:
- Create an issue in this repository
- Review existing documentation
- Submit pull requests for improvements

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built for Azure Local, AKS Arc, and Arc-enabled services monitoring. Designed to provide value beyond standard Azure Portal capabilities through aggregation, custom KPIs, and predictive insights.

---

**Version**: 1.0.0  
**Last Updated**: January 2026
