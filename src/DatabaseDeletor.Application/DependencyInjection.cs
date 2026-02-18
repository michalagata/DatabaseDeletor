using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace DatabaseDeletor.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton<IMediator, Mediator.Mediator>();
        services.AddSingleton<ISqlParser, SqlParser>();

        services.AddTransient<IRequestHandler<AnalyzeDependenciesCommand, DependencyGraph>, AnalyzeDependenciesHandler>();
        services.AddTransient<IRequestHandler<GenerateDeletionPlanCommand, DeletionPlan>, GenerateDeletionPlanHandler>();
        services.AddTransient<IRequestHandler<ExecuteDeletionCommand, DeletionReport>, ExecuteDeletionHandler>();

        return services;
    }
}
