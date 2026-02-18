namespace DatabaseDeletor.Infrastructure.Tests.Database.Factories;

using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class SqlServerConnectionFactoryTests
{
    private readonly SqlServerConnectionFactory _sut = new();

    [Fact]
    public void Provider_ReturnsSqlServer()
    {
        _sut.Provider.Should().Be(DatabaseProvider.SqlServer);
    }

    [Fact]
    public void CanHandle_SqlServerConnectionString_ReturnsTrue()
    {
        var result = _sut.CanHandle("Server=localhost;Database=mydb;Trusted_Connection=true;");

        result.Should().BeTrue();
    }

    [Fact]
    public void CanHandle_PostgreSqlConnectionString_ReturnsFalse()
    {
        var result = _sut.CanHandle("Host=localhost;Database=mydb;");

        result.Should().BeFalse();
    }

    [Fact]
    public void CanHandle_NullConnectionString_ThrowsArgumentNullException()
    {
        var act = () => _sut.CanHandle(null!);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void CreateConnection_ReturnsConnection()
    {
        var conn = _sut.CreateConnection("Server=localhost;Database=mydb;");

        conn.Should().NotBeNull();
        conn.Dispose();
    }
}

public sealed class PostgreSqlConnectionFactoryTests
{
    private readonly PostgreSqlConnectionFactory _sut = new();

    [Fact]
    public void Provider_ReturnsPostgreSql()
    {
        _sut.Provider.Should().Be(DatabaseProvider.PostgreSql);
    }

    [Fact]
    public void CanHandle_PostgreSqlConnectionString_ReturnsTrue()
    {
        var result = _sut.CanHandle("Host=localhost;Database=mydb;Username=postgres;");

        result.Should().BeTrue();
    }

    [Fact]
    public void CanHandle_SqlServerConnectionString_ReturnsFalse()
    {
        var result = _sut.CanHandle("Server=localhost;Database=mydb;");

        result.Should().BeFalse();
    }

    [Fact]
    public void CanHandle_NullConnectionString_ThrowsArgumentNullException()
    {
        var act = () => _sut.CanHandle(null!);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void CreateConnection_ReturnsConnection()
    {
        var conn = _sut.CreateConnection("Host=localhost;Database=mydb;");

        conn.Should().NotBeNull();
        conn.Dispose();
    }
}

public sealed class MySqlConnectionFactoryTests
{
    private readonly MySqlConnectionFactory _sut = new();

    [Fact]
    public void Provider_ReturnsMySql()
    {
        _sut.Provider.Should().Be(DatabaseProvider.MySql);
    }

    [Fact]
    public void CanHandle_MySqlConnectionString_ReturnsTrue()
    {
        var result = _sut.CanHandle("Server=localhost;Port=3306;Database=mydb;");

        result.Should().BeTrue();
    }

    [Fact]
    public void CanHandle_SqlServerConnectionString_ReturnsFalse()
    {
        var result = _sut.CanHandle("Server=localhost;Database=mydb;");

        result.Should().BeFalse();
    }

    [Fact]
    public void CanHandle_NullConnectionString_ThrowsArgumentNullException()
    {
        var act = () => _sut.CanHandle(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}

public sealed class OracleConnectionFactoryTests
{
    private readonly OracleConnectionFactory _sut = new();

    [Fact]
    public void Provider_ReturnsOracle()
    {
        _sut.Provider.Should().Be(DatabaseProvider.Oracle);
    }

    [Fact]
    public void CanHandle_OracleConnectionString_ReturnsTrue()
    {
        var result = _sut.CanHandle("Data Source=//localhost:1521/orcl;User Id=admin;Password=secret;");

        result.Should().BeTrue();
    }

    [Fact]
    public void CanHandle_SqlServerConnectionString_ReturnsFalse()
    {
        var result = _sut.CanHandle("Server=localhost;Database=mydb;");

        result.Should().BeFalse();
    }

    [Fact]
    public void CanHandle_NullConnectionString_ThrowsArgumentNullException()
    {
        var act = () => _sut.CanHandle(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}
