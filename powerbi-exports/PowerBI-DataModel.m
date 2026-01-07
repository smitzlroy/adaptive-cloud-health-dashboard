// ===================================================
// Adaptive Cloud - Power BI Data Model
// Auto-generated: 2026-01-07 15:34:05
// ===================================================

let
    // Configuration
    SourceFolder = "C:\AI\adaptive-cloud-health-dashboard\powerbi-exports",
    
    // Helper function to load CSV files
    LoadCsv = (fileName as text, tableName as text) =>
        let
            Source = Csv.Document(
                File.Contents(SourceFolder & "\" & fileName),
                [Delimiter=",", Columns=null, Encoding=65001, QuoteStyle=QuoteStyle.None]
            ),
            PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
            ChangedTypes = Table.TransformColumnTypes(
                PromotedHeaders,
                List.Transform(
                    Table.ColumnNames(PromotedHeaders),
                    each {_, type text}
                )
            )
        in
            ChangedTypes,
    
    // Load all tables
    ResourceSummary = LoadCsv("01-resource-summary.csv", "ResourceSummary"),
    HardwareCapacity = LoadCsv("02-hardware-capacity.csv", "HardwareCapacity"),
    ConnectivityStatus = LoadCsv("03-connectivity-status.csv", "ConnectivityStatus"),
    Configuration = LoadCsv("04-configuration.csv", "Configuration"),
    SecurityPosture = LoadCsv("05-security-posture.csv", "SecurityPosture"),
    GovernanceTags = LoadCsv("06-governance-tags.csv", "GovernanceTags"),
    PolicyCompliance = LoadCsv("07-policy-compliance.csv", "PolicyCompliance"),
    ArcExtensions = LoadCsv("08-arc-extensions.csv", "ArcExtensions"),
    KubernetesVersions = LoadCsv("09-kubernetes-versions.csv", "KubernetesVersions"),
    ArcAgentVersions = LoadCsv("10-arc-agent-versions.csv", "ArcAgentVersions"),
    ResourceLifecycle = LoadCsv("11-resource-lifecycle.csv", "ResourceLifecycle"),
    ZombieResources = LoadCsv("12-zombie-resources.csv", "ZombieResources"),
    LocationDistribution = LoadCsv("13-location-distribution.csv", "LocationDistribution"),
    Rightsizing = LoadCsv("14-rightsizing.csv", "Rightsizing")
    
    // Return all tables as a record
    Output = [
        ResourceSummary = ResourceSummary,
        HardwareCapacity = HardwareCapacity,
        ConnectivityStatus = ConnectivityStatus,
        Configuration = Configuration,
        SecurityPosture = SecurityPosture,
        GovernanceTags = GovernanceTags,
        PolicyCompliance = PolicyCompliance,
        ArcExtensions = ArcExtensions,
        KubernetesVersions = KubernetesVersions,
        ArcAgentVersions = ArcAgentVersions,
        ResourceLifecycle = ResourceLifecycle,
        ZombieResources = ZombieResources,
        LocationDistribution = LocationDistribution,
        Rightsizing = Rightsizing
    ]
in
    Output
