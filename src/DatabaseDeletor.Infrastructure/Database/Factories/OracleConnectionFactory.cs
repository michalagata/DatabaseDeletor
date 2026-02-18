using System.Data;
using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Oracle.ManagedDataAccess.Client;

namespace DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class OracleConnectionFactory : IDbConnectionFactory
{
    public DatabaseProvider Provider => DatabaseProvider.Oracle;

    public IDbConnection CreateConnection(string connectionString) =>
        new OracleConnection(connectionString);

    public bool CanHandle(string connectionString)
    {
        ArgumentNullException.ThrowIfNull(connectionString);
        return connectionString.Contains("Data Source=", StringComparison.OrdinalIgnoreCase)
            && connectionString.Contains("User Id=", StringComparison.OrdinalIgnoreCase);
    }
}
