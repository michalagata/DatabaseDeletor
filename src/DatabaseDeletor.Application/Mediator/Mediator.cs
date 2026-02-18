using DatabaseDeletor.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace DatabaseDeletor.Application.Mediator;

#pragma warning disable CA1724 // Type name conflicts with namespace — intentional: Mediator pattern implementation
public sealed class Mediator : IMediator
#pragma warning restore CA1724
{
    private readonly IServiceProvider _serviceProvider;

    public Mediator(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task<TResponse> SendAsync<TResponse>(IRequest<TResponse> request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var requestType = request.GetType();
        var handlerType = typeof(IRequestHandler<,>).MakeGenericType(requestType, typeof(TResponse));
        var handler = _serviceProvider.GetRequiredService(handlerType);

        var method = handlerType.GetMethod(nameof(IRequestHandler<IRequest<TResponse>, TResponse>.HandleAsync))
            ?? throw new InvalidOperationException($"Handler for {requestType.Name} does not have HandleAsync method.");

        var result = method.Invoke(handler, [request, ct]);

        if (result is Task<TResponse> task)
            return await task.ConfigureAwait(false);

        throw new InvalidOperationException($"Handler for {requestType.Name} returned unexpected result.");
    }
}
