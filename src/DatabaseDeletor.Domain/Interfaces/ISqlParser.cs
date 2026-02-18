namespace DatabaseDeletor.Domain.Interfaces;

public interface ISqlParser
{
    ParsedQuery Parse(string sql);
}

public sealed class ParsedQuery
{
    public required string Schema { get; init; }
    public required string TableName { get; init; }
    public string? WhereClause { get; init; }
}
