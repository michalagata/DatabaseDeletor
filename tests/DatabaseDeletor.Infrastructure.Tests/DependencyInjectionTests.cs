namespace DatabaseDeletor.Infrastructure.Tests;

using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

public sealed class DependencyInjectionTests
{
    [Fact]
    public void AddInfrastructure_RegistersDatabaseProviderResolver()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure();

        var provider = services.BuildServiceProvider();

        var resolver = provider.GetService<IDatabaseProviderResolver>();
        resolver.Should().NotBeNull();
    }

    [Fact]
    public void AddInfrastructure_RegistersFourConnectionFactories()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure();

        var provider = services.BuildServiceProvider();

        var factories = provider.GetServices<IDbConnectionFactory>();
        factories.Should().HaveCount(4);
    }

    [Fact]
    public void AddInfrastructure_RegistersFourSchemaIntrospectors()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure();

        var provider = services.BuildServiceProvider();

        var introspectors = provider.GetServices<ISchemaIntrospector>();
        introspectors.Should().HaveCount(4);
        introspectors.Select(i => i.Provider).Should().Contain(DatabaseProvider.SqlServer);
        introspectors.Select(i => i.Provider).Should().Contain(DatabaseProvider.PostgreSql);
        introspectors.Select(i => i.Provider).Should().Contain(DatabaseProvider.MySql);
        introspectors.Select(i => i.Provider).Should().Contain(DatabaseProvider.Oracle);
    }

    [Fact]
    public void AddInfrastructure_RegistersFourBulkDeleteExecutors()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure();

        var provider = services.BuildServiceProvider();

        var executors = provider.GetServices<IBulkDeleteExecutor>();
        executors.Should().HaveCount(4);
        executors.Select(e => e.Provider).Should().Contain(DatabaseProvider.SqlServer);
        executors.Select(e => e.Provider).Should().Contain(DatabaseProvider.PostgreSql);
        executors.Select(e => e.Provider).Should().Contain(DatabaseProvider.MySql);
        executors.Select(e => e.Provider).Should().Contain(DatabaseProvider.Oracle);
    }

    [Fact]
    public void AddInfrastructure_RegistersCoreServices()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure();

        var provider = services.BuildServiceProvider();

        provider.GetService<IDependencyAnalyzer>().Should().NotBeNull();
        provider.GetService<IDeletionPlanGenerator>().Should().NotBeNull();
        provider.GetService<IDeletionExecutor>().Should().NotBeNull();
    }

    [Fact]
    public void AddInfrastructure_ReturnsServiceCollection()
    {
        var services = new ServiceCollection();

        var result = services.AddInfrastructure();

        result.Should().BeSameAs(services);
    }
}
