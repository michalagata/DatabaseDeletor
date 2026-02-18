namespace DatabaseDeletor.Domain.Exceptions;

public class DatabaseDeletorException : Exception
{
    public DatabaseDeletorException() { }
    public DatabaseDeletorException(string message) : base(message) { }
    public DatabaseDeletorException(string message, Exception innerException) : base(message, innerException) { }
}

public sealed class ConnectionException : DatabaseDeletorException
{
    public ConnectionException() { }
    public ConnectionException(string message) : base(message) { }
    public ConnectionException(string message, Exception innerException) : base(message, innerException) { }
}

public sealed class SchemaIntrospectionException : DatabaseDeletorException
{
    public SchemaIntrospectionException() { }
    public SchemaIntrospectionException(string message) : base(message) { }
    public SchemaIntrospectionException(string message, Exception innerException) : base(message, innerException) { }
}

public sealed class DeletionException : DatabaseDeletorException
{
    public DeletionException() { }
    public DeletionException(string message) : base(message) { }
    public DeletionException(string message, Exception innerException) : base(message, innerException) { }
}

public sealed class UnsupportedProviderException : DatabaseDeletorException
{
    public UnsupportedProviderException() { }

    public UnsupportedProviderException(string message) : base(message) { }

    public UnsupportedProviderException(string message, Exception innerException) : base(message, innerException) { }

    public static UnsupportedProviderException ForConnectionString(string connectionString) =>
        new($"Cannot determine database provider from connection string. Supported: SQL Server, PostgreSQL, MySQL, Oracle.");
}

public sealed class SqlParseException : DatabaseDeletorException
{
    public SqlParseException() { }
    public SqlParseException(string message) : base(message) { }
    public SqlParseException(string message, Exception innerException) : base(message, innerException) { }
}
