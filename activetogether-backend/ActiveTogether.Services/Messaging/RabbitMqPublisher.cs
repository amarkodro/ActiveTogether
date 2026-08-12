using System.Text;
using System.Text.Json;
using ActiveTogether.Model.Messaging;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace ActiveTogether.Services.Messaging
{
    public interface IRabbitMqPublisher
    {
        Task PublishEmailNotificationAsync(EmailNotificationMessage message);
    }

    public class RabbitMqPublisher : IRabbitMqPublisher, IAsyncDisposable
    {
        private const string QueueName = "email-notifications";

        private readonly ConnectionFactory _factory;
        private IConnection? _connection;
        private IChannel? _channel;
        private readonly SemaphoreSlim _lock = new(1, 1);

        public RabbitMqPublisher(IConfiguration configuration)
        {
            _factory = new ConnectionFactory
            {
                HostName = configuration["RabbitMq:HostName"] ?? "localhost",
                Port = int.Parse(configuration["RabbitMq:Port"] ?? "5672"),
                UserName = configuration["RabbitMq:UserName"] ?? "guest",
                Password = configuration["RabbitMq:Password"] ?? "guest"
            };
        }

        public async Task PublishEmailNotificationAsync(EmailNotificationMessage message)
        {
            var channel = await GetChannelAsync();

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

            await channel.BasicPublishAsync(
                exchange: string.Empty,
                routingKey: QueueName,
                mandatory: false,
                basicProperties: new BasicProperties { Persistent = true },
                body: body);
        }

        private async Task<IChannel> GetChannelAsync()
        {
            if (_channel is { IsOpen: true })
                return _channel;

            await _lock.WaitAsync();
            try
            {
                if (_channel is { IsOpen: true })
                    return _channel;

                _connection ??= await _factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();
                await _channel.QueueDeclareAsync(queue: QueueName, durable: true, exclusive: false, autoDelete: false);

                return _channel;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel is not null)
                await _channel.DisposeAsync();

            if (_connection is not null)
                await _connection.DisposeAsync();
        }
    }
}