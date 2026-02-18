using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Interfaces;

public interface IDatabaseProviderResolver
{
    DatabaseProvider Resolve(string connectionString);
}
