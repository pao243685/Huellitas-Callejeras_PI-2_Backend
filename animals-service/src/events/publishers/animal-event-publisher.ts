/* eslint-disable*/
import { Injectable } from '@nestjs/common';
import { RabbitmqService } from '../../shared/messaging/rabbitmq.service';

@Injectable()
export class AnimalEventPublisher {
  constructor(private rabbitmqService: RabbitmqService) {}

  publishAnimalCreated(animal: any) {
    this.rabbitmqService.publishEvent(
      'animals',
      'animal.created',
      animal,
    );
  }

  publishAnimalUpdated(animal: any) {
    this.rabbitmqService.publishEvent(
      'animals',
      'animal.updated',
      animal,
    );
  }

  publishAnimalDeleted(id: string, refugioId: string) {
    this.rabbitmqService.publishEvent(
      'animals',
      'animal.deleted',
      { id, refugioId },
    );
  }
}
