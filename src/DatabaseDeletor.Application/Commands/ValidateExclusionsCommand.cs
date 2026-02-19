using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record ValidateExclusionsCommand(
    string ConnectionString,
    IReadOnlyList<TableInfo> SelectedTables,
    IReadOnlyList<TableInfo> ExcludedTables) : IRequest<ExclusionAnalysisResult>;
