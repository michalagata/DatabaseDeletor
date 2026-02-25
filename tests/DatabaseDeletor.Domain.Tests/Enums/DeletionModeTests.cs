using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Tests.Enums;

public sealed class DeletionModeTests
{
    [Fact]
    public void BatchDelete_HasValue0()
    {
        ((int)DeletionMode.BatchDelete).Should().Be(0);
    }

    [Fact]
    public void SingleRowDelete_HasValue1()
    {
        ((int)DeletionMode.SingleRowDelete).Should().Be(1);
    }

    [Fact]
    public void DirectDelete_HasValue2()
    {
        ((int)DeletionMode.DirectDelete).Should().Be(2);
    }

    [Fact]
    public void Enum_HasExactly3Values()
    {
        Enum.GetValues<DeletionMode>().Should().HaveCount(3);
    }

    [Theory]
    [InlineData("BatchDelete", DeletionMode.BatchDelete)]
    [InlineData("SingleRowDelete", DeletionMode.SingleRowDelete)]
    [InlineData("DirectDelete", DeletionMode.DirectDelete)]
    public void Parse_ValidString_ReturnsDeletionMode(string input, DeletionMode expected)
    {
        Enum.Parse<DeletionMode>(input).Should().Be(expected);
    }
}
