using DatabaseDeletor.Application.Helpers;

namespace DatabaseDeletor.Application.Tests.Helpers;

public sealed class TableNameParserTests
{
    [Fact]
    public void Parse_EmptyArray_ReturnsEmpty()
    {
        var result = TableNameParser.Parse();
        Assert.Empty(result);
    }

    [Fact]
    public void Parse_SingleSchemaTable_ReturnsSingleItem()
    {
        var result = TableNameParser.Parse("dbo.Users");
        Assert.Single(result);
        Assert.Equal("dbo", result[0].Schema);
        Assert.Equal("Users", result[0].Name);
    }

    [Fact]
    public void Parse_TableWithoutSchema_ReturnsEmptySchema()
    {
        var result = TableNameParser.Parse("Users");
        Assert.Single(result);
        Assert.Equal(string.Empty, result[0].Schema);
        Assert.Equal("Users", result[0].Name);
    }

    [Fact]
    public void Parse_CommaSeparated_ReturnsMultipleItems()
    {
        var result = TableNameParser.Parse("dbo.Users,dbo.Orders,dbo.Products");
        Assert.Equal(3, result.Count);
        Assert.Equal("Users", result[0].Name);
        Assert.Equal("Orders", result[1].Name);
        Assert.Equal("Products", result[2].Name);
    }

    [Fact]
    public void Parse_CommaSeparatedWithSpaces_TrimsCorrectly()
    {
        var result = TableNameParser.Parse("dbo.Users , dbo.Orders , dbo.Products");
        Assert.Equal(3, result.Count);
        Assert.Equal("Users", result[0].Name);
        Assert.Equal("Orders", result[1].Name);
        Assert.Equal("Products", result[2].Name);
    }

    [Fact]
    public void Parse_MultipleEntries_CombinesAll()
    {
        var result = TableNameParser.Parse("dbo.Users", "dbo.Orders");
        Assert.Equal(2, result.Count);
        Assert.Equal("Users", result[0].Name);
        Assert.Equal("Orders", result[1].Name);
    }

    [Fact]
    public void Parse_MixedCommaSeparatedAndMultipleEntries_CombinesAll()
    {
        var result = TableNameParser.Parse("dbo.Users,dbo.Orders", "dbo.Products");
        Assert.Equal(3, result.Count);
        Assert.Equal("Users", result[0].Name);
        Assert.Equal("Orders", result[1].Name);
        Assert.Equal("Products", result[2].Name);
    }

    [Fact]
    public void Parse_EmptyAndWhitespaceEntries_AreIgnored()
    {
        var result = TableNameParser.Parse("", "  ", "dbo.Users", null!);
        Assert.Single(result);
        Assert.Equal("Users", result[0].Name);
    }

    [Fact]
    public void Parse_TrailingCommas_AreIgnored()
    {
        var result = TableNameParser.Parse("dbo.Users,,dbo.Orders,");
        Assert.Equal(2, result.Count);
    }

    [Fact]
    public void Parse_SchemaWithDots_SplitsOnFirstDotOnly()
    {
        var result = TableNameParser.Parse("my.schema.table");
        Assert.Single(result);
        Assert.Equal("my", result[0].Schema);
        Assert.Equal("schema.table", result[0].Name);
    }
}
