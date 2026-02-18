namespace DatabaseDeletor.Application.Tests.Services;

using DatabaseDeletor.Application.Services;
using DatabaseDeletor.Domain.Exceptions;

public sealed class SqlParserTests
{
    private readonly SqlParser _sut = new();

    [Fact]
    public void Parse_DeleteFromWithSchema_ExtractsCorrectly()
    {
        var result = _sut.Parse("DELETE FROM dbo.Users");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
        result.WhereClause.Should().BeNull();
    }

    [Fact]
    public void Parse_DeleteFromWithoutSchema_DefaultsToDbo()
    {
        var result = _sut.Parse("DELETE FROM Users");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
    }

    [Fact]
    public void Parse_DeleteFromWithWhereClause_ExtractsWhere()
    {
        var result = _sut.Parse("DELETE FROM dbo.Users WHERE Id = 42");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
        result.WhereClause.Should().Be("Id = 42");
    }

    [Fact]
    public void Parse_SelectFromWithWhereClause_ExtractsCorrectly()
    {
        var result = _sut.Parse("SELECT * FROM sales.Orders WHERE Status = 'Active'");

        result.Schema.Should().Be("sales");
        result.TableName.Should().Be("Orders");
        result.WhereClause.Should().Be("Status = 'Active'");
    }

    [Fact]
    public void Parse_WithSquareBrackets_RemovesBrackets()
    {
        var result = _sut.Parse("DELETE FROM [dbo].[Users]");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
    }

    [Fact]
    public void Parse_WithDoubleQuotes_RemovesQuotes()
    {
        var result = _sut.Parse("DELETE FROM \"public\".\"users\"");

        result.Schema.Should().Be("public");
        result.TableName.Should().Be("users");
    }

    [Fact]
    public void Parse_WithBackticks_RemovesBackticks()
    {
        var result = _sut.Parse("DELETE FROM `mydb`.`users`");

        result.Schema.Should().Be("mydb");
        result.TableName.Should().Be("users");
    }

    [Fact]
    public void Parse_ThreePartName_UsesSchemaAndTable()
    {
        var result = _sut.Parse("DELETE FROM catalog.dbo.Users");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
    }

    [Fact]
    public void Parse_WithTrailingSemicolon_TrimsSemicolon()
    {
        var result = _sut.Parse("DELETE FROM dbo.Users;");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
    }

    [Fact]
    public void Parse_CaseInsensitive_ParsesCorrectly()
    {
        var result = _sut.Parse("delete from DBO.Users where ID > 10");

        result.Schema.Should().Be("DBO");
        result.TableName.Should().Be("Users");
        result.WhereClause.Should().Be("ID > 10");
    }

    [Fact]
    public void Parse_NullSql_ThrowsArgumentException()
    {
        var act = () => _sut.Parse(null!);

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Parse_EmptySql_ThrowsArgumentException()
    {
        var act = () => _sut.Parse("");

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Parse_WhitespaceSql_ThrowsArgumentException()
    {
        var act = () => _sut.Parse("   ");

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Parse_InvalidSql_ThrowsSqlParseException()
    {
        var act = () => _sut.Parse("UPDATE Users SET Name = 'test'");

        act.Should().Throw<SqlParseException>()
            .WithMessage("*Cannot parse SQL statement*");
    }

    [Fact]
    public void Parse_SelectFromWithoutWhere_ExtractsCorrectly()
    {
        var result = _sut.Parse("SELECT * FROM dbo.Users");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
        result.WhereClause.Should().BeNull();
    }

    [Fact]
    public void Parse_ComplexWhereClause_PreservesFullClause()
    {
        var result = _sut.Parse("DELETE FROM dbo.Users WHERE CreatedAt < '2024-01-01' AND Status = 'Inactive'");

        result.WhereClause.Should().Be("CreatedAt < '2024-01-01' AND Status = 'Inactive'");
    }

    [Fact]
    public void Parse_WithLeadingAndTrailingSpaces_Trims()
    {
        var result = _sut.Parse("   DELETE FROM dbo.Users   ");

        result.Schema.Should().Be("dbo");
        result.TableName.Should().Be("Users");
    }
}
