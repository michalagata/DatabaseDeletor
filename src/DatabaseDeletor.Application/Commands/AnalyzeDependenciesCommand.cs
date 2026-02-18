using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record AnalyzeDependenciesCommand(
    string ConnectionString,
    string Schema,
    string TableName) : IRequest<DependencyGraph>;
