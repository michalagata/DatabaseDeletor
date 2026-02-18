namespace DatabaseDeletor.Domain.Tests.Entities;

using DatabaseDeletor.Domain.Entities;

public sealed class TableInfoTests
{
    [Fact]
    public void FullName_WithSchema_ReturnsSchemaQualifiedName()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users" };

        table.FullName.Should().Be("dbo.Users");
    }

    [Fact]
    public void FullName_WithEmptySchema_ReturnsNameOnly()
    {
        var table = new TableInfo { Schema = "", Name = "Users" };

        table.FullName.Should().Be("Users");
    }

    [Fact]
    public void ToString_ReturnsFullName()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users" };

        table.ToString().Should().Be("dbo.Users");
    }

    [Fact]
    public void Equals_SameSchemaAndName_ReturnsTrue()
    {
        var table1 = new TableInfo { Schema = "dbo", Name = "Users" };
        var table2 = new TableInfo { Schema = "dbo", Name = "Users" };

        table1.Equals(table2).Should().BeTrue();
    }

    [Fact]
    public void Equals_CaseInsensitive_ReturnsTrue()
    {
        var table1 = new TableInfo { Schema = "DBO", Name = "USERS" };
        var table2 = new TableInfo { Schema = "dbo", Name = "users" };

        table1.Equals(table2).Should().BeTrue();
    }

    [Fact]
    public void Equals_DifferentName_ReturnsFalse()
    {
        var table1 = new TableInfo { Schema = "dbo", Name = "Users" };
        var table2 = new TableInfo { Schema = "dbo", Name = "Orders" };

        table1.Equals(table2).Should().BeFalse();
    }

    [Fact]
    public void Equals_DifferentSchema_ReturnsFalse()
    {
        var table1 = new TableInfo { Schema = "dbo", Name = "Users" };
        var table2 = new TableInfo { Schema = "sales", Name = "Users" };

        table1.Equals(table2).Should().BeFalse();
    }

    [Fact]
    public void Equals_Null_ReturnsFalse()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users" };

        table.Equals((object?)null).Should().BeFalse();
    }

    [Fact]
    public void Equals_DifferentType_ReturnsFalse()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users" };

        table.Equals("dbo.Users").Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_SameTable_ReturnsSameHash()
    {
        var table1 = new TableInfo { Schema = "dbo", Name = "Users" };
        var table2 = new TableInfo { Schema = "DBO", Name = "USERS" };

        table1.GetHashCode().Should().Be(table2.GetHashCode());
    }

    [Fact]
    public void GetHashCode_DifferentTable_ReturnsDifferentHash()
    {
        var table1 = new TableInfo { Schema = "dbo", Name = "Users" };
        var table2 = new TableInfo { Schema = "dbo", Name = "Orders" };

        table1.GetHashCode().Should().NotBe(table2.GetHashCode());
    }

    [Fact]
    public void RowCount_CanBeSetAndRetrieved()
    {
        var table = new TableInfo { Schema = "dbo", Name = "Users" };
        table.RowCount = 42;

        table.RowCount.Should().Be(42);
    }
}
