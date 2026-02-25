using DatabaseDeletor.Application.Commands;
using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace DatabaseDeletor.Application;

#pragma warning disable CA1724 // Type name conflicts with namespace — standard .NET DI extension pattern
public static class DependencyInjection
#pragma warning restore CA1724
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton<IMediator, Mediator.Mediator>();
        services.AddSingleton<ISqlParser, SqlParser>();

        services.AddTransient<IRequestHandler<AnalyzeDependenciesCommand, DependencyGraph>, AnalyzeDependenciesHandler>();
        services.AddTransient<IRequestHandler<GenerateDeletionPlanCommand, DeletionPlan>, GenerateDeletionPlanHandler>();
        services.AddTransient<IRequestHandler<ExecuteDeletionCommand, DeletionReport>, ExecuteDeletionHandler>();
        services.AddTransient<IRequestHandler<GetAllTablesCommand, IReadOnlyList<TableInfo>>, GetAllTablesHandler>();
        services.AddTransient<IRequestHandler<ValidateExclusionsCommand, ExclusionAnalysisResult>, ValidateExclusionsHandler>();
        services.AddTransient<IRequestHandler<GetColumnsCommand, IReadOnlyList<ColumnInfo>>, GetColumnsHandler>();

        return services;
    }
}
