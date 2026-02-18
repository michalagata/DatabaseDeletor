using System.Data;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Data.SqlClient;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class SqlServerConnectionFactory : IDbConnectionFactory
{
    public DatabaseProvider Provider => DatabaseProvider.SqlServer;

    public IDbConnection CreateConnection(string connectionString) =>
        new SqlConnection(connectionString);

    public bool CanHandle(string connectionString) =>
        connectionString.Contains("Server=", StringComparison.OrdinalIgnoreCase)
        && connectionString.Contains("Database=", StringComparison.OrdinalIgnoreCase)
        && !connectionString.Contains("Host=", StringComparison.OrdinalIgnoreCase);
}
