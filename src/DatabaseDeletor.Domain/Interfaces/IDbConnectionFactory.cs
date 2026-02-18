using System.Data;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IDbConnectionFactory
{
    DatabaseProvider Provider { get; }
    IDbConnection CreateConnection(string connectionString);
    bool CanHandle(string connectionString);
}
