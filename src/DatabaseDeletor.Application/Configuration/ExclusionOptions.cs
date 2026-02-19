using DatabaseDeletor.Application.Helpers;
using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Application.Configuration;

/// <summary>
/// Configuration options for globally excluded tables.
/// Bind to the "Exclusion" section in appsettings.json.
/// </summary>
public sealed class ExclusionOptions
{
    /// <summary>
    /// The configuration section name.
    /// </summary>
    public const string SectionName = "Exclusion";

    /// <summary>
    /// Comma-separated list of table names to always exclude from deletion.
    /// Format: "schema.table" or just "table". Example: "dbo.AuditLog,dbo.SystemConfig".
    /// </summary>
    public string GlobalExcludedTables { get; set; } = string.Empty;

    /// <summary>
    /// Parses the <see cref="GlobalExcludedTables"/> string into a list of <see cref="TableInfo"/>.
    /// </summary>
    public IReadOnlyList<TableInfo> GetParsedTables() => TableNameParser.Parse(GlobalExcludedTables);
}
