namespace DatabaseDeletor.Domain.Interfaces;

public interface IMediator
{
    Task<TResponse> SendAsync<TResponse>(IRequest<TResponse> request, CancellationToken ct = default);
}

public interface IRequest<out TResponse>
{
    // Marker interface for CQRS request types
    // Intentionally has no members — used for type constraint in IRequestHandler
}

public interface IRequestHandler<in TRequest, TResponse> where TRequest : IRequest<TResponse>
{
    Task<TResponse> HandleAsync(TRequest request, CancellationToken ct = default);
}
