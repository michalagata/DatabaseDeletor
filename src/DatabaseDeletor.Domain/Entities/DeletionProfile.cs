using System.Text.Json.Serialization;

namespace DatabaseDeletor.Domain.Entities;

public sealed record DeletionProfile
{
    public const string CurrentVersion = "1.0";

    [JsonPropertyName("version")]
    public string Version { get; init; } = CurrentVersion;

    [JsonPropertyName("connectionString")]
    public string ConnectionString { get; init; } = string.Empty;

    [JsonPropertyName("sql")]
    public string? Sql { get; init; }

    [JsonPropertyName("excludedTables")]
    public IReadOnlyList<string> ExcludedTables { get; init; } = [];

    [JsonPropertyName("deletionSettings")]
    public DeletionSettingsProfile DeletionSettings { get; init; } = new();

    [JsonPropertyName("scope")]
    public ScopeProfile? Scope { get; init; }
}

public sealed record DeletionSettingsProfile
{
    [JsonPropertyName("mode")]
    public string Mode { get; init; } = "BatchDelete";

    [JsonPropertyName("batchSize")]
    public int BatchSize { get; init; } = DeletionOptions.DefaultBatchSize;

    [JsonPropertyName("useTransaction")]
    public bool UseTransaction { get; init; }
}

public sealed record ScopeProfile
{
    [JsonPropertyName("rootTable")]
    public string RootTable { get; init; } = string.Empty;

    [JsonPropertyName("scopeMode")]
    public string ScopeMode { get; init; } = "DeleteAll";

    [JsonPropertyName("whereConditions")]
    public IReadOnlyList<WhereConditionProfile> WhereConditions { get; init; } = [];

    [JsonPropertyName("customSql")]
    public string? CustomSql { get; init; }
}

public sealed record WhereConditionProfile
{
    [JsonPropertyName("column")]
    public string Column { get; init; } = string.Empty;

    [JsonPropertyName("operator")]
    public string Operator { get; init; } = "=";

    [JsonPropertyName("value")]
    public string Value { get; init; } = string.Empty;

    [JsonPropertyName("logicalOperator")]
    public string LogicalOperator { get; init; } = "AND";
}
