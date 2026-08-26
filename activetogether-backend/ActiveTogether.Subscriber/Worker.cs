using System.Text;
using System.Text.Json;
using ActiveTogether.Model.Messaging;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace ActiveTogether.Subscriber;

public class Worker(ILogger<Worker> logger, IConfiguration configuration) : BackgroundService
{
    private const string QueueName = "email-notifications";
    private const string RetryCountHeader = "x-retry-count";
    private const int MaxRetryAttempts = 5;

    private IConnection? _connection;
    private IChannel? _channel;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = configuration["RabbitMq:HostName"] ?? "localhost",
            Port = int.Parse(configuration["RabbitMq:Port"] ?? "5672"),
            UserName = configuration["RabbitMq:UserName"] ?? "guest",
            Password = configuration["RabbitMq:Password"] ?? "guest"
        };

        var delay = TimeSpan.FromSeconds(1);
        const int maxDelaySeconds = 30;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _connection = await factory.CreateConnectionAsync(stoppingToken);
                _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Ne mogu se povezati na RabbitMQ ({HostName}:{Port}), pokušavam ponovo za {Delay}s.",
                    factory.HostName, factory.Port, delay.TotalSeconds);
                await Task.Delay(delay, stoppingToken);
                delay = TimeSpan.FromSeconds(Math.Min(delay.TotalSeconds * 2, maxDelaySeconds));
            }
        }

        if (stoppingToken.IsCancellationRequested || _channel is null)
            return;

        await _channel.QueueDeclareAsync(queue: QueueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);
        await _channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 1, global: false, cancellationToken: stoppingToken);

        var consumer = new AsyncEventingBasicConsumer(_channel);

        consumer.ReceivedAsync += async (model, ea) =>
        {
            var body = ea.Body.ToArray();
            var json = Encoding.UTF8.GetString(body);

            try
            {
                var message = JsonSerializer.Deserialize<EmailNotificationMessage>(json);
                if (message is not null)
                {
                    await SendEmailAsync(message, stoppingToken);
                    logger.LogInformation("Email poslan na {Email} - '{Subject}'", message.ToEmail, message.Subject);
                }

                await _channel!.BasicAckAsync(deliveryTag: ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                var retryCount = GetRetryCount(ea.BasicProperties.Headers);

                if (retryCount >= MaxRetryAttempts)
                {
                    logger.LogError(ex,
                        "Greška pri obradi email notifikacije. Dostignut maksimalan broj pokušaja ({RetryCount}), poruka se odbacuje.",
                        retryCount);
                    await _channel!.BasicNackAsync(deliveryTag: ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
                    return;
                }

                var backoffSeconds = Math.Pow(2, retryCount);
                logger.LogError(ex,
                    "Greška pri obradi email notifikacije. Pokušaj {RetryCount}/{MaxRetries}, ponovni pokušaj za {Backoff}s.",
                    retryCount + 1, MaxRetryAttempts, backoffSeconds);

                await Task.Delay(TimeSpan.FromSeconds(backoffSeconds), stoppingToken);
                await RepublishWithRetryCountAsync(ea, retryCount + 1, stoppingToken);
                await _channel!.BasicAckAsync(deliveryTag: ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
        };

        await _channel.BasicConsumeAsync(queue: QueueName, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

        logger.LogInformation("Subscriber pokrenut, čeka poruke na redu '{Queue}'.", QueueName);

        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    private static int GetRetryCount(IDictionary<string, object?>? headers)
    {
        if (headers != null && headers.TryGetValue(RetryCountHeader, out var value) && value != null)
        {
            return value switch
            {
                int i => i,
                long l => (int)l,
                byte[] bytes => int.TryParse(Encoding.UTF8.GetString(bytes), out var parsed) ? parsed : 0,
                _ => 0
            };
        }
        return 0;
    }

    private async Task RepublishWithRetryCountAsync(BasicDeliverEventArgs ea, int retryCount, CancellationToken cancellationToken)
    {
        var headers = new Dictionary<string, object?>(ea.BasicProperties.Headers ?? new Dictionary<string, object?>())
        {
            [RetryCountHeader] = retryCount
        };

        var properties = new BasicProperties
        {
            Persistent = true,
            Headers = headers
        };

        await _channel!.BasicPublishAsync(
            exchange: string.Empty,
            routingKey: QueueName,
            mandatory: false,
            basicProperties: properties,
            body: ea.Body,
            cancellationToken: cancellationToken);
    }

    private async Task SendEmailAsync(EmailNotificationMessage message, CancellationToken cancellationToken)
    {
        var email = new MimeMessage();
        email.From.Add(new MailboxAddress(
            configuration["Mailtrap:FromName"] ?? "ActiveTogether",
            configuration["Mailtrap:FromEmail"] ?? "noreply@activetogether.com"));
        email.To.Add(new MailboxAddress(message.ToName, message.ToEmail));
        email.Subject = message.Subject;
        email.Body = new TextPart("plain") { Text = message.Body };

        using var smtp = new SmtpClient();
        await smtp.ConnectAsync(
            configuration["Mailtrap:Host"],
            int.Parse(configuration["Mailtrap:Port"] ?? "587"),
            SecureSocketOptions.StartTls,
            cancellationToken);

        await smtp.AuthenticateAsync(
            configuration["Mailtrap:Username"],
            configuration["Mailtrap:Password"],
            cancellationToken);

        await smtp.SendAsync(email, cancellationToken);
        await smtp.DisconnectAsync(true, cancellationToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_channel is not null)
            await _channel.CloseAsync(cancellationToken);

        if (_connection is not null)
            await _connection.CloseAsync(cancellationToken);

        await base.StopAsync(cancellationToken);
    }
}