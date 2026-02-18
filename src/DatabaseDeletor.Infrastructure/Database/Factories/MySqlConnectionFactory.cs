using System.Data;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using MySqlConnector;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class MySqlConnectionFactory : IDbConnectionFactory
{
    public DatabaseProvider Provider => DatabaseProvider.MySql;

    public IDbConnection CreateConnection(string connectionString) =>
        new MySqlConnection(connectionString);

    public bool CanHandle(string connectionString)
    {
        ArgumentNullException.ThrowIfNull(connectionString);
        return connectionString.Contains("Server=", StringComparison.OrdinalIgnoreCase)
            && connectionString.Contains("Port=", StringComparison.OrdinalIgnoreCase);
    }
}
