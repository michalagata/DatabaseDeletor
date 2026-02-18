namespace DatabaseDeletor.Domain.Interfaces;

public interface IMediator
{
    Task<TResponse> SendAsync<TResponse>(IRequest<TResponse> request, CancellationToken ct = default);
}

#pragma warning disable CA1040 // Marker interface for CQRS request types — intentionally empty
public interface IRequest<out TResponse>;
#pragma warning restore CA1040

public interface IRequestHandler<in TRequest, TResponse> where TRequest : IRequest<TResponse>
{
    Task<TResponse> HandleAsync(TRequest request, CancellationToken ct = default);
}
