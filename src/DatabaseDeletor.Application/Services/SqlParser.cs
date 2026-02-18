using System.Text.RegularExpressions;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Domain.Interfaces;

namespace DatabaseDeletor.Application.Services;

public sealed partial class SqlParser : ISqlParser
{
    public ParsedQuery Parse(string sql)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(sql);

        var trimmed = sql.Trim().TrimEnd(';');

        var match = DeleteRegex().Match(trimmed);
        if (!match.Success)
        {
            match = SelectRegex().Match(trimmed);
        }

        if (!match.Success)
        {
            throw new SqlParseException(
                $"Cannot parse SQL statement. Expected DELETE FROM or SELECT FROM syntax. Got: {sql}");
        }

        var tablePart = match.Groups["table"].Value.Trim();
        var wherePart = match.Groups["where"].Success ? match.Groups["where"].Value.Trim() : null;

        var (schema, tableName) = ParseTableName(tablePart);

        return new ParsedQuery
        {
            Schema = schema,
            TableName = tableName,
            WhereClause = string.IsNullOrWhiteSpace(wherePart) ? null : wherePart
        };
    }

    private static (string Schema, string TableName) ParseTableName(string tablePart)
    {
        var cleaned = tablePart
            .Replace("[", "")
            .Replace("]", "")
            .Replace("\"", "")
            .Replace("`", "");

        var parts = cleaned.Split('.', StringSplitOptions.RemoveEmptyEntries);

        return parts.Length switch
        {
            1 => ("dbo", parts[0]),
            2 => (parts[0], parts[1]),
            3 => (parts[1], parts[2]),
            _ => throw new SqlParseException($"Cannot parse table name: {tablePart}")
        };
    }

    [GeneratedRegex(@"^\s*DELETE\s+FROM\s+(?<table>[^\s]+)(\s+WHERE\s+(?<where>.+))?$",
        RegexOptions.IgnoreCase | RegexOptions.Singleline)]
    private static partial Regex DeleteRegex();

    [GeneratedRegex(@"^\s*SELECT\s+.+\s+FROM\s+(?<table>[^\s]+)(\s+WHERE\s+(?<where>.+))?$",
        RegexOptions.IgnoreCase | RegexOptions.Singleline)]
    private static partial Regex SelectRegex();
}
