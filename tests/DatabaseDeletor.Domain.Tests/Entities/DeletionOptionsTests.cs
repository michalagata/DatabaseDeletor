using DatabaseDeletor.Domain.Entities;
using DatabaseDeletor.Domain.Enums;

namespace DatabaseDeletor.Domain.Tests.Entities;

public sealed class DeletionOptionsTests
{
    [Fact]
    public void DefaultValues_AreCorrect()
    {
        var options = new DeletionOptions();

        options.Mode.Should().Be(DeletionMode.BatchDelete);
        options.BatchSize.Should().Be(10_000);
        options.UseTransaction.Should().BeFalse();
    }

    [Fact]
    public void IsValid_DefaultOptions_ReturnsTrue()
    {
        var options = new DeletionOptions();

        options.IsValid.Should().BeTrue();
    }

    [Fact]
    public void IsValid_BatchSizeBelowMinimum_ReturnsFalse()
    {
        var options = new DeletionOptions { Mode = DeletionMode.BatchDelete, BatchSize = 50 };

        options.IsValid.Should().BeFalse();
    }

    [Fact]
    public void IsValid_BatchSizeAboveMaximum_ReturnsFalse()
    {
        var options = new DeletionOptions { Mode = DeletionMode.BatchDelete, BatchSize = 2_000_000 };

        options.IsValid.Should().BeFalse();
    }

    [Fact]
    public void IsValid_BatchSizeAtMinimum_ReturnsTrue()
    {
        var options = new DeletionOptions { Mode = DeletionMode.BatchDelete, BatchSize = DeletionOptions.MinBatchSize };

        options.IsValid.Should().BeTrue();
    }

    [Fact]
    public void IsValid_BatchSizeAtMaximum_ReturnsTrue()
    {
        var options = new DeletionOptions { Mode = DeletionMode.BatchDelete, BatchSize = DeletionOptions.MaxBatchSize };

        options.IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData(DeletionMode.SingleRowDelete)]
    [InlineData(DeletionMode.DirectDelete)]
    public void IsValid_NonBatchMode_IgnoresBatchSize(DeletionMode mode)
    {
        var options = new DeletionOptions { Mode = mode, BatchSize = 0 };

        options.IsValid.Should().BeTrue();
    }

    [Fact]
    public void EffectiveBatchSize_BatchDelete_ReturnsBatchSize()
    {
        var options = new DeletionOptions { Mode = DeletionMode.BatchDelete, BatchSize = 5000 };

        options.EffectiveBatchSize.Should().Be(5000);
    }

    [Fact]
    public void EffectiveBatchSize_SingleRowDelete_ReturnsOne()
    {
        var options = new DeletionOptions { Mode = DeletionMode.SingleRowDelete };

        options.EffectiveBatchSize.Should().Be(1);
    }

    [Fact]
    public void EffectiveBatchSize_DirectDelete_ReturnsZero()
    {
        var options = new DeletionOptions { Mode = DeletionMode.DirectDelete };

        options.EffectiveBatchSize.Should().Be(0);
    }

    [Fact]
    public void Constants_HaveExpectedValues()
    {
        DeletionOptions.MinBatchSize.Should().Be(100);
        DeletionOptions.MaxBatchSize.Should().Be(1_000_000);
        DeletionOptions.DefaultBatchSize.Should().Be(10_000);
    }
}
