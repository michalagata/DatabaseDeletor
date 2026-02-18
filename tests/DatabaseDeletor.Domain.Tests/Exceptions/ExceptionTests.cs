namespace DatabaseDeletor.Domain.Tests.Exceptions;

using DatabaseDeletor.Domain.Exceptions;

public sealed class ExceptionTests
{
    [Fact]
    public void DatabaseDeletorException_DefaultConstructor_Works()
    {
        var ex = new DatabaseDeletorException();

        ex.Message.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public void DatabaseDeletorException_WithMessage_SetsMessage()
    {
        var ex = new DatabaseDeletorException("test error");

        ex.Message.Should().Be("test error");
    }

    [Fact]
    public void DatabaseDeletorException_WithInnerException_SetsInnerException()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new DatabaseDeletorException("outer", inner);

        ex.Message.Should().Be("outer");
        ex.InnerException.Should().BeSameAs(inner);
    }

    [Fact]
    public void ConnectionException_InheritsFromDatabaseDeletorException()
    {
        var ex = new ConnectionException("conn error");

        ex.Should().BeAssignableTo<DatabaseDeletorException>();
        ex.Message.Should().Be("conn error");
    }

    [Fact]
    public void SchemaIntrospectionException_InheritsFromDatabaseDeletorException()
    {
        var ex = new SchemaIntrospectionException("schema error");

        ex.Should().BeAssignableTo<DatabaseDeletorException>();
    }

    [Fact]
    public void DeletionException_InheritsFromDatabaseDeletorException()
    {
        var ex = new DeletionException("deletion error");

        ex.Should().BeAssignableTo<DatabaseDeletorException>();
    }

    [Fact]
    public void SqlParseException_InheritsFromDatabaseDeletorException()
    {
        var ex = new SqlParseException("parse error");

        ex.Should().BeAssignableTo<DatabaseDeletorException>();
    }

    [Fact]
    public void UnsupportedProviderException_ForConnectionString_ReturnsDescriptiveMessage()
    {
        var ex = UnsupportedProviderException.ForConnectionString("some-conn-string");

        ex.Should().BeAssignableTo<DatabaseDeletorException>();
        ex.Message.Should().Contain("Cannot determine database provider");
        ex.Message.Should().Contain("SQL Server");
        ex.Message.Should().Contain("PostgreSQL");
        ex.Message.Should().Contain("MySQL");
        ex.Message.Should().Contain("Oracle");
    }

    [Fact]
    public void UnsupportedProviderException_DefaultConstructor_Works()
    {
        var ex = new UnsupportedProviderException();

        ex.Should().NotBeNull();
    }

    [Fact]
    public void UnsupportedProviderException_WithInnerException_Works()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new UnsupportedProviderException("msg", inner);

        ex.InnerException.Should().BeSameAs(inner);
    }

    [Fact]
    public void ConnectionException_DefaultConstructor_Works()
    {
        var ex = new ConnectionException();
        ex.Should().NotBeNull();
    }

    [Fact]
    public void ConnectionException_WithInnerException_Works()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new ConnectionException("msg", inner);
        ex.InnerException.Should().BeSameAs(inner);
    }

    [Fact]
    public void SchemaIntrospectionException_DefaultConstructor_Works()
    {
        var ex = new SchemaIntrospectionException();
        ex.Should().NotBeNull();
    }

    [Fact]
    public void SchemaIntrospectionException_WithInnerException_Works()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new SchemaIntrospectionException("msg", inner);
        ex.InnerException.Should().BeSameAs(inner);
    }

    [Fact]
    public void DeletionException_DefaultConstructor_Works()
    {
        var ex = new DeletionException();
        ex.Should().NotBeNull();
    }

    [Fact]
    public void DeletionException_WithInnerException_Works()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new DeletionException("msg", inner);
        ex.InnerException.Should().BeSameAs(inner);
    }

    [Fact]
    public void SqlParseException_DefaultConstructor_Works()
    {
        var ex = new SqlParseException();
        ex.Should().NotBeNull();
    }

    [Fact]
    public void SqlParseException_WithInnerException_Works()
    {
        var inner = new InvalidOperationException("inner");
        var ex = new SqlParseException("msg", inner);
        ex.InnerException.Should().BeSameAs(inner);
    }
}
