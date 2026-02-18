using System.Data;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Npgsql;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class PostgreSqlConnectionFactory : IDbConnectionFactory
{
    public DatabaseProvider Provider => DatabaseProvider.PostgreSql;

    public IDbConnection CreateConnection(string connectionString) =>
        new NpgsqlConnection(connectionString);

    public bool CanHandle(string connectionString) =>
        connectionString.Contains("Host=", StringComparison.OrdinalIgnoreCase)
        && connectionString.Contains("Database=", StringComparison.OrdinalIgnoreCase);
}
