namespace DatabaseDeletor.Application.Tests.Mediator;

using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

public sealed class MediatorTests
{
    [Fact]
    public async Task SendAsync_RegisteredHandler_RoutesCorrectly()
    {
        var services = new ServiceCollection();
        services.AddSingleton<IRequestHandler<TestRequest, string>, TestHandler>();
        services.AddSingleton<IMediator, Application.Mediator.Mediator>();

        var provider = services.BuildServiceProvider();
        var mediator = provider.GetRequiredService<IMediator>();

        var result = await mediator.SendAsync(new TestRequest("hello"));

        result.Should().Be("handled: hello");
    }

    [Fact]
    public async Task SendAsync_NullRequest_ThrowsArgumentNullException()
    {
        var services = new ServiceCollection();
        services.AddSingleton<IMediator, Application.Mediator.Mediator>();

        var provider = services.BuildServiceProvider();
        var mediator = provider.GetRequiredService<IMediator>();

        var act = () => mediator.SendAsync<string>(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task SendAsync_UnregisteredHandler_ThrowsInvalidOperationException()
    {
        var services = new ServiceCollection();
        services.AddSingleton<IMediator, Application.Mediator.Mediator>();

        var provider = services.BuildServiceProvider();
        var mediator = provider.GetRequiredService<IMediator>();

        var act = () => mediator.SendAsync(new TestRequest("hello"));

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task SendAsync_PropagatesCancellationToken()
    {
        var services = new ServiceCollection();
        services.AddSingleton<IRequestHandler<TestRequest, string>, CancellationCheckingHandler>();
        services.AddSingleton<IMediator, Application.Mediator.Mediator>();

        using var cts = new CancellationTokenSource();
        var provider = services.BuildServiceProvider();
        var mediator = provider.GetRequiredService<IMediator>();

        var result = await mediator.SendAsync(new TestRequest("test"), cts.Token);

        result.Should().Be("token-received");
    }

    // Test helpers
    public sealed record TestRequest(string Value) : IRequest<string>;

    private sealed class TestHandler : IRequestHandler<TestRequest, string>
    {
        public Task<string> HandleAsync(TestRequest request, CancellationToken ct = default)
        {
            return Task.FromResult($"handled: {request.Value}");
        }
    }

    private sealed class CancellationCheckingHandler : IRequestHandler<TestRequest, string>
    {
        public Task<string> HandleAsync(TestRequest request, CancellationToken ct = default)
        {
            return Task.FromResult(ct.CanBeCanceled ? "token-received" : "no-token");
        }
    }
}
