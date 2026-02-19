using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record GetAllTablesCommand(
    string ConnectionString) : IRequest<IReadOnlyList<TableInfo>>;
