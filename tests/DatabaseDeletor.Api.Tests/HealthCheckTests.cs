using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace DatabaseDeletor.Api.Tests;

public sealed class HealthCheckTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public HealthCheckTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsOk()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/health", UriKind.Relative));

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsJsonWithStatusField()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/health", UriKind.Relative));
        var content = await response.Content.ReadAsStringAsync();

        // Assert
        content.Should().Contain("\"status\"");
        content.Should().Contain("Healthy");
    }

    [Fact]
    public async Task HealthEndpoint_ReturnsTimestamp()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/health", UriKind.Relative));
        var content = await response.Content.ReadAsStringAsync();

        // Assert
        content.Should().Contain("\"timestamp\"");
    }
}
