export interface MessagingPort {
  publish(exchange: string, routingKey: string, event: object): Promise<void>;
}
