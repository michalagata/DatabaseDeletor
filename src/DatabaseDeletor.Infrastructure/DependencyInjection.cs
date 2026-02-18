using DatabaseDeletor.Domain.Interfaces;
using DatabaseDeletor.Infrastructure.Database.Executors;
using DatabaseDeletor.Infrastructure.Database.Factories;
using DatabaseDeletor.Infrastructure.Database.Introspectors;
using DatabaseDeletor.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DatabaseDeletor.Infrastructure;

#pragma warning disable CA1724 // Type name conflicts with namespace — standard .NET DI extension pattern
public static class DependencyInjection
#pragma warning restore CA1724
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        // Provider resolver
        services.AddSingleton<IDatabaseProviderResolver, DatabaseProviderResolver>();

        // Connection factories
        services.AddSingleton<IDbConnectionFactory, SqlServerConnectionFactory>();
        services.AddSingleton<IDbConnectionFactory, PostgreSqlConnectionFactory>();
        services.AddSingleton<IDbConnectionFactory, MySqlConnectionFactory>();
        services.AddSingleton<IDbConnectionFactory, OracleConnectionFactory>();

        // Schema introspectors
        services.AddSingleton<ISchemaIntrospector, SqlServerSchemaIntrospector>();
        services.AddSingleton<ISchemaIntrospector, PostgreSqlSchemaIntrospector>();
        services.AddSingleton<ISchemaIntrospector, MySqlSchemaIntrospector>();
        services.AddSingleton<ISchemaIntrospector, OracleSchemaIntrospector>();

        // Bulk delete executors
        services.AddSingleton<IBulkDeleteExecutor, SqlServerBulkDeleteExecutor>();
        services.AddSingleton<IBulkDeleteExecutor, PostgreSqlBulkDeleteExecutor>();
        services.AddSingleton<IBulkDeleteExecutor, MySqlBulkDeleteExecutor>();
        services.AddSingleton<IBulkDeleteExecutor, OracleBulkDeleteExecutor>();

        // Core services
        services.AddSingleton<IDependencyAnalyzer, DependencyAnalyzer>();
        services.AddSingleton<IDeletionPlanGenerator, DeletionPlanGenerator>();
        services.AddSingleton<IDeletionExecutor, DeletionExecutor>();

        return services;
    }
}
