namespace DatabaseDeletor.Domain.Tests.Entities;

using DatabaseDeletor.Domain.Entities;

public sealed class ColumnInfoTests
{
    [Fact]
    public void Name_ReturnsAssignedValue()
    {
        var column = new ColumnInfo { Name = "Id", DataType = "int" };
        column.Name.Should().Be("Id");
    }

    [Fact]
    public void DataType_ReturnsAssignedValue()
    {
        var column = new ColumnInfo { Name = "Email", DataType = "nvarchar(256)" };
        column.DataType.Should().Be("nvarchar(256)");
    }

    [Fact]
    public void IsNullable_DefaultsFalse()
    {
        var column = new ColumnInfo { Name = "Id", DataType = "int" };
        column.IsNullable.Should().BeFalse();
    }

    [Fact]
    public void IsNullable_WhenSet_ReturnsTrue()
    {
        var column = new ColumnInfo { Name = "MiddleName", DataType = "nvarchar(100)", IsNullable = true };
        column.IsNullable.Should().BeTrue();
    }

    [Fact]
    public void IsPrimaryKey_DefaultsFalse()
    {
        var column = new ColumnInfo { Name = "Name", DataType = "nvarchar(100)" };
        column.IsPrimaryKey.Should().BeFalse();
    }

    [Fact]
    public void IsPrimaryKey_WhenSet_ReturnsTrue()
    {
        var column = new ColumnInfo { Name = "Id", DataType = "int", IsPrimaryKey = true };
        column.IsPrimaryKey.Should().BeTrue();
    }
}
