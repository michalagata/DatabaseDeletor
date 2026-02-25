using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Commands;

public sealed record GetColumnsCommand(
    string ConnectionString,
    string Schema,
    string TableName) : IRequest<IReadOnlyList<ColumnInfo>>;
