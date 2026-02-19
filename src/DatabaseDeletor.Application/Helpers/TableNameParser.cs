using DatabaseDeletor.Domain.Entities;

namespace DatabaseDeletor.Application.Helpers;

/// <summary>
/// Parses table names from string entries that may be comma-separated
/// and optionally include schema prefixes (e.g., "dbo.Users,dbo.Orders").
/// </summary>
public static class TableNameParser
{
    /// <summary>
    /// Parses one or more string entries into <see cref="TableInfo"/> instances.
    /// Each entry may contain multiple comma-separated table names.
    /// Table names can be "schema.table" or just "table" (schema defaults to empty).
    /// </summary>
    public static IReadOnlyList<TableInfo> Parse(params string[] entries)
    {
        ArgumentNullException.ThrowIfNull(entries);

        var result = new List<TableInfo>();

        foreach (var entry in entries)
        {
            if (string.IsNullOrWhiteSpace(entry))
                continue;

            var names = entry.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);

            foreach (var name in names)
            {
                var parts = name.Split('.', 2);
                if (parts.Length == 2)
                {
                    result.Add(new TableInfo { Schema = parts[0], Name = parts[1] });
                }
                else
                {
                    result.Add(new TableInfo { Schema = string.Empty, Name = parts[0] });
                }
            }
        }

        return result;
    }
}
