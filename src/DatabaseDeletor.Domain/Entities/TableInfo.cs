namespace DatabaseDeletor.Domain.Entities;

public sealed class TableInfo
{
    public required string Schema { get; init; }
    public required string Name { get; init; }
    public long RowCount { get; set; }

    public string FullName => string.IsNullOrEmpty(Schema) ? Name : $"{Schema}.{Name}";

    public override string ToString() => FullName;

    public override bool Equals(object? obj) =>
        obj is TableInfo other &&
        string.Equals(Schema, other.Schema, StringComparison.OrdinalIgnoreCase) &&
        string.Equals(Name, other.Name, StringComparison.OrdinalIgnoreCase);

    public override int GetHashCode() =>
        HashCode.Combine(
            Schema.ToUpperInvariant(),
            Name.ToUpperInvariant());
}
