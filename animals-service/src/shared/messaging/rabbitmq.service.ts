/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import * as amqp from 'amqplib';

@Injectable()
export class RabbitmqService implements OnModuleInit, OnModuleDestroy {
  private connection: any;
  private channel: any;

  async onModuleInit() {
    try {
      const url = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
      this.connection = await amqp.connect(url);
      this.channel = await this.connection.createChannel();

      await this.channel.assertExchange('animals', 'topic', { durable: true });
      await this.channel.assertExchange('movements', 'topic', {
        durable: true,
      });

      console.log('RabbitMQ conectado');
    } catch (error) {
      console.error('RabbitMQ no disponible:', error);
    }
  }

  async onModuleDestroy() {
    if (this.channel) await this.channel.close();
    if (this.connection) await this.connection.close();
  }

  publishEvent(exchange: string, routingKey: string, event: any) {
    try {
      if (!this.channel) {
        console.warn('RabbitMQ no disponible');
        return;
      }
      this.channel.publish(
        exchange,
        routingKey,
        Buffer.from(JSON.stringify(event)),
        { persistent: true },
      );
      console.log(`Evento: ${exchange}.${routingKey}`);
    } catch (error) {
      console.error('Error publicando evento:', error);
    }
  }
}
