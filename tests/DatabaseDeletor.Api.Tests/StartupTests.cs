using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace DatabaseDeletor.Api.Tests;

public sealed class StartupTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public StartupTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public void Application_Starts_Successfully()
    {
        // Assert — factory construction triggers app startup
        _factory.Should().NotBeNull();
        _factory.Server.Should().NotBeNull();
    }

    [Fact]
    public async Task Application_RespondsToRequests()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/health", UriKind.Relative));

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task NonExistentEndpoint_Returns404()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync(new Uri("/nonexistent", UriKind.Relative));

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
