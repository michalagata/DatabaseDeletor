namespace DatabaseDeletor.Infrastructure.Tests.Database.Factories;

using DatabaseDeletor.Domain.Enums;
using DatabaseDeletor.Domain.Exceptions;
using DatabaseDeletor.Infrastructure.Database.Factories;

public sealed class DatabaseProviderResolverTests
{
    private readonly DatabaseProviderResolver _sut = new();

    [Theory]
    [InlineData("Server=localhost;Database=mydb;Trusted_Connection=true;")]
    [InlineData("server=localhost;database=mydb;Integrated Security=true;")]
    public void Resolve_SqlServerConnectionString_ReturnsSqlServer(string connectionString)
    {
        var result = _sut.Resolve(connectionString);

        result.Should().Be(DatabaseProvider.SqlServer);
    }

    [Theory]
    [InlineData("Data Source=localhost;Initial Catalog=mydb;")]
    [InlineData("data source=.\\SQLEXPRESS;initial catalog=testdb;")]
    public void Resolve_SqlServerWithDataSource_ReturnsSqlServer(string connectionString)
    {
        var result = _sut.Resolve(connectionString);

        result.Should().Be(DatabaseProvider.SqlServer);
    }

    [Fact]
    public void Resolve_SqlServerKeyword_ReturnsSqlServer()
    {
        var result = _sut.Resolve("Provider=SQLSERVER;Data=test;");

        result.Should().Be(DatabaseProvider.SqlServer);
    }

    [Theory]
    [InlineData("Host=localhost;Database=mydb;Username=postgres;Password=secret;")]
    [InlineData("host=db.example.com;database=appdb;")]
    public void Resolve_PostgresConnectionString_ReturnsPostgreSql(string connectionString)
    {
        var result = _sut.Resolve(connectionString);

        result.Should().Be(DatabaseProvider.PostgreSql);
    }

    [Fact]
    public void Resolve_NpgsqlKeyword_ReturnsPostgreSql()
    {
        var result = _sut.Resolve("Provider=Npgsql;Data=test;");

        result.Should().Be(DatabaseProvider.PostgreSql);
    }

    [Fact]
    public void Resolve_PostgresKeyword_ReturnsPostgreSql()
    {
        var result = _sut.Resolve("Provider=Postgres;Data=test;");

        result.Should().Be(DatabaseProvider.PostgreSql);
    }

    [Theory]
    [InlineData("Server=localhost;Port=3306;Database=mydb;User=root;Password=secret;")]
    [InlineData("server=db.example.com;port=3306;database=appdb;")]
    public void Resolve_MySqlConnectionString_ReturnsMySql(string connectionString)
    {
        var result = _sut.Resolve(connectionString);

        result.Should().Be(DatabaseProvider.MySql);
    }

    [Fact]
    public void Resolve_MySqlKeyword_ReturnsMySql()
    {
        var result = _sut.Resolve("Provider=MySQL;Data=test;");

        result.Should().Be(DatabaseProvider.MySql);
    }

    [Theory]
    [InlineData("Data Source=//localhost:1521/orcl;User Id=admin;Password=secret;")]
    [InlineData("data source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)));user id=sys;")]
    public void Resolve_OracleConnectionString_ReturnsOracle(string connectionString)
    {
        var result = _sut.Resolve(connectionString);

        result.Should().Be(DatabaseProvider.Oracle);
    }

    [Fact]
    public void Resolve_OracleKeyword_ReturnsOracle()
    {
        var result = _sut.Resolve("Provider=Oracle;Data=test;");

        result.Should().Be(DatabaseProvider.Oracle);
    }

    [Fact]
    public void Resolve_TnsAdminKeyword_ReturnsOracle()
    {
        var result = _sut.Resolve("TNS_ADMIN=/opt/oracle;");

        result.Should().Be(DatabaseProvider.Oracle);
    }

    [Fact]
    public void Resolve_UnknownConnectionString_ThrowsUnsupportedProviderException()
    {
        var act = () => _sut.Resolve("something=unknown;");

        act.Should().Throw<UnsupportedProviderException>();
    }

    [Fact]
    public void Resolve_NullConnectionString_ThrowsArgumentException()
    {
        var act = () => _sut.Resolve(null!);

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Resolve_EmptyConnectionString_ThrowsArgumentException()
    {
        var act = () => _sut.Resolve("");

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Resolve_WhitespaceConnectionString_ThrowsArgumentException()
    {
        var act = () => _sut.Resolve("   ");

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Resolve_CaseInsensitive_Works()
    {
        var result = _sut.Resolve("SERVER=LOCALHOST;DATABASE=MYDB;");

        result.Should().Be(DatabaseProvider.SqlServer);
    }
}
