using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class DatabaseProviderResolver : IDatabaseProviderResolver
{
    public DatabaseProvider Resolve(string connectionString)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(connectionString);

        var lower = connectionString.ToUpperInvariant();

        if (ContainsSqlServerMarkers(lower))
            return DatabaseProvider.SqlServer;

        if (ContainsPostgresMarkers(lower))
            return DatabaseProvider.PostgreSql;

        if (ContainsMySqlMarkers(lower))
            return DatabaseProvider.MySql;

        if (ContainsOracleMarkers(lower))
            return DatabaseProvider.Oracle;

        throw UnsupportedProviderException.ForConnectionString(connectionString);
    }

    private static bool ContainsSqlServerMarkers(string cs) =>
        cs.Contains("SERVER=", StringComparison.Ordinal) && cs.Contains("DATABASE=", StringComparison.Ordinal) && !cs.Contains("PORT=", StringComparison.Ordinal) && !cs.Contains("HOST=", StringComparison.Ordinal)
        || cs.Contains("DATA SOURCE=", StringComparison.Ordinal) && cs.Contains("INITIAL CATALOG=", StringComparison.Ordinal)
        || cs.Contains("SQLSERVER", StringComparison.Ordinal);

    private static bool ContainsPostgresMarkers(string cs) =>
        cs.Contains("HOST=", StringComparison.Ordinal) && cs.Contains("DATABASE=", StringComparison.Ordinal) && !cs.Contains("DATA SOURCE=", StringComparison.Ordinal)
        || cs.Contains("NPGSQL", StringComparison.Ordinal)
        || cs.Contains("POSTGRES", StringComparison.Ordinal);

    private static bool ContainsMySqlMarkers(string cs) =>
        cs.Contains("SERVER=", StringComparison.Ordinal) && cs.Contains("DATABASE=", StringComparison.Ordinal) && cs.Contains("PORT=", StringComparison.Ordinal)
        || cs.Contains("MYSQL", StringComparison.Ordinal);

    private static bool ContainsOracleMarkers(string cs) =>
        cs.Contains("DATA SOURCE=", StringComparison.Ordinal) && cs.Contains("USER ID=", StringComparison.Ordinal)
        || cs.Contains("ORACLE", StringComparison.Ordinal)
        || cs.Contains("TNS_ADMIN", StringComparison.Ordinal);
}
