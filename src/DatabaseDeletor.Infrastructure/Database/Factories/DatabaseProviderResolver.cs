using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class DatabaseProviderResolver : IDatabaseProviderResolver
{
    public DatabaseProvider Resolve(string connectionString)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(connectionString);

        var lower = connectionString.ToLowerInvariant();

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
        cs.Contains("server=") && cs.Contains("database=") && !cs.Contains("port=") && !cs.Contains("host=")
        || cs.Contains("data source=") && cs.Contains("initial catalog=")
        || cs.Contains("sqlserver", StringComparison.OrdinalIgnoreCase);

    private static bool ContainsPostgresMarkers(string cs) =>
        cs.Contains("host=") && cs.Contains("database=") && !cs.Contains("data source=")
        || cs.Contains("npgsql")
        || cs.Contains("postgres");

    private static bool ContainsMySqlMarkers(string cs) =>
        cs.Contains("server=") && cs.Contains("database=") && cs.Contains("port=")
        || cs.Contains("mysql");

    private static bool ContainsOracleMarkers(string cs) =>
        cs.Contains("data source=") && cs.Contains("user id=")
        || cs.Contains("oracle")
        || cs.Contains("tns_admin");
}
