namespace DatabaseDeletor.Application.Tests;

using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

public sealed class DependencyInjectionTests
{
    [Fact]
    public void AddApplication_RegistersMediator()
    {
        var services = new ServiceCollection();
        services.AddApplication();

        var provider = services.BuildServiceProvider();

        var mediator = provider.GetService<IMediator>();
        mediator.Should().NotBeNull();
        mediator.Should().BeOfType<Application.Mediator.Mediator>();
    }

    [Fact]
    public void AddApplication_RegistersSqlParser()
    {
        var services = new ServiceCollection();
        services.AddApplication();

        var provider = services.BuildServiceProvider();

        var parser = provider.GetService<ISqlParser>();
        parser.Should().NotBeNull();
        parser.Should().BeOfType<Application.Services.SqlParser>();
    }

    [Fact]
    public void AddApplication_RegistersCommandHandlers()
    {
        var services = new ServiceCollection();
        services.AddApplication();

        // Add required infrastructure dependencies for the handlers
        services.AddSingleton(Substitute.For<IDependencyAnalyzer>());
        services.AddSingleton(Substitute.For<IDeletionPlanGenerator>());
        services.AddSingleton(Substitute.For<IDeletionExecutor>());
        services.AddSingleton(Substitute.For<Microsoft.Extensions.Logging.ILogger<DatabaseDeletor.Application.Commands.AnalyzeDependenciesHandler>>());
        services.AddSingleton(Substitute.For<Microsoft.Extensions.Logging.ILogger<DatabaseDeletor.Application.Commands.GenerateDeletionPlanHandler>>());
        services.AddSingleton(Substitute.For<Microsoft.Extensions.Logging.ILogger<DatabaseDeletor.Application.Commands.ExecuteDeletionHandler>>());

        var provider = services.BuildServiceProvider();

        var analyzeHandler = provider.GetService<IRequestHandler<
            DatabaseDeletor.Application.Commands.AnalyzeDependenciesCommand,
            DatabaseDeletor.Domain.Entities.DependencyGraph>>();
        analyzeHandler.Should().NotBeNull();

        var planHandler = provider.GetService<IRequestHandler<
            DatabaseDeletor.Application.Commands.GenerateDeletionPlanCommand,
            DatabaseDeletor.Domain.Entities.DeletionPlan>>();
        planHandler.Should().NotBeNull();

        var executeHandler = provider.GetService<IRequestHandler<
            DatabaseDeletor.Application.Commands.ExecuteDeletionCommand,
            DatabaseDeletor.Domain.Entities.DeletionReport>>();
        executeHandler.Should().NotBeNull();
    }

    [Fact]
    public void AddApplication_ReturnsServiceCollection()
    {
        var services = new ServiceCollection();

        var result = services.AddApplication();

        result.Should().BeSameAs(services);
    }
}
